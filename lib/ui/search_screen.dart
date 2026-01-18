import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../controllers/hadith_search_controller.dart';
import 'hadith_list_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final HadithSearchController searchController =
      Get.find<HadithSearchController>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        searchController.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Search Hadiths precisely...",
            border: InputBorder.none,
          ),
          onChanged: searchController.onSearchChanged,
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          Obx(
            () => searchController.searchQuery.value.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      searchController.onSearchChanged("");
                    },
                  )
                : const SizedBox(),
          ),
        ],
      ),
      body: Obx(() {
        if (searchController.isLoading.value) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        if (searchController.searchQuery.value.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  "Search by topic, word, or Hadith number",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        if (searchController.searchResults.isEmpty) {
          return const Center(child: Text("No results found."));
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    "Showing ${searchController.searchResults.length} results",
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount:
                    searchController.searchResults.length +
                    (searchController.hasMore.value ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == searchController.searchResults.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: CircularProgressIndicator.adaptive(),
                      ),
                    );
                  }

                  final result = searchController.searchResults[index];
                  final String query = searchController.searchQuery.value;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: colorScheme.surfaceContainerLow,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Get.to(
                          () => HadithListScreen(
                            bookId: result['book_id'],
                            bookName: result['book_name'],
                            collectionId: result['collection_id'],
                            targetHadithNumber: result['hadith_number'],
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.layers_outlined,
                                  size: 14,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    "${result['collection_name']} > ${result['book_name']}",
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  "#${result['hadith_number']}",
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            if (result['text_ar'] != null &&
                                result['text_ar'].toLowerCase().contains(
                                  query.toLowerCase(),
                                ))
                              _buildSnippet(
                                context,
                                result['text_ar'],
                                query,
                                isArabic: true,
                              ),

                            if (result['text_en'] != null)
                              _buildSnippet(
                                context,
                                result['text_en'] ?? result['text'] ?? "",
                                query,
                                isArabic: false,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSnippet(
    BuildContext context,
    String text,
    String query, {
    required bool isArabic,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    int matchIdx = text.toLowerCase().indexOf(query.toLowerCase());
    if (matchIdx == -1 && !isArabic) return const SizedBox();

    if (matchIdx == -1)
      matchIdx =
          0; // Fallback for Arabic if needed (though usually SQL LIKE handles it)

    int start = (matchIdx - 50).clamp(0, text.length);
    int end = (matchIdx + 150).clamp(0, text.length);
    String snippet = text.substring(start, end);
    if (start > 0) snippet = "...$snippet";
    if (end < text.length) snippet = "$snippet...";

    String highlighted = snippet.replaceAllMapped(
      RegExp(query, caseSensitive: false),
      (match) =>
          "<b><span style='color: ${colorScheme.primary.value.toRadixString(16).substring(2)};'>${match.group(0)}</span></b>",
    );

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: isArabic
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          HtmlWidget(
            highlighted,
            textStyle:
                (isArabic
                        ? theme.textTheme.bodyMedium?.copyWith(
                            fontFamily: 'qalammajeed3',
                            height: 1.5,
                          )
                        : theme.textTheme.bodySmall)
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
