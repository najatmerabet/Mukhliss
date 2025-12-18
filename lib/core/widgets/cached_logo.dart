/// ============================================================
/// Cached Logo Widget - Affichage Optimisé des Logos
/// ============================================================
///
/// Widget qui utilise le LogoCacheService pour afficher
/// les logos de manière optimisée avec placeholder et fade-in.
library;

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/logo_cache_service.dart';

/// Provider pour le service de cache
final logoCacheServiceProvider = Provider<LogoCacheService>((ref) {
  return LogoCacheService.instance;
});

/// Widget pour afficher un logo avec cache multi-niveau
class CachedLogo extends ConsumerStatefulWidget {
  final String? logoUrl;
  final double size;
  final LogoSize cacheSize;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;

  const CachedLogo({
    super.key,
    required this.logoUrl,
    this.size = 48,
    this.cacheSize = LogoSize.thumbnail,
    this.placeholder,
    this.errorWidget,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.backgroundColor,
  });

  @override
  ConsumerState<CachedLogo> createState() => _CachedLogoState();
}

class _CachedLogoState extends ConsumerState<CachedLogo>
    with SingleTickerProviderStateMixin {
  Uint8List? _imageData;
  bool _isLoading = true;
  bool _hasError = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _loadImage();
  }

  @override
  void didUpdateWidget(CachedLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.logoUrl != widget.logoUrl) {
      _loadImage();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    if (widget.logoUrl == null || widget.logoUrl!.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final cacheService = ref.read(logoCacheServiceProvider);
      final data = await cacheService.getLogo(
        widget.logoUrl!,
        size: widget.cacheSize,
      );

      if (mounted) {
        setState(() {
          _imageData = data;
          _isLoading = false;
          _hasError = data == null;
        });

        if (data != null) {
          _fadeController.forward();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_isLoading) {
      content = widget.placeholder ?? _buildDefaultPlaceholder();
    } else if (_hasError || _imageData == null) {
      content = widget.errorWidget ?? _buildDefaultError();
    } else {
      content = FadeTransition(
        opacity: _fadeAnimation,
        child: Image.memory(
          _imageData!,
          width: widget.size,
          height: widget.size,
          fit: widget.fit,
          cacheWidth: widget.cacheSize.pixels,
          cacheHeight: widget.cacheSize.pixels,
          errorBuilder: (_, __, ___) => _buildDefaultError(),
        ),
      );
    }

    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
      child: Container(
        width: widget.size,
        height: widget.size,
        color: widget.backgroundColor ?? Colors.grey.shade100,
        child: content,
      ),
    );
  }

  Widget _buildDefaultPlaceholder() {
    return Center(
      child: SizedBox(
        width: widget.size * 0.4,
        height: widget.size * 0.4,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _buildDefaultError() {
    return Center(
      child: Icon(
        Icons.store,
        size: widget.size * 0.5,
        color: Colors.grey.shade400,
      ),
    );
  }
}

/// Widget pour afficher un logo de marqueur (très petit, optimisé)
class MarkerLogo extends StatelessWidget {
  final String? logoUrl;
  final double size;
  final Color? borderColor;

  const MarkerLogo({
    super.key,
    required this.logoUrl,
    this.size = 32,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor ?? Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CachedLogo(
        logoUrl: logoUrl,
        size: size,
        cacheSize: LogoSize.thumbnail,
        borderRadius: BorderRadius.circular(size / 2),
        placeholder: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.store,
            size: size * 0.5,
            color: Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}

/// Widget pour précharger les logos d'une liste de magasins
class LogoPreloader extends ConsumerWidget {
  final List<String?> logoUrls;
  final Widget child;

  const LogoPreloader({
    super.key,
    required this.logoUrls,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Lancer le préchargement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cacheService = ref.read(logoCacheServiceProvider);
      final validUrls = logoUrls
          .where((url) => url != null && url.isNotEmpty)
          .cast<String>()
          .toList();
      cacheService.preloadLogos(validUrls);
    });

    return child;
  }
}

/// Extension pour faciliter l'utilisation
extension LogoCacheExtension on WidgetRef {
  Future<void> preloadLogos(List<String?> urls) async {
    final cacheService = read(logoCacheServiceProvider);
    final validUrls = urls
        .where((url) => url != null && url.isNotEmpty)
        .cast<String>()
        .toList();
    await cacheService.preloadLogos(validUrls);
  }
}
