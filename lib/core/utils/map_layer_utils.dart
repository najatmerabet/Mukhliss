import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:mukhliss/core/widgets/buttons/buildmaplayerbutton.dart'; // Importez votre enum MapLayerType

class MapLayerUtils {
  static List<Widget> getMapLayers(MapLayerType selectedMapLayer) {
    switch (selectedMapLayer) {
      case MapLayerType.plan:
        return [
          TileLayer(
            urlTemplate: 'http://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
            maxZoom: 20,
            subdomains: ['mt0', 'mt1', 'mt2', 'mt3'],
          ),
        ];
      case MapLayerType.satellite:
        return [
          TileLayer(
            urlTemplate: 'http://{s}.google.com/vt/lyrs=s&x={x}&y={y}&z={z}',
            userAgentPackageName: 'com.example.app',
            subdomains: ['mt0', 'mt1', 'mt2', 'mt3'],
          ),
        ];
      case MapLayerType.terrain:
        return [
          TileLayer(
            urlTemplate: 'http://{s}.google.com/vt/lyrs=p&x={x}&y={y}&z={z}',
            userAgentPackageName: 'com.example.app',
            subdomains: ['mt0', 'mt1', 'mt2', 'mt3'],
          ),
        ];
      case MapLayerType.trafic:
        return [
          TileLayer(
            urlTemplate: 'http://{s}.google.com/vt/lyrs=s,h&x={x}&y={y}&z={z}',
            subdomains: ['mt0', 'mt1', 'mt2', 'mt3'],
          ),
        ];
    }
  }
}