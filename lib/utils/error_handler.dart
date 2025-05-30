// lib/utils/auth_error_handler.dart

import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mukhliss/utils/supabase_error_codes.dart';
import 'package:postgrest/postgrest.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_localizations_ext.dart';

class AuthErrorHandler {
  final BuildContext context;

  const AuthErrorHandler(this.context);

  /// Returns a localized message based on the type of [error].
  String handle(Object error) {
    if (error is AuthException) {
      return _handleAuthError(error);
    }

    if (error is PostgrestException) {
      return _handlePostgrestError(error);
    }

    if (error is SocketException) {
      return context.l10n.address;
    }

    if (error is TimeoutException) {
      return context.l10n.address;
    }

    return context.l10n.address;
  }

  String _handleAuthError(AuthException e) {
    // use the Supabase error code, e.g. 'invalid_credentials'
    final code = e.code ?? '';
    final map = <String, String>{
      SupabaseErrorCodes.INVALID_CREDENTIALS:   context.l10n.address,
      SupabaseErrorCodes.EMAIL_NOT_CONFIRMED:   context.l10n.address,
      SupabaseErrorCodes.USER_NOT_FOUND:        context.l10n.address,
      SupabaseErrorCodes.WEAK_PASSWORD:         context.l10n.address,
      SupabaseErrorCodes.EMAIL_EXISTS:          context.l10n.address,
      SupabaseErrorCodes.PHONE_EXISTS:          context.l10n.address,
      SupabaseErrorCodes.USER_BANNED:           context.l10n.address,
      SupabaseErrorCodes.SAME_PASSWORD:           context.l10n.address,
      // …add any other codes you care about…
    };
    return map[code] ?? context.l10n.address;
  }

  String _handlePostgrestError(PostgrestException e) {
    // PostgrestException.code holds HTTP status in v1, PostgREST code in v2
    final status = int.tryParse(e.code ?? '');
    final map = <int, String>{
      SupabaseErrorCodes.FORBIDDEN:                context.l10n.address,
      SupabaseErrorCodes.UNPROCESSABLE_ENTITY:     context.l10n.address,
      SupabaseErrorCodes.TOO_MANY_REQUESTS:        context.l10n.address,
      SupabaseErrorCodes.INTERNAL_SERVER_ERROR:    context.l10n.address,
      SupabaseErrorCodes.NOT_IMPLEMENTED:          context.l10n.address,
    };
    return status != null
      ? (map[status] ?? context.l10n.address)
      : context.l10n.address;
  }
}
