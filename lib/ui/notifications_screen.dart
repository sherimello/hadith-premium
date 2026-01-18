import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/notification_controller.dart';
import 'shared_hadith_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationController _notificationController =
      Get.find<NotificationController>();

  @override
  void initState() {
    super.initState();
    _notificationController.fetchShares();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Inbox"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _notificationController.fetchShares(),
          ),
        ],
      ),
      body: Obx(() {
        if (_notificationController.isLoading.value) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        if (_notificationController.receivedShares.isEmpty) {
          return const Center(child: Text("No shared hadiths yet."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _notificationController.receivedShares.length,
          itemBuilder: (context, index) {
            final share = _notificationController.receivedShares[index];
            final bool isUnread = share['read_status'] == false;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: isUnread ? 2 : 0,
              color: isUnread
                  ? colorScheme.surfaceContainerHigh
                  : colorScheme.surfaceContainerLow,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: colorScheme.primary,
                  child: const Icon(Icons.share, color: Colors.white, size: 20),
                ),
                title: Text(
                  "From ${share['sender']['username']}",
                  style: TextStyle(
                    fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  "${share['book_name']} #${share['hadith_number']}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  _notificationController.markAsRead(share['id']);
                  Get.to(() => SharedHadithDetailScreen(share: share));
                },
              ),
            );
          },
        );
      }),
    );
  }
}
