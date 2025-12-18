// lib/widgets/common/custom_sliver_app_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/core/theme/app_theme.dart';
import 'package:mukhliss/core/providers/theme_provider.dart';

class CustomSliverAppBar extends ConsumerWidget {
  final String title;
  final double? expandedHeight;
  final bool pinned;
  final bool floating;
  final bool automaticallyImplyLeading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget? leading;
  final TextStyle? titleStyle;
  final bool centerTitle;

  final bool useFlexibleSpace;
  final Widget? flexibleSpaceContent;
  final List<Color>? customGradientColors;
  final AlignmentGeometry? gradientBegin;
  final AlignmentGeometry? gradientEnd;
  final bool showDefaultLeading;
  const CustomSliverAppBar({
    super.key,
    required this.title,
    this.expandedHeight = 60,
    this.pinned = true,
    this.floating = false,
    this.automaticallyImplyLeading = false,
    this.actions,
    this.bottom,
    this.leading,
    this.titleStyle,
    this.centerTitle = true,

     this.useFlexibleSpace = false,
    this.flexibleSpaceContent,
    this.customGradientColors,
    this.gradientBegin,
    this.gradientEnd,
     this.showDefaultLeading = false,
  });

    Widget _buildDefaultLeading(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
    }
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == AppThemeMode.dark;
     final Widget? effectiveLeading = leading ?? (showDefaultLeading ? _buildDefaultLeading(context) : null);
    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: floating,
      pinned: pinned,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: effectiveLeading,
      actions: actions,
      bottom: bottom,
      backgroundColor: Colors.transparent,
      centerTitle: centerTitle,
      flexibleSpace: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDarkMode
              ? [Color(0xFF0A0E27), Color(0xFF0A0E27)]
              : [AppColors.lightPrimary, AppColors.lightSecondary],
        ),
      ),
    // Conserver votre flexibleSpace existant si nécessaire
    ),
      title: Text(
        title,
        style: titleStyle ?? const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// Version alternative avec plus de personnalisation
class CustomSliverAppBarAdvanced extends ConsumerWidget {
  final String title;
  final double? expandedHeight;
  final bool pinned;
  final bool floating;
  final bool automaticallyImplyLeading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget? leading;
  final TextStyle? titleStyle;
  final bool centerTitle;
  final List<Color>? customGradientColors;
  final AlignmentGeometry? gradientBegin;
  final AlignmentGeometry? gradientEnd;
  final Widget? flexibleSpaceContent;

  const CustomSliverAppBarAdvanced({
    super.key,
    required this.title,
    this.expandedHeight = 60,
    this.pinned = true,
    this.floating = false,
    this.automaticallyImplyLeading = false,
    this.actions,
    this.bottom,
    this.leading,
    this.titleStyle,
    this.centerTitle = false,
    this.customGradientColors,
    this.gradientBegin,
    this.gradientEnd,
    this.flexibleSpaceContent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == AppThemeMode.dark;

    List<Color> gradientColors = customGradientColors ?? 
        (isDarkMode 
            ? [AppColors.darkPrimary]
            : [AppColors.lightPrimary, AppColors.lightSecondary]);

    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: floating,
      pinned: pinned,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      actions: actions,
      bottom: bottom,
      centerTitle: centerTitle,
       backgroundColor: isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: gradientBegin ?? Alignment.topLeft,
                  end: gradientEnd ?? Alignment.bottomRight,
                  colors: gradientColors,
                ),
              ),
            ),
            if (flexibleSpaceContent != null) flexibleSpaceContent!,
          ],
        ),
      ),
      title: Text(
        title,
        style: titleStyle ?? const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}