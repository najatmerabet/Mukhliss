
import 'package:flutter/foundation.dart';

@immutable
class  Client{
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String adr;
  final String tel;
  final String password;
  final String updatedAt;

const  Client({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.adr,
    required this.tel,
    required this.password,
    required this.updatedAt,
  });


  
  
} 