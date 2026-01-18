import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SocialController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;

  final RxList<Map<String, dynamic>> friends = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> pendingRequests =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  Future<void> fetchFriends() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    isLoading.value = true;
    try {
      // Fetch accepted friendships
      final data = await _supabase
          .from('friendships')
          .select(
            '*, sender:sender_id(username), receiver:receiver_id(username)',
          )
          .or('sender_id.eq.$userId,receiver_id.eq.$userId')
          .eq('status', 'accepted');

      friends.assignAll(List<Map<String, dynamic>>.from(data));
    } catch (e) {
      print("Error fetching friends: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchRequests() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final data = await _supabase
          .from('friendships')
          .select('*, sender:sender_id(username)')
          .eq('receiver_id', userId)
          .eq('status', 'pending');
      pendingRequests.assignAll(List<Map<String, dynamic>>.from(data));
    } catch (e) {
      print("Error fetching requests: $e");
    }
  }

  Future<void> sendRequest(String targetUsername) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // 1. Find user by username
      final target = await _supabase
          .from('profiles')
          .select('id')
          .eq('username', targetUsername)
          .maybeSingle();

      if (target == null) {
        Get.snackbar("Error", "User not found");
        return;
      }

      if (target['id'] == userId) {
        Get.snackbar("Error", "You cannot add yourself");
        return;
      }

      // 2. Insert friendship record
      await _supabase.from('friendships').insert({
        'sender_id': userId,
        'receiver_id': target['id'],
        'status': 'pending',
      });

      Get.snackbar("Success", "Friend request sent!");
    } catch (e) {
      Get.snackbar("Error", "Request already sent or error occurred");
    }
  }

  Future<void> respondToRequest(String requestId, bool accept) async {
    try {
      await _supabase
          .from('friendships')
          .update({'status': accept ? 'accepted' : 'rejected'})
          .eq('id', requestId);

      fetchRequests();
      fetchFriends();
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }
}
