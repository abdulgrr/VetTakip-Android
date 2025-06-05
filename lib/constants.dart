import 'package:flutter/material.dart';

class AppStyles {
  static InputDecoration inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.blue, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.blue, width: 2.0),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}

class AppConstants {
  static const String googleMapsApiKey = 'AIzaSyBS22b677ZfXecBMjj5IXx-nEkJGFHd0QY';
}

// Google Maps API Key
const String GOOGLE_MAPS_API_KEY = 'AIzaSyDxOQxZxOQxZxOQxZxOQxZxOQxZxOQxZxOQ'; // Buraya kendi API anahtarınızı ekleyin