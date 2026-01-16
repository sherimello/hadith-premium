import 'package:get/get.dart';
import '../services/db_service.dart';

class DataController extends GetxController {
  final DbService _dbService = DbService();

  var isLoading = true.obs;
  var statusMessage = "Initializing...".obs;
  var progress =
      0.0.obs; // Kept for compatibility if UI binds to it, though unused.

  @override
  void onInit() {
    super.onInit();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    statusMessage.value = "Setting up database...";
    try {
      await _dbService.initDb();
      statusMessage.value = "Ready";
      isLoading.value = false;
    } catch (e) {
      statusMessage.value = "Error: $e";
      print("DB Init Error: $e");
    }
  }
}
