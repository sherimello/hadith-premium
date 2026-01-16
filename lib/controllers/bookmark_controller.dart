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
      'hadith_number': hadithNumber,
      'text_en': textEn,
      'text_ar': textAr,
    });
    await loadFolders(); // Refresh folders listing if needed
    Get.snackbar(
      "Bookmarked",
      "Added to folder successfully",
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> removeBookmark(int id, int folderId) async {
    await _dbService.removeBookmark(id);
    await loadBookmarks(folderId);
  }

  Future<bool> checkIsBookmarked(int bookId, int hadithNumber) async {
    return await _dbService.isBookmarked(bookId, hadithNumber);
  }
}
