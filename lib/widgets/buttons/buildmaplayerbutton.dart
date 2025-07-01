library map_layer_button;
import 'package:flutter/material.dart';

enum MapLayerType {
  plan,
  satellite,
  terrain,
  trafic
}

class MapLayerButton extends StatelessWidget {
  final MapLayerType layer;
  final MapLayerType selectedLayer;
  final IconData icon;
  final String label;
  final ValueChanged<MapLayerType> onSelected;

  const MapLayerButton({
    Key? key,
    required this.layer,
    required this.selectedLayer,
    required this.icon,
    required this.label,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedLayer == layer;
    
    return GestureDetector(
      onTap: () => onSelected(layer),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade700 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, 
                size: 20, 
                color: isSelected ? Colors.white : Colors.blue.shade700),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    color: isSelected ? Colors.white : Colors.blue.shade700,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check, color: Colors.white, size: 20),
          ],
        ),
      ),
      
    );
  }
}