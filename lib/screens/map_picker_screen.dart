import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
class MapPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapPickerScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late MapController _mapController;
  late LatLng _currentCenter;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentCenter = LatLng(
      widget.initialLat ?? 40.7128, // Default to NYC if nothing provided
      widget.initialLng ?? -74.0060,
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  bool _isLocating = false;

  Future<void> _goToCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
        }
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;
      
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
      );
      
      final currentLatLng = LatLng(position.latitude, position.longitude);
      _mapController.move(currentLatLng, 17.0);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 16.0,
              onPositionChanged: (position, hasGesture) {
                setState(() {
                  _currentCenter = position.center;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.attendance_tracker',
              ),
            ],
          ),
          // Center Pin marker
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40.0), // offset to point at center
              child: Icon(
                Icons.location_on,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          // Target crosshair (optional, helps precision)
          Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.black38,
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          // Current location button
          Positioned(
            right: 16,
            bottom: 80, // Above the Select Location FAB
            child: FloatingActionButton.small(
              heroTag: 'current_location_fab',
              onPressed: _isLocating ? null : _goToCurrentLocation,
              child: _isLocating 
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'select_location_fab',
        onPressed: () {
          Navigator.pop(context, _currentCenter);
        },
        icon: const Icon(Icons.check_rounded),
        label: const Text('Select Location'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
