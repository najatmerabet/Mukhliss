import 'package:flutter/material.dart';
import 'package:mukhliss/routes/app_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
      title: Text(AppLocalizations.of(context)!.hello),),
      body: Center(
         child: ElevatedButton(
        child: const Text('Aller à la page de test'),
        onPressed: () => Navigator.pushNamed(context, AppRouter.profile),
      ),
      ),
      
    );
  }
}