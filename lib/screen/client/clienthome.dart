import 'package:flutter/material.dart';
import 'package:mukhliss/routes/app_router.dart';
 // Assurez-vous d'importer votre router

class ClientHome extends StatefulWidget {
  const ClientHome({Key? key}) : super(key: key);
  
  @override
  _ClientHomeState createState() => _ClientHomeState();
} 

class _ClientHomeState extends State<ClientHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil Client'),
       
      ),
      body: Center(
         child: ElevatedButton(
        child: const Text('Aller à la page de test'),
        onPressed: () => Navigator.pushNamed(context, AppRouter.profile),
      ),
      ),
      
    );
  }
}