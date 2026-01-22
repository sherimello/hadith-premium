// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../services/db_service.dart';
// import '../controllers/theme_controller.dart';
// import '../controllers/settings_controller.dart';
// import 'books_screen.dart';
// import 'bookmarks_screen.dart';
// import 'search_screen.dart';
// import 'social_screen.dart';
// import 'notifications_screen.dart';
// import 'profile_screen.dart';
// import '../controllers/auth_controller.dart';
// import '../controllers/notification_controller.dart';
//
// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});
//
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> {
//   final DbService _dbService = DbService();
//   final ThemeController _themeController = Get.find<ThemeController>();
//   final SettingsController _settingsController = Get.find<SettingsController>();
//   final AuthController _authController = Get.find<AuthController>();
//   final NotificationController _notificationController =
//       Get.find<NotificationController>();
//
//   List<Map<String, dynamic>> _collections = [];
//   bool _loading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadCollections();
//   }
//
//   Future<void> _loadCollections() async {
//     final list = await _dbService.getCollections();
//     setState(() {
//       _collections = list;
//       _loading = false;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;
//
//     return Scaffold(
//       body: CustomScrollView(
//         slivers: [
//           SliverAppBar.large(
//             backgroundColor: theme.scaffoldBackgroundColor,
//             title: const Text("Collections"),
//             leading: IconButton(
//               icon: const Icon(Icons.person_outline),
//               onPressed: () => Get.to(() => const ProfileScreen()),
//             ),
//             actions: [
//               IconButton.filledTonal(
//                 icon: Obx(
//                   () => Badge(
//                     label: Text(
//                       _notificationController.unreadCount.value.toString(),
//                     ),
//                     isLabelVisible:
//                         _notificationController.unreadCount.value > 0,
//                     child: Icon(
//                       Icons.notifications_outlined,
//                       color: _themeController.isDarkMode
//                           ? Colors.black
//                           : Colors.white,
//                     ),
//                   ),
//                 ),
//                 onPressed: () => Get.to(() => const NotificationsScreen()),
//               ),
//               const SizedBox(width: 8),
//               IconButton.filledTonal(
//                 icon: Icon(
//                   Icons.group_outlined,
//                   color: _themeController.isDarkMode
//                       ? Colors.black
//                       : Colors.white,
//                 ),
//                 onPressed: () => Get.to(() => const SocialScreen()),
//               ),
//               const SizedBox(width: 8),
//               IconButton.filledTonal(
//                 icon: Icon(
//                   Icons.search,
//                   color: _themeController.isDarkMode
//                       ? Colors.black
//                       : Colors.white,
//                 ),
//                 onPressed: () => Get.to(() => const SearchScreen()),
//               ),
//               const SizedBox(width: 8),
//               IconButton.filledTonal(
//                 icon: Icon(
//                   Icons.bookmarks_outlined,
//                   color: _themeController.isDarkMode
//                       ? Colors.black
//                       : Colors.white,
//                 ),
//                 onPressed: () => Get.to(() => const BookmarksScreen()),
//               ),
//               const SizedBox(width: 8),
//               IconButton.filledTonal(
//                 icon: Icon(
//                   Icons.settings_outlined,
//                   color: _themeController.isDarkMode
//                       ? Colors.black
//                       : Colors.white,
//                 ),
//                 onPressed: () => _showSettingsBottomSheet(context),
//               ),
//               const SizedBox(width: 8),
//               IconButton.filledTonal(
//                 icon: Obx(
//                   () => Icon(
//                     _themeController.isDarkMode
//                         ? Icons.light_mode_outlined
//                         : Icons.dark_mode_outlined,
//                     color: _themeController.isDarkMode
//                         ? Colors.black
//                         : Colors.white,
//                   ),
//                 ),
//                 onPressed: () => _themeController.toggleTheme(),
//               ),
//               const SizedBox(width: 8),
//             ],
//           ),
//           SliverToBoxAdapter(
//             child: Obx(
//               () => Padding(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 8,
//                 ),
//                 child: Text(
//                   "Salam, ${_authController.profile['username'] ?? 'User'}!",
//                   style: theme.textTheme.titleMedium?.copyWith(
//                     color: colorScheme.primary,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           _loading
//               ? const SliverFillRemaining(
//                   child: Center(child: CircularProgressIndicator.adaptive()),
//                 )
//               : SliverPadding(
//                   padding: const EdgeInsets.all(16),
//                   sliver: SliverGrid(
//                     gridDelegate:
//                         const SliverGridDelegateWithFixedCrossAxisCount(
//                           crossAxisCount: 2,
//                           mainAxisSpacing: 12,
//                           crossAxisSpacing: 12,
//                           childAspectRatio: 1.1,
//                         ),
//                     delegate: SliverChildBuilderDelegate((context, index) {
//                       final item = _collections[index];
//                       return _CollectionCard(item: item);
//                     }, childCount: _collections.length),
//                   ),
//                 ),
//         ],
//       ),
//     );
//   }
//
//   void _showSettingsBottomSheet(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;
//
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: colorScheme.surface,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
//       ),
//       builder: (context) {
//         return Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 "Settings",
//                 style: theme.textTheme.headlineSmall?.copyWith(
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 24),
//               Text("Font Size", style: theme.textTheme.titleMedium),
//               Obx(
//                 () => Row(
//                   children: [
//                     const Icon(Icons.text_fields, size: 16),
//                     Expanded(
//                       child: Slider(
//                         value: _settingsController.fontSize.value,
//                         min: 12.0,
//                         max: 32.0,
//                         divisions: 10,
//                         label: _settingsController.fontSize.value
//                             .round()
//                             .toString(),
//                         onChanged: (val) =>
//                             _settingsController.updateFontSize(val),
//                       ),
//                     ),
//                     const Icon(Icons.text_fields, size: 24),
//                   ],
//                 ),
//               ),
//               const Divider(),
//               Obx(
//                 () => SwitchListTile(
//                   title: const Text("Show English Translation"),
//                   subtitle: const Text("Toggle visibility of English text"),
//                   value: _settingsController.showEnglish.value,
//                   onChanged: (val) => _settingsController.toggleEnglish(val),
//                 ),
//               ),
//               const SizedBox(height: 16),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }
//
// class _CollectionCard extends StatelessWidget {
//   final Map<String, dynamic> item;
//
//   const _CollectionCard({required this.item});
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;
//
//     return Card(
//       elevation: 0,
//       margin: EdgeInsets.zero,
//       color: colorScheme.surfaceContainer,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(24),
//         side: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
//       ),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(24),
//         onTap: () {
//           Get.to(
//             () => BooksScreen(
//               collectionId: item['id'],
//               collectionName: item['name'],
//             ),
//           );
//         },
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: colorScheme.primary.withOpacity(0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(
//                   Icons.auto_stories_outlined,
//                   color: colorScheme.primary,
//                   size: 32,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 item['name'],
//                 textAlign: TextAlign.center,
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//                 style: theme.textTheme.titleMedium?.copyWith(
//                   fontWeight: FontWeight.bold,
//                   color: colorScheme.onSurface,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hadith_premium/utils/app_theme.dart';
import 'package:text_scroll/text_scroll.dart';
import '../services/db_service.dart';
import '../controllers/theme_controller.dart';
import '../controllers/settings_controller.dart';
import 'books_screen.dart';
import 'bookmarks_screen.dart';
import 'search_screen.dart';
import 'social_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import '../controllers/auth_controller.dart';
import '../controllers/notification_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final DbService _dbService = DbService();
  final ThemeController _themeController = Get.find<ThemeController>();
  final SettingsController _settingsController = Get.find<SettingsController>();
  final AuthController _authController = Get.find<AuthController>();
  final NotificationController _notificationController =
      Get.find<NotificationController>();

  List<Map<String, dynamic>> _collections = [];
  bool _loading = true;

  // Animation controller for the expandable menu
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _loadCollections();

    // Initialize animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadCollections() async {
    final list = await _dbService.getCollections();
    setState(() {
      _collections = list;
      _loading = false;
    });
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
      _isMenuOpen
          ? _animationController.forward()
          : _animationController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    var size = MediaQuery.of(context).size;

    return Scaffold(
      // --- ANIMATED FLOATING MENU ---
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildMenuItem(
            icon: Icons.settings_outlined,
            label: "Settings",
            isDarkMode: _themeController.isDarkMode,
            onTap: () => _showSettingsBottomSheet(context),
          ),
          _buildMenuItem(
            icon: Icons.bookmarks_outlined,
            label: "Bookmarks",
            isDarkMode: _themeController.isDarkMode,
            onTap: () => Get.to(() => const BookmarksScreen()),
          ),
          _buildMenuItem(
            icon: Icons.search,
            label: "Search",
            isDarkMode: _themeController.isDarkMode,
            onTap: () => Get.to(() => const SearchScreen()),
          ),
          _buildMenuItem(
            icon: Icons.group_outlined,
            label: "Social",
            isDarkMode: _themeController.isDarkMode,
            onTap: () => Get.to(() => const SocialScreen()),
          ),
          _buildMenuItem(
            icon: Icons.notifications_outlined,
            label: "Alerts",
            isDarkMode: _themeController.isDarkMode,
            isNotification: true,
            onTap: () => Get.to(() => const NotificationsScreen()),
          ),
          _buildMenuItem(
            icon: _themeController.isDarkMode
                ? Icons.light_mode
                : Icons.dark_mode,
            label: "Theme",
            isDarkMode: _themeController.isDarkMode,
            isObx: true,
            onTap: () => _themeController.toggleTheme(),
          ),
          const SizedBox(height: 11),
          FloatingActionButton(
            backgroundColor: _expandAnimation.status.isForwardOrCompleted
                ? colorScheme.primary
                : Colors.white,
            foregroundColor: colorScheme.onPrimary,
            onPressed: _toggleMenu,
            child: AnimatedIcon(
              icon: AnimatedIcons.menu_close,
              color: Colors.black,
              progress: _expandAnimation,
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            centerTitle: false,
            leadingWidth: 50,
            // leading: Padding(
            //   padding: const EdgeInsets.only(left: 16),
            //   child: Image.asset(
            //     "assets/images/icon.png",
            //     fit: BoxFit.contain,
            //     width: size.width * .055,
            //     height: size.width * .055,
            //     errorBuilder: (context, error, stackTrace) =>
            //     const Icon(Icons.menu_book, color: Colors.grey),
            //   ),
            // ),
            automaticallyImplyLeading: false,
            title: Row(
              spacing: 9,
              children: [
                Image.asset(
                  "assets/images/icon.png",
                  fit: BoxFit.contain,
                  width: size.width * .065,
                  height: size.width * .065,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.menu_book, color: Colors.grey),
                ),
                Text(
                  "Hadith Premium",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: size.width * .045,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.person_outline,
                  color: _themeController.isDarkMode
                      ? Colors.white
                      : Colors.black,
                ),
                onPressed: () => Get.to(() => const ProfileScreen()),
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Obx(
              () => Padding(
                padding: const EdgeInsets.only(left: 27, top: 27, bottom: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Salam, ${_authController.profile['full_name'] ?? 'User'}!",
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: _themeController.isDarkMode ? AppColors.goldPrimary : AppColors.goldDark,
                        // color: _themeController.isDarkMode ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Start reading Hadith today!",
                      style: TextStyle(
                        fontSize: 21,
                        color: _themeController.isDarkMode ? Colors.white38 : Colors.black54,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _loading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator.adaptive()),
                )
              : SliverPadding(
                  padding: EdgeInsets.fromLTRB(27, 27, 27, size.height * .25),
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
                      return _CollectionCard(
                        item: item,
                        themeController: _themeController,
                      );
                    }, childCount: _collections.length),
                  ),
                ),
        ],
      ),
    );
  }

  // Helper to build items for the animated FAB menu
  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isNotification = false,
    bool isObx = false,
    bool isDarkMode = false,
  }) {
    return ScaleTransition(
      scale: _expandAnimation,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _expandAnimation,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isDarkMode ? Colors.black : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            FloatingActionButton.small(
              heroTag: label, // Unique tag for each FAB
              onPressed: () {
                _toggleMenu();
                onTap();
              },
              child: isNotification
                  ? Obx(
                      () => Badge(
                        label: Text(
                          _notificationController.unreadCount.value.toString(),
                        ),
                        isLabelVisible:
                            _notificationController.unreadCount.value > 0,
                        child: Icon(icon),
                      ),
                    )
                  : isObx
                  ? Obx(
                      () => Icon(
                        _themeController.isDarkMode
                            ? Icons.light_mode
                            : Icons.dark_mode,
                      ),
                    )
                  : Icon(icon),
            ),
          ],
        ),
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
  final ThemeController themeController;

  const _CollectionCard({required this.item, required this.themeController});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    var size = MediaQuery.of(context).size;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Get.to(
            () => BooksScreen(
              collectionId: item['id'].toString(),
              collectionName: item['name_en'],
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: themeController.isDarkMode
                      ? Colors.white.withOpacity(.21)
                      : Colors.black.withOpacity(.21),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  item["name_en"].toString().substring(0, 1),
                  style: TextStyle(
                    color: themeController.isDarkMode
                        ? Colors.white
                        : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: size.width * .05,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextScroll(
                item['name_en'],
                mode: TextScrollMode.endless,
                velocity: const Velocity(pixelsPerSecond: Offset(30, 0)),
                delayBefore: const Duration(seconds: 2),
                pauseBetween: const Duration(seconds: 2),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                  fontSize: size.width * .039
                ),
                textAlign: TextAlign.center,
                selectable: true,
              ),
              // Text(
              //   item['name_en'],
              //   textAlign: TextAlign.center,
              //   maxLines: 2,
              //   overflow: TextOverflow.ellipsis,
              //   style: theme.textTheme.titleMedium?.copyWith(
              //     fontWeight: FontWeight.bold,
              //     color: colorScheme.onSurface,
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
