// import 'package:get/get.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
//
// class AuthController extends GetxController {
//   final SupabaseClient _supabase = Supabase.instance.client;
//
//   final Rx<User?> user = Rx<User?>(null);
//   final RxMap<String, dynamic> profile = <String, dynamic>{}.obs;
//   final RxBool isLoading = false.obs;
//
//   @override
//   void onInit() {
//     super.onInit();
//     user.value = _supabase.auth.currentUser;
//     _supabase.auth.onAuthStateChange.listen((data) {
//       final sessionUser = data.session?.user;
//       user.value = sessionUser;
//       if (sessionUser != null) {
//         fetchProfile();
//       } else {
//         profile.clear();
//       }
//     });
//
//     if (user.value != null) {
//       fetchProfile();
//     }
//   }
//
//   Future<void> fetchProfile() async {
//     if (user.value == null) return;
//     try {
//       final data = await _supabase
//           .from('profiles')
//           .select()
//           .eq('id', user.value!.id)
//           .single();
//       profile.assignAll(data);
//     } catch (e) {
//       print("Error fetching profile: $e");
//     }
//   }
//
//   Future<void> signUp({
//     required String email,
//     required String password,
//     required String fullName,
//   }) async {
//     isLoading.value = true;
//     try {
//       // 1. Sign up with metadata - the SQL trigger handles profile creation
//       final response = await _supabase.auth.signUp(
//         email: email,
//         password: password,
//         data: {'full_name': fullName},
//       );
//
//       if (response.user != null) {
//         Get.snackbar(
//           "Success",
//           "Account created! Please check your email to confirm your account.",
//         );
//       }
//     } catch (e) {
//       Get.snackbar("Error", e.toString());
//     } finally {
//       isLoading.value = false;
//     }
//   }
//
//   Future<void> signIn(String email, String password) async {
//     isLoading.value = true;
//     try {
//       await _supabase.auth.signInWithPassword(email: email, password: password);
//     } catch (e) {
//       Get.snackbar("Error", "Invalid email or password");
//     } finally {
//       isLoading.value = false;
//     }
//   }
//
//   Future<void> sendPasswordReset(String email) async {
//     isLoading.value = true;
//     try {
//       await _supabase.auth.resetPasswordForEmail(email);
//       Get.snackbar("Success", "Password reset link sent to your email.");
//     } catch (e) {
//       Get.snackbar("Error", e.toString());
//     } finally {
//       isLoading.value = false;
//     }
//   }
//
//   Future<void> signOut() async {
//     await _supabase.auth.signOut();
//   }
//
//   bool get isAuthenticated => user.value != null;
// }

import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../ui/auth_screen.dart';
import '../ui/home_screen.dart';

class AuthController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;

  final Rx<User?> user = Rx<User?>(null);
  final RxMap<String, dynamic> profile = <String, dynamic>{}.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    user.value = _supabase.auth.currentUser;

    // Listen to Auth State Changes (Supabase internal)
    _supabase.auth.onAuthStateChange.listen((data) {
      final sessionUser = data.session?.user;
      user.value = sessionUser;

      if (sessionUser != null) {
        fetchProfile();
      } else {
        profile.clear();
      }
    });

    // WORKER: Automatically navigate based on Auth State
    // This runs every time 'user' changes.
    ever(user, (User? latestUser) {
      if (latestUser != null) {
        // If user exists, redirect to Home
        Get.offAll(() => const HomeScreen());
      } else {
        // If user is null (signed out), redirect to Auth
        Get.offAll(() => const AuthScreen());
      }
    });

    if (user.value != null) {
      _loadCachedProfile();
      fetchProfile();
    }
  }

  static const String _profileKey = 'cached_profile';

  Future<void> _loadCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_profileKey);
    if (cached != null) {
      try {
        profile.assignAll(jsonDecode(cached));
      } catch (e) {
        print("Error decoding cached profile: $e");
      }
    }
  }

  Future<void> fetchProfile() async {
    if (user.value == null) return;
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.value!.id)
          .single();
      profile.assignAll(data);

      // Cache profile
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileKey, jsonEncode(data));
    } catch (e) {
      print("Error fetching profile: $e");
    }
  }

  /// Returns true if OTP sent successfully
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    isLoading.value = true;
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      // If user is created but assuming email confirmation is required,
      // we return true to show the OTP dialog.
      if (response.user != null) {
        Get.snackbar(
          "Verification Required",
          "An OTP has been sent to your email. Please verify.",
        );
        return true;
      }
      return false;
    } catch (e) {
      Get.snackbar("Error", e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Verifies the OTP token for either Signup or Recovery
  Future<bool> verifyOtp({
    required String email,
    required String token,
    required OtpType type,
  }) async {
    isLoading.value = true;
    try {
      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: type,
      );
      if (response.session != null) {
        Get.snackbar("Success", "Verified successfully!");
        return true;
      }
      return false;
    } catch (e) {
      Get.snackbar("Error", "Invalid Token: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Updates password after recovery (User must be logged in via verifyOTP first)
  Future<bool> updatePassword(String newPassword) async {
    isLoading.value = true;
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      Get.snackbar("Success", "Password updated successfully!");
      return true;
    } catch (e) {
      Get.snackbar("Error", "Failed to update password: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // --- EXISTING METHODS ---

  /// Returns true if login successful
  Future<bool> signIn(String email, String password) async {
    isLoading.value = true;
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
      return true;
    } catch (e) {
      Get.snackbar("Error", "Invalid email or password");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    isLoading.value = true;
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      Get.snackbar("Success", "OTP sent to your email.");
      return true;
    } catch (e) {
      Get.snackbar("Error", e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    // The 'ever' worker will automatically trigger navigation to AuthScreen
  }

  bool get isAuthenticated => user.value != null;
}
