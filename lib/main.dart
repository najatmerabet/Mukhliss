import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/routes/app_router.dart';
import 'package:mukhliss/screen/slash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ajoutez cette ligne
 
  try {
    await dotenv.load(fileName: '.env'); // Charge le fichier .env
    
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_KEY']!,
    );
    
    runApp(ProviderScope(
      child: MyApp(),
    ),);
  } catch (e) {
    print('Erreur d\'initialisation: $e');
    // Gestion d'erreur alternative
    runApp(const ErrorApp());
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
    
      home: Scaffold(
        body: Center(
          child: Text(
            'Erreur d\'initialisation',
            style: TextStyle(fontSize: 24, color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MUKHLISS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
           debugShowCheckedModeBanner: false,
      home: const SplashScreen(), // Utilisez le widget de votre choix ici
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}

