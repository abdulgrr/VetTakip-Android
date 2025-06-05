import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../constants.dart';

class PlacesService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  Future<List<dynamic>> searchPlaces(String query, LatLng location) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/autocomplete/json'
        '?input=$query'
        '&location=${location.latitude},${location.longitude}'
        '&radius=5000'
        '&language=tr'
        '&key=${AppConstants.googleMapsApiKey}'
      );

      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        return data['predictions'];
      } else {
        throw Exception(data['error_message'] ?? 'Arama yapılırken bir hata oluştu');
      }
    } catch (e) {
      throw Exception('Arama yapılırken bir hata oluştu: $e');
    }
  }

  Future<Map<String, dynamic>> getPlaceDetails(String placeId) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/details/json'
        '?place_id=$placeId'
        '&fields=geometry,name,formatted_address'
        '&key=${AppConstants.googleMapsApiKey}'
      );

      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        return data['result'];
      } else {
        throw Exception(data['error_message'] ?? 'Konum detayları alınamadı');
      }
    } catch (e) {
      throw Exception('Konum detayları alınamadı: $e');
    }
  }
} 