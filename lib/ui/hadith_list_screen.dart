import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:get/get.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:text_scroll/text_scroll.dart';

import '../services/db_service.dart';
import '../controllers/settings_controller.dart';
import '../controllers/bookmark_controller.dart';
import '../controllers/social_controller.dart';
import '../controllers/notification_controller.dart';
import '../controllers/auth_controller.dart';

class HadithListScreen extends StatefulWidget {
  final int bookId;
  final String bookName;
  final String collectionId;
  final int? targetHadithNumber;

  const HadithListScreen({
    super.key,
    required this.bookId,
    required this.bookName,
    required this.collectionId,
    this.targetHadithNumber,
  });

  @override
  State<HadithListScreen> createState() => _HadithListScreenState();
}

class _HadithListScreenState extends State<HadithListScreen> {
  final DbService _dbService = DbService();
  final SettingsController _settingsController = Get.find<SettingsController>();

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
    final list = await _dbService.getHadiths(widget.bookId);
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
    if (widget.targetHadithNumber != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToHadith(widget.targetHadithNumber!);
      });
    }
  }

  void _scrollToHadith(int hadithNumber) {
    final index = _hadiths.indexWhere(
      (h) => h['hadith_number'] == hadithNumber,
    );
    if (index != -1) {
      _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            title: SizedBox(
              height: 32,
              child: TextScroll(
                widget.bookName,
                mode: TextScrollMode.endless,
                velocity: const Velocity(pixelsPerSecond: Offset(30, 0)),
                delayBefore: const Duration(seconds: 2),
                pauseBetween: const Duration(seconds: 2),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.start,
                selectable: true,
              ),
            ),
            centerTitle: false,
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
                    final currentNum = isFirstIndexZero
                        ? item['hadith_number'] + 1
                        : item['hadith_number'];

                    String label = "Hadith $currentNum";

                    // if (index > 0) {
                    //   final prevItem = _hadiths[index - 1];
                    //   final prevNum = isFirstIndexZero
                    //       ? prevItem['hadith_number'] + 1
                    //       : prevItem['hadith_number'];
                    //
                    //   if (currentNum == prevNum) {
                    //     label = "Linked to Hadith $prevNum";
                    //   }
                    // }

                    return _HadithCard(
                      item: item,
                      numberLabel: label,
                      collectionId: widget.collectionId,
                      bookName: widget.bookName,
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

  _HadithCard({
    required this.item,
    required this.numberLabel,
    required this.collectionId,
    required this.bookName,
  });

  final SettingsController _settingsController = Get.find<SettingsController>();
  final BookmarkController _bookmarkController = Get.find<BookmarkController>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onLongPress: () => _showContextMenu(context),
      child: Card(
        elevation: 0,
        color:
            // numberLabel.contains("Linked")
            //     ? colorScheme.primaryContainer.withAlpha(50)
            //     :
            colorScheme.surfaceContainerLow,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
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
                      ),
                    ),
                  ),
                  const Spacer(),
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
                      fontSize: _settingsController.fontSize.value * 1.5,
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
                const SizedBox(height: 16),
              ],
              Obx(
                () => Visibility(
                  visible: _settingsController.showEnglish.value,
                  child: HtmlWidget(
                    item['text_en'] ?? item['text'] ?? "",
                    textStyle: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: _settingsController.fontSize.value,
                      height: 1.6,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              if (item['narrator'] != null &&
                  item['narrator'].toString().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  "Narrated by ${item['narrator']}",
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.end,
                ),
              ],
            ],
          ),
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
                    hadithNumber: item['hadith_number'],
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
      hadithNumber: item['hadith_number'],
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        processedGrade,
        style: theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
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
