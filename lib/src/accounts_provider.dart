import 'package:appwrite_flutter_accounts/src/models/logs.dart';
import 'package:appwrite_flutter_accounts/src/models/session.dart';
import 'package:appwrite_flutter_accounts/src/models/user.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:appwrite/appwrite.dart';

extension AppwriteAccountProviderExt on BuildContext {
  AuthNotifier? get authNotifier => AppwriteAccountProvider.of(this);
}

/// Exposes Nhost authentication information to its subtree.
class AppwriteAccountProvider extends InheritedNotifier<AuthNotifier> {
  AppwriteAccountProvider({
    Key? key,
    required Client client,
    required Widget child,
  }) : super(
          key: key,
          notifier: AuthNotifier(client),
          child: child,
        );

  @override
  bool updateShouldNotify(InheritedNotifier<AuthNotifier> oldWidget) {
    return oldWidget.notifier != notifier;
  }

  static AuthNotifier? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppwriteAccountProvider>()
        ?.notifier;
  }
}

enum AuthStatus {
  uninitialized,
  authenticated,
  authenticating,
  unauthenticated,
}

/// A [Listenable] that notifies when Nhost authentication states changes
class AuthNotifier extends ChangeNotifier {
  late final Account _account;
  final Client _client;
  AuthStatus _status = AuthStatus.uninitialized;
  User? _user;
  String? _error;
  late bool _loading;

  AuthNotifier(Client client) : this._client = client {
    _error = '';
    _loading = true;
    _account = Account(client);
    _getUser();
  }

  Account get account => _account;
  Client get client => _client;
  String? get error => _error;
  bool get isLoading => _loading;
  User? get user => _user;
  AuthStatus get status => _status;

  Future _getUser() async {
    try {
      final res = await _account.get();
      _user = User.fromMap(res.data);
      _status = AuthStatus.authenticated;
    } on AppwriteException catch (e) {
      _status = AuthStatus.unauthenticated;
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteSession({String sessionId = 'current'}) async {
    try {
      await _account.deleteSession(sessionId: sessionId);
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on AppwriteException catch (e) {
      _error = e.message;
      return false;
    }
  }

  Future<bool> deleteSessions() async {
    try {
      await _account.deleteSessions();
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on AppwriteException catch (e) {
      _error = e.message;
      return false;
    }
  }

  Future<bool> createSession(
      {required String email, required String password}) async {
    _status = AuthStatus.authenticating;
    notifyListeners();
    try {
      await _account.createSession(email: email, password: password);
      _getUser();
      return true;
    } on AppwriteException catch (e) {
      _error = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> createAnonymousSession() async {
    _status = AuthStatus.authenticating;
    notifyListeners();
    try {
      await _account.createAnonymousSession();
      _getUser();
      return true;
    } on AppwriteException catch (e) {
      _error = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<String?> createJWT() async {
    try {
      final res = await _account.createJWT();
      return res.data['jwt'];
    } on AppwriteException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  /// Create account
  ///
  Future<bool> create(
      {required String name,
      required String email,
      required String password}) async {
    _status = AuthStatus.authenticating;
    notifyListeners();
    try {
      await _account.create(name: name, email: email, password: password);
      _error = '';
      await createSession(email: email, password: password);
      return true;
    } on AppwriteException catch (e) {
      _error = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete() async {
    try {
      await _account.delete();
      _getUser();
      return true;
    } on AppwriteException catch (e) {
      _error = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePrefs(Map<String, dynamic> prefs) async {
    try {
      final res = await _account.updatePrefs(prefs: prefs);
      _user = _user?.copyWith(prefs: res.data);
      notifyListeners();
      return true;
    } on AppwriteException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<LogList?> getLogs() async {
    try {
      final res = await _account.getLogs();
      return LogList.fromMap(res.data);
    } on AppwriteException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<bool> createOAuth2Session(String provider) async {
    try {
      await _account.createOAuth2Session(provider: provider);
      _getUser();
      return true;
    } on AppwriteException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<SessionList?> getSessions() async {
    try {
      final res = await _account.getSessions();
      return SessionList.fromMap(res.data);
    } on AppwriteException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateName(String name) async {
    try {
      final res = await _account.updateName(name: name);
      _user = User.fromMap(res.data);
      notifyListeners();
      return true;
    } on AppwriteException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateEmail(
      {required String email, required String password}) async {
    try {
      final res = await _account.updateEmail(email: email, password: password);
      _user = User.fromMap(res.data);
      notifyListeners();
      return true;
    } on AppwriteException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePassword(
      {required String oldPassword, required String password}) async {
    try {
      final res = await _account.updatePassword(
          password: password, oldPassword: oldPassword);
      _user = User.fromMap(res.data);
      notifyListeners();
      return true;
    } on AppwriteException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  //createRecovery
  Future<bool> createRecovery(
      {required String email, required String url}) async {
    try {
      await _account.createRecovery(email: email, url: url);
      return true;
    } on AppwriteException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  //updateRecovery
  Future<bool> updateRecovery(
      {required String userId,
      required String password,
      required String confirmPassword,
      required String secret}) async {
    try {
      await _account.updateRecovery(
          userId: userId,
          password: password,
          passwordAgain: confirmPassword,
          secret: secret);
      return true;
    } on AppwriteException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  //createVerification
  Future<bool> createVerification({required String url}) async {
    try {
      await _account.createVerification(url: url);
      return true;
    } on AppwriteException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  //updateVerification
  Future<bool> updateVerification(
      {required String userId,
      required String password,
      required String confirmPassword,
      required String secret}) async {
    try {
      await _account.updateVerification(userId: userId, secret: secret);
      return true;
    } on AppwriteException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }
}