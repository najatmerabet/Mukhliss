import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QrcodeService {
  final SupabaseClient client=Supabase.instance.client;
  static const String _qrCacheKey = 'cached_qr_data';

  //recuperer les donnes des cleint 
  Future<Map<String, dynamic>> _getClientData() async {
    try {
      // First try to get from Supabase
      final user = client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      final response = await client
          .from('clients')
          .select()
          .eq('id', user.id)
          .single();
      
      // Cache the data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_qrCacheKey, jsonEncode(response));
      
      return response;
    } catch (e) {
      // If online fetch fails, try to get cached data
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_qrCacheKey);
      
      if (cachedData != null) {
        return jsonDecode(cachedData);
      }
      throw Exception('No cached data available');
    }
  }

  // cree un QR code pour le cleint  
  String _getQrCodeData(Map<String, dynamic> clientData) {
    final secureData = {
      'user_id': clientData['id'],
      'nom': clientData['nom'],
      'prenom': clientData['prenom'],
      'email': clientData['email'],
      'address': clientData['adr'],
      'phone': clientData['tel'],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    return jsonEncode(secureData);
  }
  
 Future<Widget> generateUserQR() async {
    try {
      final userData = await _getClientData();
      final qrData = _getQrCodeData(userData);

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
    } catch (e) {
      // Return an error widget if both online and cached data fail
      return Center(
        child: Text('Could not load QR code: ${e.toString()}'),
      );
    }
  }

  Future<String> getQRDataString() async {
    final userData = await _getClientData();
    return _getQrCodeData(userData);
  }

}