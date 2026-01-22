import 'package:get/get.dart';
import 'dart:async';
import '../services/db_service.dart';

class HadithSearchController extends GetxController {
  final DbService _dbService = DbService();

  final RxString searchQuery = "".obs;
  final RxList<Map<String, dynamic>> searchResults =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isMoreLoading = false.obs;
  final RxBool hasMore = true.obs;
  int _offset = 0;
  final int _limit = 100;

  Timer? _debounce;

  void onSearchChanged(String query) {
    searchQuery.value = query;
    _offset = 0;
    hasMore.value = true;

    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        performSearch(query);
      } else {
        searchResults.clear();
      }
    });
  }

  Future<void> performSearch(String query) async {
    isLoading.value = true;
    _offset = 0;
    hasMore.value = true;
    try {
      final results = await _dbService.searchHadiths(
        query,
        limit: _limit,
        offset: _offset,
      );
      searchResults.assignAll(results);
      if (results.length < _limit) {
        hasMore.value = false;
      }
      _offset += results.length;
    } catch (e) {
      print("Search error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isMoreLoading.value || !hasMore.value || searchQuery.value.isEmpty)
      return;

    isMoreLoading.value = true;
    try {
      final results = await _dbService.searchHadiths(
        searchQuery.value,
        limit: _limit,
        offset: _offset,
      );
      if (results.isEmpty) {
        hasMore.value = false;
      } else {
        searchResults.addAll(results);
        _offset += results.length;
        if (results.length < _limit) {
          hasMore.value = false;
        }
      }
    } catch (e) {
      print("Load more error: $e");
    } finally {
      isMoreLoading.value = false;
    }
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
