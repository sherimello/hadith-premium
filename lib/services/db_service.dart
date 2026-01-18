import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class DbService {
  static Database? _db;
  static const String _dbName = 'hadith_premium.db';

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
        "assets/data/db/hadith_premium_backup.db",
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
      version: 2,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createBookmarkTables(db);
        }
      },
      onOpen: (db) async {
        // Ensure tables exist even if version didn't change (robustness)
        await _createBookmarkTables(db);
      },
    );
  }

  Future<void> _createBookmarkTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bookmark_folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
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
        hadith_number INTEGER,
        text_en TEXT,
        text_ar TEXT,
        timestamp INTEGER,
        FOREIGN KEY(folder_id) REFERENCES bookmark_folders(id) ON DELETE CASCADE
      )
    ''');
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

  Future<bool> isBookmarked(int bookId, int hadithNumber) async {
    final db = await database;
    final result = await db.query(
      'bookmarks',
      where: 'book_id = ? AND hadith_number = ?',
      whereArgs: [bookId, hadithNumber],
    );
    return result.isNotEmpty;
  }

  Future<bool> hasData() async {
    try {
      final db = await database;
      // Check if table exists first to avoid error during migration
      var table = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='hadiths'",
      );
      if (table.isEmpty) return false;

      final result = await db.rawQuery('SELECT COUNT(*) as count FROM hadiths');
      int count = Sqflite.firstIntValue(result) ?? 0;
      return count > 0;
    } catch (e) {
      return false;
    }
  }

  Future<void> insertCollection(String id, String name) async {
    final db = await database;
    await db.insert('collections', {
      'id': id,
      'name': name,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> insertBook(
    String collectionId,
    int bookNumber,
    String name,
  ) async {
    final db = await database;
    return await db.insert('books', {
      'collection_id': collectionId,
      'book_number': bookNumber,
      'name': name,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertHadith(
    String collectionId,
    int bookId,
    int hadithNumber,
    String textEn,
    String textAr,
    String grade,
    String? narrator,
  ) async {
    final db = await database;
    await db.insert('hadiths', {
      'collection_id': collectionId,
      'book_id': bookId,
      'hadith_number': hadithNumber,
      'text_en': textEn,
      'text_ar': textAr,
      'grade': grade,
      'narrator': narrator,
    });
  }

  Future<String> backupToDownloads() async {
    try {
      if (Platform.isAndroid) {
        // Check for Manage External Storage (Android 11+)
        if (await Permission.manageExternalStorage.request().isGranted) {
          // Good to go
        } else if (await Permission.storage.request().isGranted) {
          // Old Android or partial access
        } else {
          return "Permission denied. Please allow 'All Files Access' in settings.";
        }
      }

      final dbPath = await getDatabasesPath();
      final srcPath = join(dbPath, _dbName);
      final srcFile = File(srcPath);

      if (!await srcFile.exists()) return "Database file not found.";

      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
      } else {
        downloadsDir = await getDownloadsDirectory();
      }

      if (downloadsDir != null) {
        if (!await downloadsDir.exists()) {
          try {
            await downloadsDir.create(recursive: true);
          } catch (e) {
            return "Could not create Downloads directory: $e";
          }
        }
        final dstPath = join(downloadsDir.path, 'hadith_premium_backup.db');
        await srcFile.copy(dstPath);
        return "Database saved to: $dstPath";
      }
      return "Downloads directory not found.";
    } catch (e) {
      return "Backup failed: $e";
    }
  }

  // Data Retrieval methods
  Future<List<Map<String, dynamic>>> getCollections() async {
    final db = await database;
    return await db.query('collections');
  }

  Future<List<Map<String, dynamic>>> getBooks(String collectionId) async {
    final db = await database;
    return await db.query(
      'books',
      where: 'collection_id = ?',
      whereArgs: [collectionId],
      orderBy: 'book_number ASC',
    );
  }

  Future<List<Map<String, dynamic>>> searchHadiths(
    String query, {
    int limit = 100,
    int offset = 0,
  }) async {
    final db = await database;

    // Contextual search joining collections and books
    return await db.rawQuery(
      '''
      SELECT 
        h.*, 
        b.name as book_name, 
        c.name as collection_name,
        c.id as collection_id
      FROM hadiths h
      JOIN books b ON h.book_id = b.id
      JOIN collections c ON b.collection_id = c.id
      WHERE h.text_en LIKE ? OR h.text_ar LIKE ?
      LIMIT ? OFFSET ?
    ''',
      ['%$query%', '%$query%', limit, offset],
    );
  }

  Future<List<Map<String, dynamic>>> getHadiths(int bookId) async {
    final db = await database;
    return await db.query(
      'hadiths',
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'hadith_number ASC',
    );
  }
}
