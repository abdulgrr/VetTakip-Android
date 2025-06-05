import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String? _address;
  bool _isLoading = false;
  Set<Marker> _markers = {};

  // Buca, İzmir koordinatları
  static const LatLng _bucaLocation = LatLng(38.375733, 27.172433);

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    setState(() {
      _selectedLocation = _bucaLocation;
      _markers.add(
        Marker(
          markerId: const MarkerId('initial'),
          position: _bucaLocation,
          infoWindow: const InfoWindow(title: 'Seçilen Konum'),
        ),
      );
    });
    _updateAddress();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _moveToLocation(_bucaLocation);
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      final location = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedLocation = location;
        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId('current'),
            position: location,
            infoWindow: const InfoWindow(title: 'Mevcut Konum'),
          ),
        );
      });
      _moveToLocation(location);
    } catch (e) {
      _moveToLocation(_bucaLocation);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konum alınamadı. Buca merkezini gösteriyorum.')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _moveToLocation(LatLng location) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: location,
          zoom: 15.0,
        ),
      ),
    );
    _updateAddress();
  }

  Future<void> _updateAddress() async {
    if (_selectedLocation == null) return;
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _address = '${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}';
        });
      }
    } catch (e) {
      print('Adres çözümleme hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konum Seç'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedLocation != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context, {
                  'location': '${_selectedLocation!.latitude},${_selectedLocation!.longitude}',
                  'address': _address,
                });
              },
              child: const Text(
                'Seç',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _bucaLocation,
              zoom: 15.0,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            mapType: MapType.normal,
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            onTap: (location) {
              setState(() {
                _selectedLocation = location;
                _markers.clear();
                _markers.add(
                  Marker(
                    markerId: const MarkerId('selected'),
                    position: location,
                    infoWindow: InfoWindow(
                      title: 'Seçilen Konum',
                      snippet: _address,
                    ),
                  ),
                );
              });
              _updateAddress();
            },
          ),
          if (_address != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _address!,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}