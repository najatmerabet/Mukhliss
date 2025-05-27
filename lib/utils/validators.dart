// utils/validators.dart
class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Veuillez entrer un email valide';
    }
    return null;
  }

   static String? validateRequired(String? value, [String? fieldName]) {
    if (value?.isEmpty ?? true) return fieldName != null ? '$fieldName est requis' : 'Requis';
    return null;
  }

    static String? validateConfirmPassword(String? value, String? password) {
    if (value != password) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value?.isEmpty ?? true) return 'Requis';
    if (value!.length < 10) return 'Numéro invalide';
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre mot de passe';
    }
    if (value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    return null;
  }
 //validators login page 
 static String? validateEmaillogin(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un email';
    }
    if (!value.contains('@')) {
      return 'Email invalide';
    }
    return null;
  }






}