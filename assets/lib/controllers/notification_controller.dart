import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;

  final RxList<Map<String, dynamic>> receivedShares =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxInt unreadCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    // Fetch initial shares if user is logged in
    if (_supabase.auth.currentUser != null) {
      fetchShares();
    }
  }

  Future<void> fetchShares() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    isLoading.value = true;
    try {
      final data = await _supabase
          .from('shared_hadiths')
          .select('*, sender:sender_id(username)')
          .eq('receiver_id', userId)
          .order('created_at', ascending: false);

      receivedShares.assignAll(List<Map<String, dynamic>>.from(data));
      _updateUnreadCount();
    } catch (e) {
      print("Error fetching shares: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void _updateUnreadCount() {
    unreadCount.value = receivedShares
        .where((s) => s['read_status'] == false)
        .length;
  }

  Future<void> markAsRead(String shareId) async {
    try {
      await _supabase
          .from('shared_hadiths')
          .update({'read_status': true})
          .eq('id', shareId);

      final index = receivedShares.indexWhere((s) => s['id'] == shareId);
      if (index != -1) {
        receivedShares[index]['read_status'] = true;
        receivedShares.refresh();
        _updateUnreadCount();
      }
    } catch (e) {
      print("Error marking as read: $e");
    }
  }

  Future<void> shareWithFriends({
    required List<String> receiverIds,
    required String collectionId,
    required int bookId,
    required String bookName,
    required int hadithNumber,
    String? chapterName,
    String? textEn,
    String? textAr,
    String? annotation,
    String? comment,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final shares = receiverIds
          .map(
            (rid) => {
              'sender_id': userId,
              'receiver_id': rid,
              'collection_id': collectionId,
              'book_id': bookId,
              'book_name': bookName,
              'hadith_number': hadithNumber,
              'chapter_name': chapterName,
              'text_en': textEn,
              'text_ar': textAr,
              'annotation': annotation,
              'comment': comment,
            },
          )
          .toList();

      await _supabase.from('shared_hadiths').insert(shares);
      Get.snackbar("Success", "Hadith shared with friends!");
    } catch (e) {
      Get.snackbar("Error", "Could not share: $e");
    }
  }
}
