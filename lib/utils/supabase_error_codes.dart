// lib/utils/supabase_error_codes.dart

/// Central definitions for Supabase Auth error and status codes.
class SupabaseErrorCodes {
  // HTTP Status Codes
  static const int FORBIDDEN = 403;
  static const int UNPROCESSABLE_ENTITY = 422;
  static const int TOO_MANY_REQUESTS = 429;
  static const int INTERNAL_SERVER_ERROR = 500;
  static const int NOT_IMPLEMENTED = 501;

  // Auth Error Codes (complete list as of May 2025)
  static const String ANONYMOUS_PROVIDER_DISABLED      = 'anonymous_provider_disabled';
  static const String BAD_CODE_VERIFIER                = 'bad_code_verifier';
  static const String BAD_JSON                         = 'bad_json';
  static const String BAD_JWT                          = 'bad_jwt';
  static const String BAD_OAUTH_CALLBACK               = 'bad_oauth_callback';
  static const String BAD_OAUTH_STATE                  = 'bad_oauth_state';
  static const String CAPTCHA_FAILED                   = 'captcha_failed';
  static const String CONFLICT                         = 'conflict';
  static const String EMAIL_ADDRESS_INVALID            = 'email_address_invalid';
  static const String EMAIL_ADDRESS_NOT_AUTHORIZED     = 'email_address_not_authorized';
  static const String EMAIL_CONFLICT_IDENTITY_NOT_DELETABLE = 'email_conflict_identity_not_deletable';
  static const String EMAIL_EXISTS                     = 'email_exists';
  static const String EMAIL_NOT_CONFIRMED              = 'email_not_confirmed';
  static const String EMAIL_PROVIDER_DISABLED          = 'email_provider_disabled';
  static const String FLOW_STATE_EXPIRED               = 'flow_state_expired';
  static const String FLOW_STATE_NOT_FOUND             = 'flow_state_not_found';
  static const String HOOK_PAYLOAD_INVALID_CONTENT_TYPE= 'hook_payload_invalid_content_type';
  static const String HOOK_PAYLOAD_OVER_SIZE_LIMIT     = 'hook_payload_over_size_limit';
  static const String HOOK_TIMEOUT                     = 'hook_timeout';
  static const String HOOK_TIMEOUT_AFTER_RETRY         = 'hook_timeout_after_retry';
  static const String IDENTITY_ALREADY_EXISTS          = 'identity_already_exists';
  static const String IDENTITY_NOT_FOUND               = 'identity_not_found';
  static const String INSUFFICIENT_AAL                 = 'insufficient_aal';
  static const String INVALID_CREDENTIALS              = 'invalid_credentials';
  static const String INVITE_NOT_FOUND                 = 'invite_not_found';
  static const String MANUAL_LINKING_DISABLED          = 'manual_linking_disabled';
  static const String MFA_CHALLENGE_EXPIRED            = 'mfa_challenge_expired';
  static const String MFA_FACTOR_NAME_CONFLICT         = 'mfa_factor_name_conflict';
  static const String MFA_FACTOR_NOT_FOUND             = 'mfa_factor_not_found';
  static const String MFA_IP_ADDRESS_MISMATCH          = 'mfa_ip_address_mismatch';
  static const String MFA_PHONE_ENROLL_NOT_ENABLED     = 'mfa_phone_enroll_not_enabled';
  static const String MFA_PHONE_VERIFY_NOT_ENABLED     = 'mfa_phone_verify_not_enabled';
  static const String MFA_TOTP_ENROLL_NOT_ENABLED      = 'mfa_totp_enroll_not_enabled';
  static const String MFA_TOTP_VERIFY_NOT_ENABLED      = 'mfa_totp_verify_not_enabled';
  static const String MFA_VERIFICATION_FAILED          = 'mfa_verification_failed';
  static const String MFA_VERIFICATION_REJECTED        = 'mfa_verification_rejected';
  static const String MFA_VERIFIED_FACTOR_EXISTS       = 'mfa_verified_factor_exists';
  static const String MFA_WEB_AUTHN_ENROLL_NOT_ENABLED= 'mfa_web_authn_enroll_not_enabled';
  static const String MFA_WEB_AUTHN_VERIFY_NOT_ENABLED= 'mfa_web_authn_verify_not_enabled';
  static const String NO_AUTHORIZATION                 = 'no_authorization';
  static const String NOT_ADMIN                        = 'not_admin';
  static const String OAUTH_PROVIDER_NOT_SUPPORTED     = 'oauth_provider_not_supported';
  static const String OTP_DISABLED                     = 'otp_disabled';
  static const String OTP_EXPIRED                      = 'otp_expired';
  static const String OVER_EMAIL_SEND_RATE_LIMIT       = 'over_email_send_rate_limit';
  static const String OVER_REQUEST_RATE_LIMIT          = 'over_request_rate_limit';
  static const String OVER_SMS_SEND_RATE_LIMIT         = 'over_sms_send_rate_limit';
  static const String PHONE_EXISTS                     = 'phone_exists';
  static const String PHONE_NOT_CONFIRMED              = 'phone_not_confirmed';
  static const String PHONE_PROVIDER_DISABLED          = 'phone_provider_disabled';
  static const String PROVIDER_DISABLED                = 'provider_disabled';
  static const String PROVIDER_EMAIL_NEEDS_VERIFICATION= 'provider_email_needs_verification';
  static const String REAUTHENTICATION_NEEDED          = 'reauthentication_needed';
  static const String REAUTHENTICATION_NOT_VALID       = 'reauthentication_not_valid';
  static const String REFRESH_TOKEN_ALREADY_USED       = 'refresh_token_already_used';
  static const String REFRESH_TOKEN_NOT_FOUND          = 'refresh_token_not_found';
  static const String REQUEST_TIMEOUT                  = 'request_timeout';
  static const String SAME_PASSWORD                    = 'same_password';
  static const String SAML_ASSERTION_NO_EMAIL          = 'saml_assertion_no_email';
  static const String SAML_ASSERTION_NO_USER_ID        = 'saml_assertion_no_user_id';
  static const String SAML_ENTITY_ID_MISMATCH          = 'saml_entity_id_mismatch';
  static const String SAML_IDP_ALREADY_EXISTS          = 'saml_idp_already_exists';
  static const String SAML_IDP_NOT_FOUND                = 'saml_idp_not_found';
  static const String SAML_METADATA_FETCH_FAILED       = 'saml_metadata_fetch_failed';
  static const String SAML_PROVIDER_DISABLED           = 'saml_provider_disabled';
  static const String SAML_RELAY_STATE_EXPIRED         = 'saml_relay_state_expired';
  static const String SAML_RELAY_STATE_NOT_FOUND       = 'saml_relay_state_not_found';
  static const String SESSION_EXPIRED                  = 'session_expired';
  static const String SESSION_NOT_FOUND                = 'session_not_found';
  static const String SIGNUP_DISABLED                  = 'signup_disabled';
  static const String SINGLE_IDENTITY_NOT_DELETABLE    = 'single_identity_not_deletable';
  static const String SMS_SEND_FAILED                  = 'sms_send_failed';
  static const String SSO_DOMAIN_ALREADY_EXISTS        = 'sso_domain_already_exists';
  static const String SSO_PROVIDER_NOT_FOUND           = 'sso_provider_not_found';
  static const String TOO_MANY_ENROLLED_MFA_FACTORS    = 'too_many_enrolled_mfa_factors';
  static const String UNEXPECTED_AUDIENCE              = 'unexpected_audience';
  static const String UNEXPECTED_FAILURE               = 'unexpected_failure';
  static const String USER_ALREADY_EXISTS              = 'user_already_exists';
  static const String USER_BANNED                      = 'user_banned';
  static const String USER_NOT_FOUND                   = 'user_not_found';
  static const String USER_SSO_MANAGED                 = 'user_sso_managed';
  static const String VALIDATION_FAILED                = 'validation_failed';
  static const String WEAK_PASSWORD                    = 'weak_password';
}

/// Extension to map HTTP status codes to translation keys.
extension HttpStatusKey on int {
  String get i18nKey {
    switch (this) {
      case SupabaseErrorCodes.FORBIDDEN:
        return 'errors.http.403';
      case SupabaseErrorCodes.UNPROCESSABLE_ENTITY:
        return 'errors.http.422';
      case SupabaseErrorCodes.TOO_MANY_REQUESTS:
        return 'errors.http.429';
      case SupabaseErrorCodes.INTERNAL_SERVER_ERROR:
        return 'errors.http.500';
      case SupabaseErrorCodes.NOT_IMPLEMENTED:
        return 'errors.http.501';
      default:
        return 'errors.http.unknown';
    }
  }
}

/// Extension to map Auth error codes to translation keys.
extension AuthErrorKey on String {
  String get i18nKey => 'errors.auth.$this';
}
