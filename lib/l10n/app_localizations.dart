import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @currentLanguage.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get currentLanguage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select language'**
  String get selectLanguage;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language changed to English'**
  String get languageChanged;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language'**
  String get languageSubtitle;

  /// No description provided for @languageAlreadySet.
  ///
  /// In en, this message translates to:
  /// **'Language already set to English'**
  String get languageAlreadySet;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @french.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get french;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'Anglais'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabe'**
  String get arabic;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Mukhliss'**
  String get appTitle;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Welcome to MUKHLISS'**
  String get hello;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @membredepuis.
  ///
  /// In en, this message translates to:
  /// **'Member since'**
  String get membredepuis;

  /// No description provided for @informationperso.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get informationperso;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'e-mail'**
  String get email;

  /// No description provided for @identificationTitleqrcode.
  ///
  /// In en, this message translates to:
  /// **'My Identification'**
  String get identificationTitleqrcode;

  /// No description provided for @qrCodeInstructions.
  ///
  /// In en, this message translates to:
  /// **'Show this QR code to benefit from your offer'**
  String get qrCodeInstructions;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get genericError;

  /// No description provided for @errorAuthInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get errorAuthInvalidCredentials;

  /// No description provided for @errorAuthEmailNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your email before logging in'**
  String get errorAuthEmailNotConfirmed;

  /// No description provided for @errorAuthTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later'**
  String get errorAuthTooManyRequests;

  /// No description provided for @errorAuthUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get errorAuthUserNotFound;

  /// No description provided for @errorAuthWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get errorAuthWeakPassword;

  /// No description provided for @errorAuthEmailExists.
  ///
  /// In en, this message translates to:
  /// **'Email already in use'**
  String get errorAuthEmailExists;

  /// No description provided for @errorAuthPhoneExists.
  ///
  /// In en, this message translates to:
  /// **'Phone number already in use'**
  String get errorAuthPhoneExists;

  /// No description provided for @errorAuthUserBanned.
  ///
  /// In en, this message translates to:
  /// **'Account suspended'**
  String get errorAuthUserBanned;

  /// No description provided for @errorAuthUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Unexpected authentication error'**
  String get errorAuthUnexpected;

  /// No description provided for @errorHttp403.
  ///
  /// In en, this message translates to:
  /// **'Access denied'**
  String get errorHttp403;

  /// No description provided for @errorHttp422.
  ///
  /// In en, this message translates to:
  /// **'Unprocessable data'**
  String get errorHttp422;

  /// No description provided for @errorHttp429.
  ///
  /// In en, this message translates to:
  /// **'Too many requests'**
  String get errorHttp429;

  /// No description provided for @errorHttp500.
  ///
  /// In en, this message translates to:
  /// **'Server error'**
  String get errorHttp500;

  /// No description provided for @errorHttp501.
  ///
  /// In en, this message translates to:
  /// **'Feature not implemented'**
  String get errorHttp501;

  /// No description provided for @errorHttpUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown HTTP error'**
  String get errorHttpUnknown;

  /// No description provided for @errorNetworkNoConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get errorNetworkNoConnection;

  /// No description provided for @errorUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error'**
  String get errorUnexpected;

  /// No description provided for @errorAuthSamePassword.
  ///
  /// In en, this message translates to:
  /// **'The new password must be different from the old one'**
  String get errorAuthSamePassword;

  /// No description provided for @successSignup.
  ///
  /// In en, this message translates to:
  /// **'Signup successful!'**
  String get successSignup;

  /// No description provided for @connectezvous.
  ///
  /// In en, this message translates to:
  /// **'Log in to continue'**
  String get connectezvous;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @identificationTitleprofile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get identificationTitleprofile;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgetpassword.
  ///
  /// In en, this message translates to:
  /// **'Forgotten password ?'**
  String get forgetpassword;

  /// No description provided for @connecter.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get connecter;

  /// No description provided for @ou.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get ou;

  /// No description provided for @connecteravecgoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get connecteravecgoogle;

  /// No description provided for @pasdecompte.
  ///
  /// In en, this message translates to:
  /// **'No account yet?'**
  String get pasdecompte;

  /// No description provided for @regoinez.
  ///
  /// In en, this message translates to:
  /// **'Join our community'**
  String get regoinez;

  /// No description provided for @prenom.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get prenom;

  /// No description provided for @nom.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get nom;

  /// No description provided for @adresseemail.
  ///
  /// In en, this message translates to:
  /// **'E-mail address'**
  String get adresseemail;

  /// No description provided for @numphone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get numphone;

  /// No description provided for @adressecomplet.
  ///
  /// In en, this message translates to:
  /// **'Full address'**
  String get adressecomplet;

  /// No description provided for @confirmepassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmepassword;

  /// No description provided for @creecompte.
  ///
  /// In en, this message translates to:
  /// **'Create my account'**
  String get creecompte;

  /// No description provided for @vousavezcompte.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get vousavezcompte;

  /// No description provided for @requis.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requis;

  /// No description provided for @emailinvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get emailinvalid;

  /// No description provided for @invalidphone.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get invalidphone;

  /// No description provided for @entrezemail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get entrezemail;

  /// No description provided for @emailinvalide.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get emailinvalide;

  /// No description provided for @lesmotspassnecorresponspas.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get lesmotspassnecorresponspas;

  /// No description provided for @entrzpassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get entrzpassword;

  /// No description provided for @entrzemail.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least 6 characters'**
  String get entrzemail;

  /// No description provided for @parametre.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get parametre;

  /// No description provided for @compte.
  ///
  /// In en, this message translates to:
  /// **'COMPTE'**
  String get compte;

  /// No description provided for @offre.
  ///
  /// In en, this message translates to:
  /// **'My Offers'**
  String get offre;

  /// No description provided for @localisation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get localisation;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'My Categories'**
  String get categories;

  /// No description provided for @tous.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tous;

  /// No description provided for @tousmagasins.
  ///
  /// In en, this message translates to:
  /// **'Nearest stores'**
  String get tousmagasins;

  /// No description provided for @categoie.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoie;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance:'**
  String get distance;

  /// No description provided for @fermer.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get fermer;

  /// No description provided for @iterinaire.
  ///
  /// In en, this message translates to:
  /// **'Itinerary'**
  String get iterinaire;

  /// No description provided for @glissez.
  ///
  /// In en, this message translates to:
  /// **'Swipe to see more'**
  String get glissez;

  /// No description provided for @mode.
  ///
  /// In en, this message translates to:
  /// **'mode'**
  String get mode;

  /// No description provided for @voiture.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get voiture;

  /// No description provided for @marche.
  ///
  /// In en, this message translates to:
  /// **'Walk'**
  String get marche;

  /// No description provided for @velo.
  ///
  /// In en, this message translates to:
  /// **'Bike'**
  String get velo;

  /// No description provided for @vers.
  ///
  /// In en, this message translates to:
  /// **'Directions to'**
  String get vers;

  /// No description provided for @duree.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duree;

  /// No description provided for @recenter.
  ///
  /// In en, this message translates to:
  /// **'Refocus'**
  String get recenter;

  /// No description provided for @chercher.
  ///
  /// In en, this message translates to:
  /// **'Find a store...'**
  String get chercher;

  /// No description provided for @calcule.
  ///
  /// In en, this message translates to:
  /// **'Calculation...'**
  String get calcule;

  /// No description provided for @connectionRequired.
  ///
  /// In en, this message translates to:
  /// **'You must be logged in to see your points.'**
  String get connectionRequired;

  /// No description provided for @offredisponible.
  ///
  /// In en, this message translates to:
  /// **'Offers available'**
  String get offredisponible;

  /// No description provided for @navigation.
  ///
  /// In en, this message translates to:
  /// **'START NAVIGATION'**
  String get navigation;

  /// No description provided for @detailsiterinaire.
  ///
  /// In en, this message translates to:
  /// **'ROUTE DETAILS'**
  String get detailsiterinaire;

  /// No description provided for @offremagasin.
  ///
  /// In en, this message translates to:
  /// **'OFFER'**
  String get offremagasin;

  /// No description provided for @depensez.
  ///
  /// In en, this message translates to:
  /// **'Spend'**
  String get depensez;

  /// No description provided for @pointsagagner.
  ///
  /// In en, this message translates to:
  /// **'points to win'**
  String get pointsagagner;

  /// No description provided for @nooffre.
  ///
  /// In en, this message translates to:
  /// **'No offers available '**
  String get nooffre;

  /// No description provided for @arrivee.
  ///
  /// In en, this message translates to:
  /// **'You have arrived at'**
  String get arrivee;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'pts'**
  String get points;

  /// No description provided for @disponible.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get disponible;

  /// No description provided for @limite.
  ///
  /// In en, this message translates to:
  /// **'Limit'**
  String get limite;

  /// No description provided for @nouvelleoffre.
  ///
  /// In en, this message translates to:
  /// **'New Offers'**
  String get nouvelleoffre;

  /// No description provided for @offrerecus.
  ///
  /// In en, this message translates to:
  /// **'Offers Received'**
  String get offrerecus;

  /// No description provided for @offreutilise.
  ///
  /// In en, this message translates to:
  /// **'Used Offers'**
  String get offreutilise;

  /// No description provided for @neww.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get neww;

  /// No description provided for @chez.
  ///
  /// In en, this message translates to:
  /// **'in'**
  String get chez;

  /// No description provided for @partirede.
  ///
  /// In en, this message translates to:
  /// **'from'**
  String get partirede;

  /// No description provided for @detailsoffre.
  ///
  /// In en, this message translates to:
  /// **'Offer details'**
  String get detailsoffre;

  /// No description provided for @profitez.
  ///
  /// In en, this message translates to:
  /// **'Take advantage of this opportunity'**
  String get profitez;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Take advantage of this exclusive offer available now!'**
  String get description;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'active'**
  String get active;

  /// No description provided for @aujour.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get aujour;

  /// No description provided for @hier.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get hier;

  /// No description provided for @utilise.
  ///
  /// In en, this message translates to:
  /// **'USED'**
  String get utilise;

  /// No description provided for @beneicier.
  ///
  /// In en, this message translates to:
  /// **'vous avez bénéficié de'**
  String get beneicier;

  /// No description provided for @consomeoffre.
  ///
  /// In en, this message translates to:
  /// **'This offer has already been consumed'**
  String get consomeoffre;

  /// No description provided for @consomme.
  ///
  /// In en, this message translates to:
  /// **'Consumed'**
  String get consomme;

  /// No description provided for @newticket.
  ///
  /// In en, this message translates to:
  /// **'New Ticket'**
  String get newticket;

  /// No description provided for @besoinaide.
  ///
  /// In en, this message translates to:
  /// **'Need help?'**
  String get besoinaide;

  /// No description provided for @probleme.
  ///
  /// In en, this message translates to:
  /// **'Describe your problem and we will help you quickly'**
  String get probleme;

  /// No description provided for @priorite.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priorite;

  /// No description provided for @sujet.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get sujet;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Summary of your problem'**
  String get resume;

  /// No description provided for @champsrequi.
  ///
  /// In en, this message translates to:
  /// **'Required field'**
  String get champsrequi;

  /// No description provided for @descriptiondetaille.
  ///
  /// In en, this message translates to:
  /// **'Description détaillée'**
  String get descriptiondetaille;

  /// No description provided for @poblemedetaille.
  ///
  /// In en, this message translates to:
  /// **'Describe your problem in detail...'**
  String get poblemedetaille;

  /// No description provided for @envoiencours.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get envoiencours;

  /// No description provided for @envoyerticket.
  ///
  /// In en, this message translates to:
  /// **'Submit ticket'**
  String get envoyerticket;

  /// No description provided for @faible.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get faible;

  /// No description provided for @normale.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normale;

  /// No description provided for @urgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgent;

  /// No description provided for @generale.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get generale;

  /// No description provided for @technique.
  ///
  /// In en, this message translates to:
  /// **'Technical'**
  String get technique;

  /// No description provided for @autre.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get autre;

  /// No description provided for @ticketenvoye.
  ///
  /// In en, this message translates to:
  /// **'Ticket envoyé !'**
  String get ticketenvoye;

  /// No description provided for @ticketsucces.
  ///
  /// In en, this message translates to:
  /// **'Your ticket has been successfully created. You will receive a response within 24 hours.'**
  String get ticketsucces;

  /// No description provided for @continuer.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continuer;

  /// No description provided for @eleve.
  ///
  /// In en, this message translates to:
  /// **'high'**
  String get eleve;

  /// No description provided for @apropos.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get apropos;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get version;

  /// No description provided for @content.
  ///
  /// In en, this message translates to:
  /// **'Mukhliss – Your smart and connected loyalty card Mukhliss is the next-generation loyalty mobile app, designed to reward your purchases and help you take advantage of the best offers around you. With Mukhliss, every purchase made in a partner store earns you points, based on the offers proposed by the merchant. Accumulate your points and exchange them for exclusive gifts in your favorite stores. The more loyal you are, the more you are rewarded!'**
  String get content;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Contact & Support'**
  String get support;

  /// No description provided for @contacter.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get contacter;

  /// No description provided for @technologies.
  ///
  /// In en, this message translates to:
  /// **'Technologies'**
  String get technologies;

  /// No description provided for @desc.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get desc;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Informations'**
  String get info;

  /// No description provided for @voir.
  ///
  /// In en, this message translates to:
  /// **'View and edit'**
  String get voir;

  /// No description provided for @gerer.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get gerer;

  /// No description provided for @aide.
  ///
  /// In en, this message translates to:
  /// **'Help and Support'**
  String get aide;

  /// No description provided for @deconection.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get deconection;

  /// No description provided for @mesinformation.
  ///
  /// In en, this message translates to:
  /// **'My Information'**
  String get mesinformation;

  /// No description provided for @modifiermesinformation.
  ///
  /// In en, this message translates to:
  /// **'Edit my informations'**
  String get modifiermesinformation;

  /// No description provided for @sauvgarder.
  ///
  /// In en, this message translates to:
  /// **'save'**
  String get sauvgarder;

  /// No description provided for @application.
  ///
  /// In en, this message translates to:
  /// **'APPLICATION'**
  String get application;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Dark theme'**
  String get theme;

  /// No description provided for @netoyercacha.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get netoyercacha;

  /// No description provided for @desactive.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get desactive;

  /// No description provided for @securite.
  ///
  /// In en, this message translates to:
  /// **'SECURITY & PRIVACY'**
  String get securite;

  /// No description provided for @gestionappariels.
  ///
  /// In en, this message translates to:
  /// **'Device management'**
  String get gestionappariels;

  /// No description provided for @politiques.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get politiques;

  /// No description provided for @cachenettoye.
  ///
  /// In en, this message translates to:
  /// **'Cache nettoyé avec succès'**
  String get cachenettoye;

  /// No description provided for @apparielsconnecte.
  ///
  /// In en, this message translates to:
  /// **'Connected devices'**
  String get apparielsconnecte;

  /// No description provided for @statistiques.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistiques;

  /// No description provided for @inactifs.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactifs;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @mesappariels.
  ///
  /// In en, this message translates to:
  /// **'My Devices'**
  String get mesappariels;

  /// No description provided for @politiqueconfidentialite.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get politiqueconfidentialite;

  /// No description provided for @datemiseajour.
  ///
  /// In en, this message translates to:
  /// **'Last updated: 08/07/2025'**
  String get datemiseajour;

  /// No description provided for @premierstep.
  ///
  /// In en, this message translates to:
  /// **'1. Data collection'**
  String get premierstep;

  /// No description provided for @contentstepone.
  ///
  /// In en, this message translates to:
  /// **'Mukhliss collecte les données suivantes pour fournir le service de carte de fidélité :\n - Informations personnelles (nom, prénom, email, téléphone)\n - Données de localisation (pour trouver les magasins partenaires)\n - Historique des achats et points accumulés\n - Données de paiement (pour les offres premium).'**
  String get contentstepone;

  /// No description provided for @deusiemestep.
  ///
  /// In en, this message translates to:
  /// **'2. Use of data'**
  String get deusiemestep;

  /// No description provided for @contentsteptwo.
  ///
  /// In en, this message translates to:
  /// **' Your data is used to:\n\n  - Manage your account and loyalty card\n -Inform you of personalized offersn -Analyze purchasing trends\n  - Improve our service\n  - Prevent fraud'**
  String get contentsteptwo;

  /// No description provided for @troisemestep.
  ///
  /// In en, this message translates to:
  /// **'3. Sharing data'**
  String get troisemestep;

  /// No description provided for @contentstepthre.
  ///
  /// In en, this message translates to:
  /// **'Your data may be shared with:\n - Partner stores where you use your card\n  -  Payment providers\n  -Nous ne vendons jamais vos données personnelles.'**
  String get contentstepthre;

  /// No description provided for @quatriemestep.
  ///
  /// In en, this message translates to:
  /// **'4. Data security'**
  String get quatriemestep;

  /// No description provided for @contentstepfor.
  ///
  /// In en, this message translates to:
  /// **'We protect your data with: :\n -AES-256 encryption\n-Two-factor authentication\n - Regular security audits\n - GDPR-compliant secure storage'**
  String get contentstepfor;

  /// No description provided for @cinquemestep.
  ///
  /// In en, this message translates to:
  /// **'5. Your rights'**
  String get cinquemestep;

  /// No description provided for @contentstepfive.
  ///
  /// In en, this message translates to:
  /// **'You have the right to:\n - Access your data\n- Request its correction\n  - Delete your account\n - Export your data\n - Object to its processing\n -Contact us at  mukhlissfidelite@gmail.com  for any requests.'**
  String get contentstepfive;

  /// No description provided for @compris.
  ///
  /// In en, this message translates to:
  /// **'Understood'**
  String get compris;

  /// No description provided for @deconnextion.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get deconnextion;

  /// No description provided for @etresur.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get etresur;

  /// No description provided for @exclusifs.
  ///
  /// In en, this message translates to:
  /// **'EXCLUSIVE'**
  String get exclusifs;

  /// No description provided for @pointsrequis.
  ///
  /// In en, this message translates to:
  /// **'REQUIRED POINTS'**
  String get pointsrequis;

  /// No description provided for @benificier.
  ///
  /// In en, this message translates to:
  /// **'To benefit'**
  String get benificier;

  /// No description provided for @ofline.
  ///
  /// In en, this message translates to:
  /// **'Offline mode'**
  String get ofline;

  /// No description provided for @noloadqrcode.
  ///
  /// In en, this message translates to:
  /// **'Could not load QR code'**
  String get noloadqrcode;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @pasconnexioninternet.
  ///
  /// In en, this message translates to:
  /// **'No Internet connection'**
  String get pasconnexioninternet;

  /// No description provided for @veuillezvzrifier.
  ///
  /// In en, this message translates to:
  /// **'Please check your connection and try again.'**
  String get veuillezvzrifier;

  /// No description provided for @aucunoffre.
  ///
  /// In en, this message translates to:
  /// **'No offer used'**
  String get aucunoffre;

  /// No description provided for @aucunoffreutilise.
  ///
  /// In en, this message translates to:
  /// **'No rewards recently available'**
  String get aucunoffreutilise;

  /// No description provided for @langagechangedsuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Language changed successfully'**
  String get langagechangedsuccessfully;

  /// No description provided for @uneconnexionnecessaire.
  ///
  /// In en, this message translates to:
  /// **'Login is required to load map and stores'**
  String get uneconnexionnecessaire;

  /// No description provided for @connexionrequise.
  ///
  /// In en, this message translates to:
  /// **'Connection required'**
  String get connexionrequise;

  /// No description provided for @connecterinternet.
  ///
  /// In en, this message translates to:
  /// **'To access device management, you must be connected to the internet.'**
  String get connecterinternet;

  /// No description provided for @verifier.
  ///
  /// In en, this message translates to:
  /// **'Please check:'**
  String get verifier;

  /// No description provided for @wifi.
  ///
  /// In en, this message translates to:
  /// **'• Your Wi-Fi connection\n•Your mobile data\n• Your network signalt'**
  String get wifi;

  /// No description provided for @vereficationconnexion.
  ///
  /// In en, this message translates to:
  /// **'Checking the connection...'**
  String get vereficationconnexion;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
