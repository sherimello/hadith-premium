import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hadith_premium/ui/auth_screen.dart';
import 'package:share_plus/share_plus.dart';
import '../controllers/auth_controller.dart';
import '../controllers/bookmark_controller.dart';
import '../controllers/social_controller.dart';
import '../controllers/notification_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final bookmarkController = Get.find<BookmarkController>();
    final socialController = Get.find<SocialController>();
    final notificationController = Get.find<NotificationController>();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final profile = authController.profile;
    final user = authController.user.value;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text("My Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async{
              await authController.signOut();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (builder) => AuthScreen()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header: Avatar and Name
            CircleAvatar(
              radius: 50,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                (profile['full_name'] ?? 'U')[0].toUpperCase(),
                style: theme.textTheme.displayMedium?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w900
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              profile['full_name'] ?? "User",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              user?.email ?? "",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.outline,
              ),
            ),
            const SizedBox(height: 32),

            // Username Card
            Card(
              elevation: 0,
              color: colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      "Your Unique Username",
                      style: theme.textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      profile['username'] ?? "N/A",
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: profile['username'] ?? ""),
                            );
                            Get.snackbar(
                              "Copied",
                              "Username copied to clipboard",
                            );
                          },
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text("Copy"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            Share.share(
                              "Add me on Hadith Premium! My username is: ${profile['username']}",
                            );
                          },
                          icon: const Icon(Icons.share, size: 18),
                          label: const Text("Share"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Statistics Section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "App Usage",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard(
                  context,
                  "Bookmarks",
                  bookmarkController.folders.length
                      .toString(), // Folders as proxy for stats
                  Icons.bookmarks_outlined,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  context,
                  "Friends",
                  socialController.friends.length.toString(),
                  Icons.group_outlined,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  context,
                  "Received",
                  notificationController.receivedShares.length.toString(),
                  Icons.inbox_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          children: [
            Icon(icon, color: colorScheme.primary, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
