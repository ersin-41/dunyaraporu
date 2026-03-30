import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/dashboard.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // .env dosyasını yükle
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print(".env yüklenemedi: $e");
  }
  
  // Firebase'i başlat (Web için konfigürasyon firebase_options.dart'tan alınır)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print("Firebase init hatası: $e");
  }
  
  runApp(DunyaRaporuApp());
}

class DunyaRaporuApp extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dünya Raporu - Operasyon Merkezi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Color(0xFFFFD700),
        colorScheme: ColorScheme.dark(
          primary: Color(0xFFFFD700),
          secondary: Color(0xFFFFD700),
          surface: Color(0xFF1E1E1E),
        ),
        useMaterial3: true,
      ),
      // StreamBuilder ile giriş durumunu anlık takip et
      home: StreamBuilder<User?>(
        stream: _authService.user,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            return DashboardScreen(); // Giriş yapılmışsa Dashboard'a git
          }
          return LoginScreen(); // Yapılmamışsa Login ekranını göster
        },
      ),
    );
  }
}
