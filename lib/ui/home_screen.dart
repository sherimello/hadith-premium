import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/db_service.dart';
import '../controllers/theme_controller.dart';
import '../controllers/settings_controller.dart';
import 'books_screen.dart';
import 'bookmarks_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DbService _dbService = DbService();
  final ThemeController _themeController = Get.find<ThemeController>();
  final SettingsController _settingsController = Get.find<SettingsController>();

  List<Map<String, dynamic>> _collections = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  Future<void> _loadCollections() async {
    final list = await _dbService.getCollections();
    setState(() {
      _collections = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            backgroundColor: theme.scaffoldBackgroundColor,
            title: const Text("Collections"),
            actions: [
              IconButton.filledTonal(
                icon: Icon(
                  Icons.bookmarks_outlined,
                  color: _themeController.isDarkMode
                      ? Colors.black
                      : Colors.white,
                ),
                onPressed: () => Get.to(() => const BookmarksScreen()),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                icon: Icon(
                  Icons.settings_outlined,
                  color: _themeController.isDarkMode
                      ? Colors.black
                      : Colors.white,
                ),
                onPressed: () => _showSettingsBottomSheet(context),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                icon: Obx(
                  () => Icon(
                    _themeController.isDarkMode
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    color: _themeController.isDarkMode
                        ? Colors.black
                        : Colors.white,
                  ),
                ),
                onPressed: () => _themeController.toggleTheme(),
              ),
              const SizedBox(width: 16),
            ],
          ),
          _loading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator.adaptive()),
                )
              : SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.1,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = _collections[index];
                      return _CollectionCard(item: item);
                    }, childCount: _collections.length),
                  ),
                ),
        ],
      ),
    );
  }

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
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _CollectionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Get.to(
            () => BooksScreen(
              collectionId: item['id'],
              collectionName: item['name'],
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_stories_outlined,
                  color: colorScheme.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                item['name'],
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
