// utils/validators.dart

import 'package:flutter/material.dart';
import 'package:mukhliss/l10n/app_localizations.dart';

class Validators {
  static String? validateEmail(String? value, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.isEmpty) {
      return l10n?.entrezemail ?? 'Veuillez entrer votre email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return l10n?.emailinvalide ?? 'Veuillez entrer un email valide';
    }
    return null;
  }

  static String? validateRequired(String? value, BuildContext context, [String? fieldName]) {
    final l10n = AppLocalizations.of(context);
    if (value?.isEmpty ?? true) {
      return fieldName != null 
          ? '$fieldName ${l10n?.requis.toLowerCase() ?? 'est requis'}' 
          : l10n?.requis ?? 'Requis';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String? password, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (value != password) {
      return l10n?.lesmotspassnecorresponspas ?? 'Les mots de passe ne correspondent pas'; // Vous pourriez ajouter cette traduction aussi
    }
    return null;
  }

  static String? validatePhone(String? value, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (value?.isEmpty ?? true) return l10n?.requis ?? 'Requis';
    if (value!.length < 10) return l10n?.invalidphone ?? 'Numéro invalide';
    return null;
  }

  static String? validatePassword(String? value, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.isEmpty) {
      return l10n?.entrzpassword ?? 'Veuillez entrer votre mot de passe';
    }
    if (value.length < 6) {
      return l10n?.entrzemail??'Le mot de passe doit contenir au moins 6 caractères'; // Vous pourriez ajouter cette traduction aussi
    }
    return null;
  }

  static String? validateEmaillogin(String? value, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.isEmpty) {
      return l10n?.entrezemail ?? 'Veuillez entrer un email';
    }
    if (!value.contains('@')) {
      return l10n?.emailinvalid ?? 'Email invalide';
    }
    return null;
  }
}