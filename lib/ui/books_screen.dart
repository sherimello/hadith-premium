// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../services/db_service.dart';
// import 'hadith_list_screen.dart';
//
// class BooksScreen extends StatefulWidget {
//   final String collectionId;
//   final String collectionName;
//
//   const BooksScreen({required this.collectionId, required this.collectionName});
//
//   @override
//   _BooksScreenState createState() => _BooksScreenState();
// }
//
// class _BooksScreenState extends State<BooksScreen> {
//   final DbService _dbService = DbService();
//   List<Map<String, dynamic>> _books = [];
//   bool _loading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadBooks();
//   }
//
//   Future<void> _loadBooks() async {
//     final list = await _dbService.getBooks(widget.collectionId);
//     setState(() {
//       _books = list;
//       _loading = false;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(widget.collectionName)),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: _books.length,
//               itemBuilder: (context, index) {
//                 final item = _books[index];
//                 return Card(
//                   elevation: 1,
//                   margin: const EdgeInsets.only(bottom: 8),
//                   child: ListTile(
//                     title: Text(
//                       item['name'],
//                       style: const TextStyle(fontWeight: FontWeight.w600),
//                     ),
//                     leading: CircleAvatar(
//                       backgroundColor: Theme.of(
//                         context,
//                       ).primaryColor.withOpacity(0.1),
//                       child: Text(
//                         "${index + 1}",
//                         style: TextStyle(color: Theme.of(context).primaryColor),
//                       ),
//                     ),
//                     onTap: () {
//                       Get.to(
//                         () => HadithListScreen(
//                           bookId: item['id'],
//                           bookName: item['name'],
//                         ),
//                       );
//                     },
//                   ),
//                 );
//               },
//             ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/db_service.dart';
import 'hadith_list_screen.dart';

class BooksScreen extends StatefulWidget {
  final String collectionId;
  final String collectionName;

  const BooksScreen({
    super.key,
    required this.collectionId,
    required this.collectionName,
  });

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  final DbService _dbService = DbService();
  List<Map<String, dynamic>> _books = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    final list = await _dbService.getBooks(widget.collectionId);
    setState(() {
      _books = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // M3 Large AppBar provides a beautiful transition as you scroll
      body: CustomScrollView(
        slivers: [
          SliverAppBar.medium(
            title: Text(widget.collectionName),
            backgroundColor: theme.scaffoldBackgroundColor,
            surfaceTintColor: colorScheme.surfaceTint,
          ),
          _loading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator.adaptive()),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = _books[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: ListTile(
                          // Shape used in M3 Navigation specs
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          // Slightly tint the background of the item
                          tileColor: colorScheme.surfaceContainerLow,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                "${index + 1}",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            item['name'],
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: colorScheme.outline,
                          ),
                          onTap: () {
                            Get.to(
                              () => HadithListScreen(
                                bookId: item['id'],
                                bookName: item['name'],
                                collectionId: widget.collectionId,
                              ),
                            );
                          },
                        ),
                      );
                    }, childCount: _books.length),
                  ),
                ),
        ],
      ),
    );
  }
}
