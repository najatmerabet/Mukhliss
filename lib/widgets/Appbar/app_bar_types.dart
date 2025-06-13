// lib/widgets/common/app_bar_types.dart
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mukhliss/widgets/Appbar/custom_sliver_app_bar.dart';

class AppBarTypes {
  // AppBar pour les offres
  static CustomSliverAppBar offersAppBar(BuildContext context, {List<Widget>? actions}) {
    final l10n = AppLocalizations.of(context);
    return CustomSliverAppBar(
      title:l10n?.address  ?? 'Mes Offres',
      actions: actions,
    );
  }

  // AppBar pour l'identification/QR Code
  static CustomSliverAppBar identificationAppBar(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CustomSliverAppBar(
      title: l10n?.identificationTitleqrcode ?? 'Mon Identification',

    );
  }

  static CustomSliverAppBar ParametreAppBar(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CustomSliverAppBar(
      title: l10n?.parametre ?? 'Paramètres',
      useFlexibleSpace: true,
        showDefaultLeading: true, //
    );
  }


  // AppBar pour les magasins
  static CustomSliverAppBar localisationAppBar(BuildContext context, {List<Widget>? actions}) {
    final l10n = AppLocalizations.of(context);
    return CustomSliverAppBar(
      title: l10n?.address ?? 'Localisation',
      actions: actions,
    );
  }

  // AppBar pour le profil
  static CustomSliverAppBar profileAppBar(BuildContext context, {List<Widget>? actions}) {
    final l10n = AppLocalizations.of(context);
    return CustomSliverAppBar(
      title: l10n?.identificationTitleprofile ?? 'Mon Profil',
      actions: actions,
    );
  }

  // AppBar générique avec titre personnalisé
  static CustomSliverAppBar customAppBar(
    String title, {
    double? expandedHeight,
    List<Widget>? actions,
    bool automaticallyImplyLeading = false,
    Widget? leading,
  }) {
    return CustomSliverAppBar(
      title: title,
      expandedHeight: expandedHeight,
      actions: actions,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
    );
  }

  // AppBar avec bouton de retour
  static CustomSliverAppBar backAppBar(
    String title, {
    VoidCallback? onBackPressed,
    List<Widget>? actions,
  }) {
    return CustomSliverAppBar(
      title: title,
      automaticallyImplyLeading: true,
      actions: actions,
      leading: onBackPressed != null 
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: onBackPressed,
            )
          : null,
    );
  }
 static CustomSliverAppBar parametreAppBar(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CustomSliverAppBar(
      title: l10n?.identificationTitleqrcode ?? 'Paramètres',
      useFlexibleSpace: true,
      // Ajoutez flexibleSpaceContent si nécessaire
    );
  }

  // AppBar avec hauteur étendue (pour les détails)
  static CustomSliverAppBarAdvanced expandedAppBar(
    String title, {
    Widget? flexibleContent,
    double expandedHeight = 200,
    List<Widget>? actions,
  }) {
    return CustomSliverAppBarAdvanced(
      title: title,
      expandedHeight: expandedHeight,
      flexibleSpaceContent: flexibleContent,
      actions: actions,
    );
  }
}