import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class MapControllerButton extends StatelessWidget  {

  final IconData icon;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final bool isLoading ;

  const MapControllerButton ({
     required this.icon,
     required this.onPressed,
     required this.backgroundColor,
     required this.isLoading
  });

  @override
  Widget build(BuildContext context) {
   
   return Material(
    shape: const CircleBorder(),
    elevation: 2,
    child: Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
      ),
      child: IconButton(
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    ),
  );
  }

}