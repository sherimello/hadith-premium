import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbService {
  static Database? _db;
  static const String _dbName = 'hadith_v2.db';

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await initDb();
    return _db!;
  }

  Future<Database> initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    // Check if DB exists
    bool exists = await databaseExists(path);

    if (!exists) {
      print("Creating new copy from asset");

      // Make sure parent directory exists
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      // Copy from asset
      ByteData data = await rootBundle.load(
        "assets/data/db/hadith_fixed_v2.db",
      );
      List<int> bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      // Write and flush
      await File(path).writeAsBytes(bytes, flush: true);
    } else {
      print("Opening existing database");
    }

    return await openDatabase(
      path,
      version: 1, // New DB, reset versioning logic if needed or keep consistent
      onUpgrade: (db, oldVersion, newVersion) async {
        // Migration logic if we upgrade existing USER DBs
        // For now, since we switched filename, it's a fresh DB for everyone.
        // We still need to create bookmark tables on this NEW DB.
        await _createBookmarkTables(db);
      },
      onOpen: (db) async {
        // Ensure tables exist
        await _createBookmarkTables(db);
      },
    );
  }

  Future<void> _createBookmarkTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bookmark_folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        is_synced INTEGER DEFAULT 0,
        remote_id TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS bookmarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        folder_id INTEGER,
        collection_id TEXT,
        book_id INTEGER,
        book_name TEXT,
        chapter_name TEXT,
        hadith_number TEXT,
        text_en TEXT,
        text_ar TEXT,
        timestamp INTEGER,
        is_synced INTEGER DEFAULT 0,
        remote_id TEXT,
        FOREIGN KEY(folder_id) REFERENCES bookmark_folders(id) ON DELETE CASCADE
      )
    ''');

    // Migration for existing tables:
    await _addColumnIfNotExists(
      db,
      'bookmark_folders',
      'is_synced',
      'INTEGER DEFAULT 0',
    );
    await _addColumnIfNotExists(db, 'bookmark_folders', 'remote_id', 'TEXT');
    await _addColumnIfNotExists(
      db,
      'bookmarks',
      'is_synced',
      'INTEGER DEFAULT 0',
    );
    await _addColumnIfNotExists(db, 'bookmarks', 'remote_id', 'TEXT');
  }

  Future<void> _addColumnIfNotExists(
    Database db,
    String tableName,
    String columnName,
    String columnType,
  ) async {
    final results = await db.rawQuery('PRAGMA table_info($tableName)');
    bool exists = results.any((row) => row['name'] == columnName);
    if (!exists) {
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN $columnName $columnType',
      );
    }
  }

  // Folder Methods
  Future<int> createFolder(String name) async {
    final db = await database;
    return await db.insert('bookmark_folders', {
      'name': name,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<Map<String, dynamic>>> getFolders() async {
    final db = await database;
    return await db.query('bookmark_folders', orderBy: 'name ASC');
  }

  Future<void> deleteFolder(int id) async {
    final db = await database;
    await db.delete('bookmark_folders', where: 'id = ?', whereArgs: [id]);
  }

  // Bookmark Methods
  Future<int> addBookmark(Map<String, dynamic> bookmark) async {
    final db = await database;
    return await db.insert('bookmarks', {
      ...bookmark,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> getBookmarksInFolder(int folderId) async {
    final db = await database;
    return await db.query(
      'bookmarks',
      where: 'folder_id = ?',
      whereArgs: [folderId],
      orderBy: 'timestamp DESC',
    );
  }

  Future<void> removeBookmark(int id) async {
    final db = await database;
    await db.delete('bookmarks', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> isBookmarked(
    String collectionId,
    int bookId,
    dynamic hadithNumber,
  ) async {
    final db = await database;
    final result = await db.query(
      'bookmarks',
      where: 'collection_id = ? AND book_id = ? AND hadith_number = ?',
      whereArgs: [collectionId, bookId, hadithNumber.toString()],
    );
    return result.isNotEmpty;
  }

  // Sync helpers
  Future<List<Map<String, dynamic>>> getUnsyncedFolders() async {
    final db = await database;
    return await db.query('bookmark_folders', where: 'is_synced = 0');
  }

  Future<List<Map<String, dynamic>>> getUnsyncedBookmarks() async {
    final db = await database;
    return await db.query('bookmarks', where: 'is_synced = 0');
  }

  Future<void> markBookmarkSynced(int localId, String remoteId) async {
    final db = await database;
    await db.update(
      'bookmarks',
      {'is_synced': 1, 'remote_id': remoteId},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  Future<String?> getFolderRemoteId(int localId) async {
    final db = await database;
    final result = await db.query(
      'bookmark_folders',
      columns: ['remote_id'],
      where: 'id = ?',
      whereArgs: [localId],
    );
    if (result.isNotEmpty) return result.first['remote_id'] as String?;
    return null;
  }

  Future<void> updateFolderRemoteId(int localId, String remoteId) async {
    final db = await database;
    await db.update(
      'bookmark_folders',
      {'remote_id': remoteId, 'is_synced': 1},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  Future<void> resetFolderSync(int folderId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'bookmark_folders',
        {'is_synced': 0, 'remote_id': null},
        where: 'id = ?',
        whereArgs: [folderId],
      );
      // Also mark all bookmarks in this folder as unsynced just in case
      await txn.update(
        'bookmarks',
        {'is_synced': 0, 'remote_id': null},
        where: 'folder_id = ?',
        whereArgs: [folderId],
      );
    });
  }

  Future<void> upscaleFolderRemoteId(int localId, String remoteId) async {
    final db = await database;
    await db.update(
      'bookmark_folders',
      {'remote_id': remoteId, 'is_synced': 1},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  Future<void> upsertRemoteFolder(Map<String, dynamic> folder) async {
    final db = await database;
    // Check if a folder with this name exists locally
    final local = await db.query(
      'bookmark_folders',
      where: 'name = ?',
      whereArgs: [folder['name']],
    );

    if (local.isNotEmpty) {
      // If it exists, update its remote_id instead of replacing the whole row
      // replacing the row would delete bookmarks due to CASCADE
      await db.update(
        'bookmark_folders',
        {'remote_id': folder['id'], 'is_synced': 1},
        where: 'id = ?',
        whereArgs: [local.first['id']],
      );
    } else {
      // If not, insert as new
      await db.insert('bookmark_folders', {
        'name': folder['name'],
        'is_synced': 1,
        'remote_id': folder['id'],
      });
    }
  }

  Future<void> upsertRemoteBookmark(
    Map<String, dynamic> bookmark,
    int localFolderId,
  ) async {
    final db = await database;
    await db.insert('bookmarks', {
      'folder_id': localFolderId,
      'collection_id': bookmark['collection_id'],
      'book_id': bookmark['book_id'],
      'book_name': bookmark['book_name'],
      'chapter_name': bookmark['chapter_name'],
      'hadith_number': bookmark['hadith_number'].toString(),
      'text_en': bookmark['text_en'],
      'text_ar': bookmark['text_ar'],
      'is_synced': 1,
      'remote_id': bookmark['id'],
      'timestamp': DateTime.parse(
        bookmark['created_at'],
      ).millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<bool> hasData() async {
    // Simplified check for new DB
    final db = await database;
    try {
      final result = await db.rawQuery('SELECT COUNT(*) FROM collection');
      int count = Sqflite.firstIntValue(result) ?? 0;
      return count > 0;
    } catch (e) {
      return false;
    }
  }

  // Data Retrieval methods
  Future<List<Map<String, dynamic>>> getCollections() async {
    final db = await database;
    // Map 'title' to 'name' for compatibility if UI expects 'name'
    return await db.rawQuery(
      "SELECT id, title as name, title_en as name_en, short_description FROM collection",
    );
  }

  Future<List<Map<String, dynamic>>> getBooks(String collectionId) async {
    final db = await database;
    // 'book' table schema: id, collection_id, title...
    // We map 'title' to 'name'
    return await db.rawQuery(
      "SELECT id, id as book_number, title as name FROM book WHERE collection_id = ? ORDER BY id ASC",
      [collectionId],
    );
  }

  Future<List<Map<String, dynamic>>> searchHadiths(
    String query, {
    int limit = 100,
    int offset = 0,
  }) async {
    final db = await database;

    // Search in hadith.c6, c7, c8 (Arabic) and hadith_en.content (English)
    return await db.rawQuery(
      '''
      SELECT 
        h.id,
        h.c0, 
        h.c1 as collection_id,
        h.c2 as book_id,
        h.c4 as hadith_number,
        h.c5 as in_book_number,
        (COALESCE(h.c6, '') || ' ' || COALESCE(h.c7, '') || ' ' || COALESCE(h.c8, '')) as text_ar,
        he.content as text_en,
        h.c13 as grade_ar,
        he.grades as grade,
        he.narrator_prefix as narrator,
        he.reference as reference,
        b.title as book_name,
        c.title as collection_name,
        c.title_en as collection_name_en,
        h.c15 as similar_urns
      FROM hadith h
      LEFT JOIN hadith_en he ON h.c0 = he.arabic_urn
      JOIN book b ON h.c2 = b.id AND h.c1 = b.collection_id
      JOIN collection c ON h.c1 = c.id
      WHERE h.c6 LIKE ? OR h.c7 LIKE ? OR h.c8 LIKE ? OR he.content LIKE ?
      ORDER BY h.id ASC
      LIMIT ? OFFSET ?
    ''',
      ['%$query%', '%$query%', '%$query%', '%$query%', limit, offset],
    );
  }

  Future<List<Map<String, dynamic>>> getHadiths(
    String collectionId,
    int bookId,
  ) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT 
        h.id,
        h.c0,
        h.c1 as collection_id,
        h.c2 as book_id,
        h.c4 as hadith_number,
        h.c5 as in_book_number,
        (COALESCE(h.c6, '') || ' ' || COALESCE(h.c7, '') || ' ' || COALESCE(h.c8, '')) as text_ar,
        he.content as text_en,
        he.grades as grade, 
        he.narrator_prefix as narrator, 
        he.reference as reference,
        h.c13 as grade_ar,
        h.c12 as explanation_ar,
        he.hadith_explanation as explanation_en,
        h.c15 as similar_urns
      FROM hadith h
      LEFT JOIN hadith_en he ON h.c0 = he.arabic_urn
      WHERE h.c1 = ? AND h.c2 = ?
      ORDER BY h.id ASC
      ''',
      [collectionId, bookId],
    );
  }

  Future<List<Map<String, dynamic>>> getHadithsByUrns(List<int> urns) async {
    if (urns.isEmpty) return [];
    final db = await database;
    final placeholders = List.filled(urns.length, '?').join(',');
    return await db.rawQuery(
      '''
      SELECT 
        h.id,
        h.c0,
        h.c1 as collection_id,
        h.c2 as book_id,
        h.c4 as hadith_number,
        (COALESCE(h.c6, '') || ' ' || COALESCE(h.c7, '') || ' ' || COALESCE(h.c8, '')) as text_ar,
        he.content as text_en,
        he.grades as grade, 
        he.narrator_prefix as narrator, 
        he.reference as reference,
        h.c13 as grade_ar,
        b.title as book_name,
        c.title as collection_name
      FROM hadith h
      LEFT JOIN hadith_en he ON h.c0 = he.arabic_urn
      JOIN book b ON h.c2 = b.id AND h.c1 = b.collection_id
      JOIN collection c ON h.c1 = c.id
      WHERE h.c0 IN ($placeholders)
      ORDER BY CASE h.c0 ''' +
          List.generate(
            urns.length,
            (i) => 'WHEN ${urns[i]} THEN $i',
          ).join(' ') +
          ' END',
      urns.map((u) => u.toString()).toList(),
    );
  }

  Future<List<Map<String, dynamic>>> getHadithsByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');
    return await db.rawQuery(
      '''
      SELECT 
        h.id,
        h.c0,
        h.c1 as collection_id,
        h.c2 as book_id,
        h.c4 as hadith_number,
        (COALESCE(h.c6, '') || ' ' || COALESCE(h.c7, '') || ' ' || COALESCE(h.c8, '')) as text_ar,
        he.content as text_en,
        he.grades as grade, 
        he.narrator_prefix as narrator, 
        he.reference as reference,
        h.c13 as grade_ar,
        b.title as book_name,
        c.title as collection_name
      FROM hadith h
      LEFT JOIN hadith_en he ON h.c0 = he.arabic_urn
      JOIN book b ON h.c2 = b.id AND h.c1 = b.collection_id
      JOIN collection c ON h.c1 = c.id
      WHERE h.id IN ($placeholders)
      ORDER BY CASE h.id ''' +
          List.generate(ids.length, (i) => 'WHEN ${ids[i]} THEN $i').join(' ') +
          ' END',
      ids.map((id) => id.toString()).toList(),
    );
  }
}
