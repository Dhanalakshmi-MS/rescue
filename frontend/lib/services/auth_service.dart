import 'package:shared_preferences/shared_preferences.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String role; // 'admin' or 'user'

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
  });

  bool get isAdmin => role == 'admin';
}

class AuthService {
  static const String _keyUid = 'auth_uid';
  static const String _keyEmail = 'auth_email';
  static const String _keyRole = 'auth_role';
  static const String _keyName = 'auth_name';

  static UserModel? _currentUser;
  static UserModel? get currentUser => _currentUser;

  // Initialize saved session from device cache
  static Future<UserModel?> loadUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(_keyUid);
    final email = prefs.getString(_keyEmail);
    final role = prefs.getString(_keyRole);
    final name = prefs.getString(_keyName);

    if (uid != null && email != null && role != null) {
      _currentUser = UserModel(
        uid: uid,
        email: email,
        displayName: name ?? 'User',
        role: role,
      );
      return _currentUser;
    }
    return null;
  }

  // Sign in with email, password & role
  static Future<UserModel> login({
    required String email,
    required String password,
    String? preferredRole,
  }) async {
    // Demonstration Authentication Logic with Role Detection
    String role = 'user';
    String displayName = 'Building Occupant';

    if (email.toLowerCase().contains('admin') || preferredRole == 'admin') {
      role = 'admin';
      displayName = 'Safety Chief Officer';
    }

    final user = UserModel(
      uid: 'USR_${email.hashCode.abs()}',
      email: email,
      displayName: displayName,
      role: role,
    );

    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUid, user.uid);
    await prefs.setString(_keyEmail, user.email);
    await prefs.setString(_keyRole, user.role);
    await prefs.setString(_keyName, user.displayName);

    return user;
  }

  // Registration
  static Future<UserModel> register({
    required String email,
    required String password,
    required String displayName,
    required String role,
  }) async {
    final user = UserModel(
      uid: 'USR_${email.hashCode.abs()}',
      email: email,
      displayName: displayName,
      role: role,
    );

    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUid, user.uid);
    await prefs.setString(_keyEmail, user.email);
    await prefs.setString(_keyRole, user.role);
    await prefs.setString(_keyName, user.displayName);

    return user;
  }

  // Logout
  static Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
