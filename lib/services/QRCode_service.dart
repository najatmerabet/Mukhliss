import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';


class QrcodeService {
  final SupabaseClient client=Supabase.instance.client;


  //recuperer les donnes des cleint 
  Future<Map<String,dynamic>> _getClientData() async{
    final user= client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    final response = await client
        .from('clients')
        .select()
        .eq('id', user.id)
        .single();

        return response;
  }

  // cree un QR code pour le cleint  
  String _geteQrCodeData(Map<String, dynamic> clientData) {
   final secureData = {
      'user_id': clientData['id'],
      'nom': clientData['nom'] ,
      'prenom': clientData['prenom'],
      'email': clientData['email'],
      'address': clientData['adr'],
      'phone': clientData['tel'],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    return jsonEncode(secureData);
  }
  
   Future<Widget> generateUserQR() async {
    final userData = await _getClientData();
    final qrData = _geteQrCodeData(userData);

    return QrImageView(
      data: qrData,
      version: QrVersions.auto,
      size: 250.0,
      backgroundColor: Colors.white,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Colors.blue,
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Colors.black,
      ),
    );
  }

  Future<String> getQRDataString() async {
    final userData = await _getClientData();
    return _geteQrCodeData(userData);
  }

}