import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sprint/firebase_options.dart';
import 'package:sprint/login_or_register/login_page.dart';
import 'package:sprint/login_or_register/register_page.dart';
import 'package:sprint/principal.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Aguarda o Firebase carregar o estado de autenticação persistido
  User? usuarioAtual = await FirebaseAuth.instance.authStateChanges().first;

  // Define a rota inicial com base no login persistido
  String initialRoute;
  if (usuarioAtual != null) {
    initialRoute = '/principal';
  } else {
    initialRoute = '/login';
  }

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Auth Demo',
      theme: ThemeData.dark(),
      // Define a rota inicial dinamicamente (login ou home)
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/principal': (context) => const Principal(),
      },
      // Podemos definir a tela de login como rota padrão para qualquer rota desconhecida:
      onUnknownRoute: (settings) =>
          MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }
}
