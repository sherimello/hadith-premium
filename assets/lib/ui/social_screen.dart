import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/social_controller.dart';
import '../controllers/auth_controller.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final SocialController _socialController = Get.find<SocialController>();
  final AuthController _authController = Get.find<AuthController>();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _socialController.fetchFriends();
    _socialController.fetchRequests();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Social"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Friends"),
              Tab(text: "Requests"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFriendsTab(colorScheme, theme),
            _buildRequestsTab(colorScheme, theme),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddFriendDialog,
          icon: const Icon(Icons.person_add_outlined),
          label: const Text("Add Friend"),
        ),
      ),
    );
  }

  Widget _buildFriendsTab(ColorScheme colorScheme, ThemeData theme) {
    return Obx(() {
      if (_socialController.isLoading.value) {
        return const Center(child: CircularProgressIndicator.adaptive());
      }

      if (_socialController.friends.isEmpty) {
        return const Center(child: Text("No friends yet. Add some!"));
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _socialController.friends.length,
        itemBuilder: (context, index) {
          final f = _socialController.friends[index];
          final userId = _authController.user.value?.id;
          final isSender = f['sender_id'] == userId;
          final friendName = isSender
              ? f['receiver']['username']
              : f['sender']['username'];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Text(friendName[0].toUpperCase()),
              ),
              title: Text(friendName),
              trailing: const Icon(Icons.chat_bubble_outline, size: 20),
            ),
          );
        },
      );
    });
  }

  Widget _buildRequestsTab(ColorScheme colorScheme, ThemeData theme) {
    return Obx(() {
      if (_socialController.pendingRequests.isEmpty) {
        return const Center(child: Text("No pending requests."));
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _socialController.pendingRequests.length,
        itemBuilder: (context, index) {
          final req = _socialController.pendingRequests[index];
          final senderName = req['sender']['username'];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text("Request from $senderName"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () =>
                        _socialController.respondToRequest(req['id'], true),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () =>
                        _socialController.respondToRequest(req['id'], false),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  void _showAddFriendDialog() {
    Get.defaultDialog(
      title: "Add Friend",
      content: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: "Enter unique username",
          prefixIcon: Icon(Icons.person_search_outlined),
        ),
      ),
      textConfirm: "Send",
      textCancel: "Cancel",
      onConfirm: () {
        if (_searchController.text.isNotEmpty) {
          _socialController.sendRequest(_searchController.text.trim());
          _searchController.clear();
          Get.back();
        }
      },
    );
  }
}
