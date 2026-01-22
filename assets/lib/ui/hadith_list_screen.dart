import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:get/get.dart';
import 'package:hadith_premium/controllers/theme_controller.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:text_scroll/text_scroll.dart';

import '../controllers/auth_controller.dart';
import '../controllers/bookmark_controller.dart';
import '../controllers/notification_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/social_controller.dart';
import '../services/db_service.dart';

class HadithListScreen extends StatefulWidget {
  final int bookId;
  final String bookName;
  final String collectionId;
  final dynamic targetHadithNumber;
  final int? targetUrn;
  final int? targetId;
  final String? searchQuery;

  const HadithListScreen({
    super.key,
    required this.bookId,
    required this.bookName,
    required this.collectionId,
    this.targetHadithNumber,
    this.targetUrn,
    this.targetId,
    this.searchQuery,
  });

  @override
  State<HadithListScreen> createState() => _HadithListScreenState();
}

class _HadithListScreenState extends State<HadithListScreen> {
  final DbService _dbService = DbService();

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  List<Map<String, dynamic>> _hadiths = [];
  bool _loading = true, isFirstIndexZero = false;

  @override
  void initState() {
    super.initState();
    _loadHadiths();
  }

  Future<void> _loadHadiths() async {
    final list = await _dbService.getHadiths(
      widget.collectionId,
      widget.bookId,
    );
    bool firstIdxZero = false;
    if (list.isNotEmpty && list.first['hadith_number'] == 0) {
      firstIdxZero = true;
    }
    setState(() {
      _hadiths = list;
      isFirstIndexZero = firstIdxZero;
      _loading = false;
    });

    // Handle deep linking after load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.targetId != null) {
        _scrollToId(widget.targetId!);
      } else if (widget.targetUrn != null) {
        _scrollToUrn(widget.targetUrn!);
      } else if (widget.targetHadithNumber != null) {
        _scrollToHadithNumber(widget.targetHadithNumber!);
      }
    });
  }

  void _scrollToId(int id) {
    final index = _hadiths.indexWhere((h) => h['id'] == id);
    if (index != -1) _jumpToIndex(index);
  }

  void _scrollToUrn(int urn) {
    final index = _hadiths.indexWhere((h) => h['c0'] == urn);
    if (index != -1) _jumpToIndex(index);
  }

  void _scrollToHadithNumber(dynamic hadithNumber) {
    final index = _hadiths.indexWhere(
      (h) => h['hadith_number'].toString() == hadithNumber.toString(),
    );
    if (index != -1) _jumpToIndex(index);
  }

  void _jumpToIndex(int index) {
    _itemScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var size = MediaQuery.of(context).size;
    final ThemeController _themeController = Get.find<ThemeController>();
    final SettingsController _settingsController =
        Get.find<SettingsController>();
    void _showSettingsBottomSheet(BuildContext context) {
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;

      showModalBottomSheet(
        context: context,
        backgroundColor: colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Settings",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Text("Font Size", style: theme.textTheme.titleMedium),
                Obx(
                  () => Row(
                    children: [
                      const Icon(Icons.text_fields, size: 16),
                      Expanded(
                        child: Slider(
                          value: _settingsController.fontSize.value,
                          min: 12.0,
                          max: 32.0,
                          divisions: 10,
                          label: _settingsController.fontSize.value
                              .round()
                              .toString(),
                          onChanged: (val) =>
                              _settingsController.updateFontSize(val),
                        ),
                      ),
                      const Icon(Icons.text_fields, size: 24),
                    ],
                  ),
                ),
                const Divider(),
                Obx(
                  () => SwitchListTile(
                    title: const Text("Show English Translation"),
                    subtitle: const Text("Toggle visibility of English text"),
                    value: _settingsController.showEnglish.value,
                    onChanged: (val) => _settingsController.toggleEnglish(val),
                  ),
                ),
                Obx(
                  () => SwitchListTile(
                    title: const Text("Dark Mode"),
                    subtitle: const Text("Toggle dark mode on/off"),
                    value: _themeController.isDarkMode,
                    onChanged: (val) {
                      _themeController.toggleThemeWithValue(val);
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      );
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            floating: false,
            snap: false,
            toolbarHeight: 64,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            backgroundColor: theme.scaffoldBackgroundColor,
            title: TextScroll(
              widget.bookName,
              mode: TextScrollMode.endless,
              velocity: const Velocity(pixelsPerSecond: Offset(30, 0)),
              delayBefore: const Duration(seconds: 2),
              pauseBetween: const Duration(seconds: 2),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
                fontSize: size.width * .049,
              ),
              textAlign: TextAlign.start,
              selectable: true,
            ),
            centerTitle: false,
            actionsPadding: EdgeInsets.only(right: size.width * .05),
            actions: [
              GestureDetector(
                onTap: () => _showSettingsBottomSheet(context),
                child: Icon(Icons.settings),
              ),
            ],
          ),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator.adaptive())
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ScrollablePositionedList.builder(
                  itemCount: _hadiths.length,
                  itemScrollController: _itemScrollController,
                  itemPositionsListener: _itemPositionsListener,
                  itemBuilder: (context, index) {
                    final item = _hadiths[index];

                    return _HadithCard(
                      item: item,
                      numberLabel: "Hadith ${index + 1}",
                      collectionId: widget.collectionId,
                      bookName: widget.bookName,
                      searchQuery: widget.searchQuery,
                      shouldGlow:
                          (widget.targetId != null &&
                              item['id'] == widget.targetId) ||
                          (widget.targetUrn != null &&
                              item['c0'] == widget.targetUrn),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class _HadithCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String numberLabel;
  final String collectionId;
  final String bookName;
  final bool shouldGlow;
  final String? searchQuery;

  _HadithCard({
    required this.item,
    required this.numberLabel,
    required this.collectionId,
    required this.bookName,
    this.shouldGlow = false,
    this.searchQuery,
  });

  final SettingsController _settingsController = Get.find<SettingsController>();
  final BookmarkController _bookmarkController = Get.find<BookmarkController>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    var size = MediaQuery.of(context).size;

    return GestureDetector(
      onLongPress: () => _showContextMenu(context),
      child: _GlowCard(
        animate: shouldGlow,
        child: Card(
          elevation: 0,
          color: colorScheme.surfaceContainerLow,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        numberLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: size.width * .029,
                        ),
                      ),
                    ),
                    if (item['grade'] != null &&
                        item['grade'].toString().isNotEmpty)
                      _buildGradeChip(context, item['grade'].toString()),
                  ],
                ),
                const SizedBox(height: 20),
                if (item['text_ar'] != null &&
                    item['text_ar'].toString().isNotEmpty) ...[
                  Obx(
                    () => HtmlWidget(
                      _processArabicText(item['text_ar'], context),
                      textStyle: theme.textTheme.headlineSmall?.copyWith(
                        fontFamily: 'qalammajeed3',
                        fontSize: _settingsController.fontSize.value * 1.4,
                        height: 1.8,
                        color: colorScheme.onSurface,
                        wordSpacing: 2.2,
                      ),
                      customStylesBuilder: (element) {
                        if (element.localName == 'p' ||
                            element.localName == 'div') {
                          return {'text-align': 'right', 'direction': 'rtl'};
                        }
                        return null;
                      },
                    ),
                  ),
                  if (item['explanation_ar'] != null &&
                      item['explanation_ar'].toString().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    HtmlWidget(
                      item['explanation_ar'],
                      textStyle: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'qalammajeed3',
                        fontSize: _settingsController.fontSize.value * 1.1,
                        color: colorScheme.secondary,
                      ),
                      customStylesBuilder: (element) {
                        if (element.localName == 'p' ||
                            element.localName == 'div') {
                          return {'text-align': 'right', 'direction': 'rtl'};
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
                if (item['narrator'] != null &&
                    item['narrator'].toString().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    "Narrated by ${item['narrator']}",
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.2,
                      fontSize: size.width * .037,
                    ),
                    textAlign: TextAlign.start,
                  ),
                ],
                Obx(
                  () => Visibility(
                    visible: _settingsController.showEnglish.value,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        HtmlWidget(
                          _highlightText(
                            item['text_en'] ?? item['text'] ?? "",
                            searchQuery,
                          ),
                          textStyle: theme.textTheme.bodyLarge?.copyWith(
                            fontSize: _settingsController.fontSize.value * 0.9,
                            height: 1.6,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (item['explanation_en'] != null &&
                            item['explanation_en'].toString().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: HtmlWidget(
                              _highlightText(
                                item['explanation_en'],
                                searchQuery,
                              ),
                              textStyle: theme.textTheme.bodySmall?.copyWith(
                                fontSize:
                                    _settingsController.fontSize.value * 0.9,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 11),
                Text("Source: ${item['reference']}"),
                _buildSimilarHadithsButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _highlightText(String text, String? query) {
    if (query == null || query.isEmpty) return text;
    final escapedQuery = RegExp.escape(query);
    final regex = RegExp(escapedQuery, caseSensitive: false);
    return text.replaceAllMapped(regex, (match) {
      return '<span style="color: #2196F3; font-weight: bold;">${match.group(0)}</span>';
    });
  }

  Widget _buildSimilarHadithsButton(BuildContext context) {
    final similarUrnsStr = item['similar_urns']?.toString() ?? "";
    if (similarUrnsStr.isEmpty) return const SizedBox();

    final List<int> similarUrns = similarUrnsStr
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .toList();

    if (similarUrns.isEmpty) return const SizedBox();

    return TextButton.icon(
      onPressed: () => _showSimilarHadiths(context, similarUrns),
      icon: const Icon(Icons.compare_arrows, size: 16),
      label: Text(
        "${similarUrns.length} similar hadiths",
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  void _showSimilarHadiths(BuildContext context, List<int> urns) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Similar Hadiths",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: DbService().getHadithsByUrns(urns),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator.adaptive(),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  final similarList = snapshot.data ?? [];
                  if (similarList.isEmpty) {
                    return const Center(child: Text("No details found."));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: similarList.length,
                    itemBuilder: (context, index) {
                      final sItem = similarList[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: theme.colorScheme.surfaceContainerLow,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.pop(context);
                            Get.to(
                              () => HadithListScreen(
                                bookId: sItem['book_id'],
                                bookName: sItem['book_name'],
                                collectionId: sItem['collection_id'].toString(),
                                targetUrn: sItem['c0'],
                              ),
                              preventDuplicates: false,
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${sItem['collection_name']} > ${sItem['book_name']} #${sItem['hadith_number']}",
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (sItem['text_ar'] != null)
                                  Text(
                                    sItem['text_ar'],
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontFamily: 'qalammajeed3',
                                      fontSize: 16,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                if (sItem['text_en'] != null)
                                  Text(
                                    sItem['text_en'],
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.bookmark_add_outlined),
            title: const Text("Bookmark"),
            onTap: () {
              Navigator.pop(context);
              _showBookmarkDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.share_outlined),
            title: const Text("Share with Friends"),
            onTap: () {
              Navigator.pop(context);
              _showShareDialog(context);
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _showShareDialog(BuildContext context) {
    final SocialController socialController = Get.find<SocialController>();
    final NotificationController notifyController =
        Get.find<NotificationController>();
    final annotationController = TextEditingController();
    final commentController = TextEditingController();
    final RxList<String> selectedFriendIds = <String>[].obs;

    socialController.fetchFriends();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Share Hadith",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: annotationController,
                decoration: const InputDecoration(
                  labelText: "Annotation (Internal note)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  labelText: "Comment (For recipient)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Select Friends:"),
              const SizedBox(height: 12),
              Obx(
                () => Column(
                  children: socialController.friends.map((f) {
                    final userId = Get.find<AuthController>().user.value!.id;
                    final isSender = f['sender_id'] == userId;
                    final friendName = isSender
                        ? f['receiver']['username']
                        : f['sender']['username'];
                    final friendId = isSender
                        ? f['receiver_id']
                        : f['sender_id'];

                    return CheckboxListTile(
                      title: Text(friendName),
                      value: selectedFriendIds.contains(friendId),
                      onChanged: (val) {
                        if (val == true) {
                          selectedFriendIds.add(friendId);
                        } else {
                          selectedFriendIds.remove(friendId);
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  if (selectedFriendIds.isEmpty) {
                    Get.snackbar("Error", "Select at least one friend");
                    return;
                  }
                  notifyController.shareWithFriends(
                    receiverIds: selectedFriendIds,
                    collectionId: collectionId,
                    bookId: item['book_id'],
                    bookName: bookName,
                    hadithNumber: int.parse(item['hadith_number']),
                    textEn: item['text_en'] ?? item['text'],
                    textAr: item['text_ar'],
                    annotation: annotationController.text,
                    comment: commentController.text,
                  );
                  Get.back();
                },
                child: const Text("Share Now"),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showBookmarkDialog(BuildContext context) {
    final TextEditingController folderController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Bookmark Hadith"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Select a folder or create a new one:"),
              const SizedBox(height: 16),
              Obx(
                () => DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: "Folder"),
                  items: [
                    ..._bookmarkController.folders.map(
                      (f) => DropdownMenuItem(
                        value: f['id'] as int,
                        child: Text(f['name']),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      _saveBookmark(context, val);
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: folderController,
                decoration: const InputDecoration(
                  labelText: "New Folder Name",
                  suffixIcon: Icon(Icons.add),
                ),
                onSubmitted: (val) async {
                  if (val.isNotEmpty) {
                    final id = await _bookmarkController.createFolder(val);
                    _saveBookmark(context, id);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  void _saveBookmark(BuildContext context, int folderId) {
    _bookmarkController.addBookmark(
      folderId: folderId,
      collectionId: collectionId,
      bookId: item['book_id'],
      bookName: bookName,
      hadithNumber: int.parse(item['hadith_number']),
      textEn: item['text_en'] ?? item['text'],
      textAr: item['text_ar'],
      chapterName: "Chapter", // You might want to extract this if available
    );
  }

  Widget _buildGradeChip(BuildContext context, String grade) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    String processedGrade = grade.contains("null:")
        ? grade.substring(grade.indexOf(":") + 1).trim()
        : grade;

    var size = MediaQuery.of(context).size;

    return LayoutBuilder(
      builder: (context, constraints) {
        final style = theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontSize: size.width * .029,
        );

        // Calculate text width
        final textPainter = TextPainter(
          text: TextSpan(text: processedGrade, style: style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(minWidth: 0, maxWidth: double.infinity);

        final bool isOverflowing =
            textPainter.width > (size.width * .35 - 20); // Width minus padding

        return Container(
          width: size.width * .35,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: isOverflowing
              ? TextScroll(
                  processedGrade,
                  mode: TextScrollMode.endless,
                  velocity: const Velocity(pixelsPerSecond: Offset(30, 0)),
                  delayBefore: const Duration(seconds: 2),
                  pauseBetween: const Duration(seconds: 2),
                  intervalSpaces: 20,
                  style: style,
                  textAlign: TextAlign.center,
                  selectable: true,
                )
              : Text(
                  processedGrade,
                  style: style,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
        );
      },
    );
  }

  String _processArabicText(String text, BuildContext context) {
    if (text.isEmpty) return "";
    String processed = text;
    final colorScheme = Theme.of(context).colorScheme;
    final narratorColor =
        '#${colorScheme.primary.value.toRadixString(16).substring(2)}';

    processed = processed.replaceAllMapped(
      RegExp(r'\[narrator.*?\](.*?)\[/narrator\]'),
      (match) =>
          '<span style="color: $narratorColor; font-weight: 600;">${match.group(1)}</span>',
    );
    processed = processed.replaceAll(
      '[prematn]',
      '<div style="margin-bottom: 8px; opacity: 0.8;">',
    );
    processed = processed.replaceAll('[/prematn]', '</div>');
    processed = processed.replaceAll(
      '[matn]',
      '<div style="font-weight: bold; margin-top: 8px;">',
    );
    processed = processed.replaceAll('[/matn]', '</div>');

    return processed;
  }
}

class _GlowCard extends StatefulWidget {
  final Widget child;
  final bool animate;

  const _GlowCard({required this.child, required this.animate});

  @override
  State<_GlowCard> createState() => _GlowCardState();
}

class _GlowCardState extends State<_GlowCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.animate) {
      _controller.repeat(reverse: true);
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (mounted) _controller.stop();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: widget.animate
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(
                        _animation.value * 0.5,
                      ),
                      blurRadius: 15 * _animation.value,
                      spreadRadius: 2 * _animation.value,
                    ),
                  ]
                : [],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
