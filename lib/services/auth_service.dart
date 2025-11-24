import '../models/user_model.dart';
import 'db_helper.dart';

class AuthService {
  static User? _currentUser;

  static User? get currentUser => _currentUser;

  /// Login using SQLite-backed users table. Accepts username OR nip OR npm plus password.
  static Future<User?> login(String id, String password) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final row = await DBHelper.instance.getUserByCredential(id, password);
    if (row == null) return null;
    _currentUser = User(
      username: row['username'] as String,
      password: row['password'] as String,
      role: row['role'] as String,
      name: row['name'] as String,
      nip: row['nip'] as String?,
      npm: row['npm'] as String?,
    );
    return _currentUser;
  }

  static void logout() {
    _currentUser = null;
  }
}
