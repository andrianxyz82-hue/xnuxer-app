import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

class AuthService {
  final SupabaseClient _client = SupabaseService.instance.client;

  // Get current user
  User? get currentUser => _client.auth.currentUser;

  // Auth state stream
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // Sign in with email
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    try {
      return await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Sign up with email
  Future<AuthResponse> signUpWithEmail(String email, String password,
      {Map<String, dynamic>? userData}) async {
    try {
      return await _client.auth.signUp(
        email: email,
        password: password,
        data: userData,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  // Update last login time
  Future<void> updateLastLogin() async {
    final user = currentUser;
    if (user != null) {
      try {
        await _client.from('user_profiles').update(
            {'last_login': DateTime.now().toIso8601String()}).eq('id', user.id);
      } catch (e) {
        // Continue silently if update fails
        print('Failed to update last login: $e');
      }
    }
  }
}
