/// ============================================================
/// Draggable Bottom Sheet Wrapper
/// ============================================================
///
/// Wrapper pour rendre les bottom sheets glissables
/// avec animation et geste swipe down pour fermer.
library;

import 'package:flutter/material.dart';

/// Bottom sheet draggable avec geste swipe
class DraggableBottomSheetWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onClose;
  final double minHeight;
  final double maxHeight;
  final bool showHandle;

  const DraggableBottomSheetWrapper({
    super.key,
    required this.child,
    required this.onClose,
    this.minHeight = 0.3,
    this.maxHeight = 0.8,
    this.showHandle = true,
  });

  @override
  State<DraggableBottomSheetWrapper> createState() => _DraggableBottomSheetWrapperState();
}

class _DraggableBottomSheetWrapperState extends State<DraggableBottomSheetWrapper> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  double _dragOffset = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    // Animer l'entrée
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails details) {
    _isDragging = true;
    _dragOffset = 0;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (details.delta.dy > 0) {
      // Drag vers le bas uniquement
      setState(() {
        _dragOffset += details.delta.dy;
      });
    }
  }

  void _onDragEnd(DragEndDetails details) {
    _isDragging = false;
    
    // Si drag > 100px ou vélocité > 500, fermer
    if (_dragOffset > 100 || details.velocity.pixelsPerSecond.dy > 500) {
      _close();
    } else {
      // Revenir à la position initiale
      setState(() {
        _dragOffset = 0;
      });
    }
  }

  void _close() {
    _controller.reverse().then((_) {
      widget.onClose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {}, // Empêcher les taps de passer à travers
      child: SlideTransition(
        position: _offsetAnimation,
        child: Transform.translate(
          offset: Offset(0, _dragOffset),
          child: GestureDetector(
            onVerticalDragStart: _onDragStart,
            onVerticalDragUpdate: _onDragUpdate,
            onVerticalDragEnd: _onDragEnd,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar pour indiquer qu'on peut glisser
                  if (widget.showHandle)
                    GestureDetector(
                      onVerticalDragStart: _onDragStart,
                      onVerticalDragUpdate: _onDragUpdate,
                      onVerticalDragEnd: _onDragEnd,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Contenu
                  widget.child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Overlay semi-transparent pour les bottom sheets
class BottomSheetOverlay extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const BottomSheetOverlay({
    super.key,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fond semi-transparent qui ferme au tap
        Positioned.fill(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ),
        ),
        // Le bottom sheet lui-même
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: child,
        ),
      ],
    );
  }
}
