import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/bookmark_controller.dart';
import 'hadith_list_screen.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final BookmarkController bookmarkController =
        Get.find<BookmarkController>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bookmarks"),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: Obx(() {
        if (bookmarkController.folders.isEmpty) {
          return const Center(child: Text("No bookmark folders created yet."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookmarkController.folders.length,
          itemBuilder: (context, index) {
            final folder = bookmarkController.folders[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: colorScheme.surfaceContainerLow,
              child: ListTile(
                title: Text(
                  folder['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                leading: const Icon(Icons.folder_shared_outlined),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Get.to(
                  () => BookmarkListScreen(
                    folderId: folder['id'],
                    folderName: folder['name'],
                  ),
                ),
                onLongPress: () {
                  Get.defaultDialog(
                    title: "Delete Folder?",
                    middleText:
                        "Are you sure you want to delete '${folder['name']}' and all its bookmarks?",
                    textConfirm: "Delete",
                    textCancel: "Cancel",
                    confirmTextColor: Colors.white,
                    onConfirm: () {
                      bookmarkController.deleteFolder(folder['id']);
                      Get.back();
                    },
                  );
                },
              ),
            );
          },
        );
      }),
    );
  }
}

class BookmarkListScreen extends StatefulWidget {
  final int folderId;
  final String folderName;

  const BookmarkListScreen({
    super.key,
    required this.folderId,
    required this.folderName,
  });

  @override
  State<BookmarkListScreen> createState() => _BookmarkListScreenState();
}

class _BookmarkListScreenState extends State<BookmarkListScreen> {
  final BookmarkController bookmarkController = Get.find<BookmarkController>();

  @override
  void initState() {
    super.initState();
    bookmarkController.loadBookmarks(widget.folderId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folderName),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: Obx(() {
        if (bookmarkController.isLoading.value) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        final bookmarks = bookmarkController.bookmarks;
        if (bookmarks.isEmpty) {
          return const Center(child: Text("No bookmarks in this folder."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookmarks.length,
          itemBuilder: (context, index) {
            final b = bookmarks[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                title: Text(
                  "Hadith ${b['hadith_number']}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "${b['book_name']} - ${b['collection_id']}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    bookmarkController.removeBookmark(b['id'], widget.folderId);
                  },
                ),
                onTap: () {
                  Get.to(
                    () => HadithListScreen(
                      bookId: b['book_id'],
                      bookName: b['book_name'],
                      collectionId: b['collection_id'],
                      targetHadithNumber: b['hadith_number'],
                    ),
                  );
                },
              ),
            );
          },
        );
      }),
    );
  }
}
