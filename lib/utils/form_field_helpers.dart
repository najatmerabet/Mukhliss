import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mukhliss/theme/app_theme.dart';

class AppFormFields {
  static Widget buildModernTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool enabled = true,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          enabled: enabled,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: enabled ? Colors.grey.shade900 : Colors.grey.shade600,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: AppColors.purpleDark.withOpacity(0.7),
            ),
            hintText: hintText,
            filled: true,
            fillColor: Colors.white.withOpacity(0.7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            errorStyle: TextStyle(color: Colors.red.shade600, fontSize: 13),
          ),
          validator: validator,
        ),
      ],
    );
  }

  static Widget buildModernPasswordField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required bool isObscure,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: isObscure,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade900,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.lock_outline,
              color: AppColors.purpleDark.withOpacity(0.7),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isObscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.grey.shade600,
              ),
              onPressed: onToggleVisibility,
            ),
            hintText: hintText,
            filled: true,
            fillColor: Colors.white.withOpacity(0.7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            errorStyle: TextStyle(color: Colors.red.shade600, fontSize: 13),
          ),
          validator: validator,
        ),
      ],
    );
  }
}