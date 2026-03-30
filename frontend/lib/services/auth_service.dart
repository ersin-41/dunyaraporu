import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Giriş Durumu Akışı (Stream)
  Stream<User?> get user {
    return _auth.authStateChanges();
  }

  // Email ve Şifre ile Giriş
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } catch (e) {
      print("Giriş Hatası: ${e.toString()}");
      rethrow;
    }
  }

  // Güvenli Çıkış
  Future<void> signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      print("Çıkış Hatası: ${e.toString()}");
    }
  }
}
