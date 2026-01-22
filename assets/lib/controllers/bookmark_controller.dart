import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import '../services/db_service.dart';

class BookmarkController extends GetxController {
  final DbService _dbService = DbService();

  final RxList<Map<String, dynamic>> folders = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> bookmarks = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadFolders();
    syncAll();

    // Listen to Auth State Changes
    _supabase.auth.onAuthStateChange.listen((data) {
      if (data.session?.user != null) {
        print("Auth change detected, syncing bookmarks...");
        syncAll();
      }
    });
  }

  final _supabase = Supabase.instance.client;

  Future<void> syncAll() async {
    if (_supabase.auth.currentUser == null) return;

    isLoading.value = true;
    try {
      await loadFolders(); // Ensure local state is fresh
      await uploadUnsynced();
      await downloadRemote();
      await loadFolders(); // Final refresh
    } catch (e) {
      print("Sync error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> uploadUnsynced() async {
    // 1. Sync Folders
    final unsyncedFolders = await _dbService.getUnsyncedFolders();
    for (var folder in unsyncedFolders) {
      try {
        final response = await _supabase
            .from('bookmark_folders')
            .upsert({
              if (folder['remote_id'] != null) 'id': folder['remote_id'],
              'user_id': _supabase.auth.currentUser!.id,
              'name': folder['name'],
            })
            .select('id')
            .single();

        await _dbService.updateFolderRemoteId(folder['id'], response['id']);
      } catch (e) {
        print("Error uploading folder ${folder['name']}: $e");
      }
    }

    // CRITICAL: Refresh folders list so bookmark sync can find the remote_ids
    await loadFolders();

    // 2. Sync Bookmarks
    final unsyncedBookmarks = await _dbService.getUnsyncedBookmarks();
    for (var bookmark in unsyncedBookmarks) {
      try {
        // Find parent remote ID directly from DB to avoid any state issues
        final remoteFolderId = await _dbService.getFolderRemoteId(
          bookmark['folder_id'],
        );

        if (remoteFolderId == null) {
          print("Skipping bookmark sync: Parent folder not yet synced.");
          continue;
        }

        await _supabase.from('bookmarks').upsert({
          if (bookmark['remote_id'] != null) 'id': bookmark['remote_id'],
          'user_id': _supabase.auth.currentUser!.id,
          'folder_id': remoteFolderId,
          'collection_id': bookmark['collection_id'],
          'book_id': bookmark['book_id'],
          'book_name': bookmark['book_name'],
          'hadith_number': bookmark['hadith_number'].toString(),
          'chapter_name': bookmark['chapter_name'],
          'text_en': bookmark['text_en'],
          'text_ar': bookmark['text_ar'],
          'created_at': DateTime.fromMillisecondsSinceEpoch(
            bookmark['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
          ).toIso8601String(),
        });

        // We need the remote ID if we didn't have it.
        // If it was an insert, it's better to select back or assume upsert logic.
        // For now, let's just mark it as synced.
        // Ideally we'd get the ID back if bookmark['remote_id'] was null.
        if (bookmark['remote_id'] == null) {
          final res = await _supabase
              .from('bookmarks')
              .select('id')
              .eq('user_id', _supabase.auth.currentUser!.id)
              .eq('folder_id', remoteFolderId)
              .eq('collection_id', bookmark['collection_id'])
              .eq('book_id', bookmark['book_id'])
              .eq('hadith_number', bookmark['hadith_number'].toString())
              .maybeSingle();
          if (res != null) {
            await _dbService.markBookmarkSynced(bookmark['id'], res['id']);
          }
        } else {
          await _dbService.markBookmarkSynced(
            bookmark['id'],
            bookmark['remote_id'],
          );
        }
      } catch (e) {
        if (e is PostgrestException && e.code == '23503') {
          print(
            "FK violation detected for Hadith ${bookmark['hadith_number']}. Attempting immediate repair...",
          );

          // Self-healing: mark parent folder as unsynced
          await _dbService.resetFolderSync(bookmark['folder_id']);

          // Immediately re-upload the folder
          final folderData = folders.firstWhereOrNull(
            (f) => f['id'] == bookmark['folder_id'],
          );
          if (folderData != null) {
            try {
              // First check if folder already exists in Supabase
              var existingFolder = await _supabase
                  .from('bookmark_folders')
                  .select('id')
                  .eq('user_id', _supabase.auth.currentUser!.id)
                  .eq('name', folderData['name'])
                  .maybeSingle();

              String newRemoteId;
              if (existingFolder != null) {
                newRemoteId = existingFolder['id'];
                print("Found existing folder in Supabase: $newRemoteId");
              } else {
                final insertResponse = await _supabase
                    .from('bookmark_folders')
                    .insert({
                      'user_id': _supabase.auth.currentUser!.id,
                      'name': folderData['name'],
                    })
                    .select('id')
                    .single();
                newRemoteId = insertResponse['id'];
                print("Created new folder in Supabase: $newRemoteId");
              }

              await _dbService.updateFolderRemoteId(
                bookmark['folder_id'],
                newRemoteId,
              );
              print(
                "Folder ${folderData['name']} re-synced with ID: $newRemoteId",
              );

              // Retry the bookmark upload
              await _supabase.from('bookmarks').upsert({
                if (bookmark['remote_id'] != null) 'id': bookmark['remote_id'],
                'user_id': _supabase.auth.currentUser!.id,
                'folder_id': newRemoteId,
                'collection_id': bookmark['collection_id'],
                'book_id': bookmark['book_id'],
                'book_name': bookmark['book_name'],
                'hadith_number': bookmark['hadith_number'].toString(),
                'chapter_name': bookmark['chapter_name'],
                'text_en': bookmark['text_en'],
                'text_ar': bookmark['text_ar'],
                'created_at': DateTime.fromMillisecondsSinceEpoch(
                  bookmark['timestamp'] ??
                      DateTime.now().millisecondsSinceEpoch,
                ).toIso8601String(),
              });

              // Mark bookmark as synced
              final res = await _supabase
                  .from('bookmarks')
                  .select('id')
                  .eq('user_id', _supabase.auth.currentUser!.id)
                  .eq('folder_id', newRemoteId)
                  .eq('collection_id', bookmark['collection_id'])
                  .eq('book_id', bookmark['book_id'])
                  .eq('hadith_number', bookmark['hadith_number'].toString())
                  .maybeSingle();
              if (res != null) {
                await _dbService.markBookmarkSynced(bookmark['id'], res['id']);
                print(
                  "Bookmark (Hadith ${bookmark['hadith_number']}) successfully synced after repair!",
                );
              }
            } catch (retryError) {
              print(
                "Repair failed for bookmark (Hadith ${bookmark['hadith_number']}): $retryError",
              );
            }
          }
        } else {
          print(
            "Error uploading bookmark (Hadith ${bookmark['hadith_number']}): $e",
          );
        }
      }
    }
  }

  Future<void> downloadRemote() async {
    // 1. Fetch remote folders
    final remoteFolders = await _supabase.from('bookmark_folders').select();
    for (var rFolder in remoteFolders) {
      await _dbService.upsertRemoteFolder(rFolder);
    }

    // Reload local folders to get correct IDs for bookmark mapping
    await loadFolders();

    // 2. Fetch remote bookmarks
    final remoteBookmarks = await _supabase.from('bookmarks').select();
    for (var rBookmark in remoteBookmarks) {
      // Find local folder ID by remote UUID
      final localFolder = folders.firstWhereOrNull(
        (f) => f['remote_id'] == rBookmark['folder_id'],
      );
      if (localFolder != null) {
        await _dbService.upsertRemoteBookmark(rBookmark, localFolder['id']);
      }
    }
  }

  Future<void> loadFolders() async {
    isLoading.value = true;
    final list = await _dbService.getFolders();
    folders.assignAll(list);
    isLoading.value = false;
  }

  Future<void> loadBookmarks(int folderId) async {
    isLoading.value = true;
    final list = await _dbService.getBookmarksInFolder(folderId);
    bookmarks.assignAll(list);
    isLoading.value = false;
  }

  Future<int> createFolder(String name) async {
    final id = await _dbService.createFolder(name);
    await loadFolders();
    return id;
  }

  Future<void> deleteFolder(int id) async {
    final folder = folders.firstWhereOrNull((f) => f['id'] == id);
    if (folder != null && folder['remote_id'] != null) {
      try {
        await _supabase
            .from('bookmark_folders')
            .delete()
            .eq('id', folder['remote_id']);
      } catch (e) {
        print("Error deleting remote folder: $e");
      }
    }
    await _dbService.deleteFolder(id);
    await loadFolders();
  }

  Future<void> addBookmark({
    required int folderId,
    required String collectionId,
    required int bookId,
    required String bookName,
    required int hadithNumber,
    String? chapterName,
    String? textEn,
    String? textAr,
  }) async {
    await _dbService.addBookmark({
      'folder_id': folderId,
      'collection_id': collectionId,
      'book_id': bookId,
      'book_name': bookName,
      'chapter_name': chapterName,
      'hadith_number': hadithNumber.toString(),
      'text_en': textEn,
      'text_ar': textAr,
    });
    await loadFolders();
    syncAll(); // Try to sync immediately

    Get.snackbar(
      "Bookmarked",
      "Added to folder successfully",
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> removeBookmark(int id, int folderId) async {
    final bookmark = bookmarks.firstWhereOrNull((b) => b['id'] == id);
    if (bookmark != null && bookmark['remote_id'] != null) {
      try {
        await _supabase
            .from('bookmarks')
            .delete()
            .eq('id', bookmark['remote_id']);
      } catch (e) {
        print("Error deleting remote bookmark: $e");
      }
    }
    await _dbService.removeBookmark(id);
    await loadBookmarks(folderId);
  }

  Future<bool> checkIsBookmarked(
    String collectionId,
    int bookId,
    dynamic hadithNumber,
  ) async {
    return await _dbService.isBookmarked(collectionId, bookId, hadithNumber);
  }
}
