import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull, Column;
import 'package:geolocator/geolocator.dart';
import '../data/app_database.dart';
import '../data/providers.dart';
import '../domain/geo_utils.dart';
import 'package:latlong2/latlong.dart';
import 'map_picker_screen.dart';

/// Venue form screen — SPEC.md §10, Screen 3.
/// Lets users create/edit venues with GPS coordinates, radius slider,
/// and WiFi SSID. Shows overlap warnings per §8.
class VenueFormScreen extends ConsumerStatefulWidget {
  final Venue? existingVenue; // null = creating new

  const VenueFormScreen({super.key, this.existingVenue});

  @override
  ConsumerState<VenueFormScreen> createState() => _VenueFormScreenState();
}

class _VenueFormScreenState extends ConsumerState<VenueFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _wifiController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  late double _radiusMeters;
  bool _isLocating = false;
  String? _locationError;

  bool get _isEditing => widget.existingVenue != null;

  @override
  void initState() {
    super.initState();
    final v = widget.existingVenue;
    _nameController = TextEditingController(text: v?.name ?? '');
    _wifiController = TextEditingController(text: v?.wifiSsid ?? '');
    _latController =
        TextEditingController(text: v != null ? v.latitude.toString() : '');
    _lngController =
        TextEditingController(text: v != null ? v.longitude.toString() : '');
    _radiusMeters = v?.radiusMeters ?? 30.0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _wifiController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLocating = true;
      _locationError = null;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Location services are disabled. Please enable GPS.';
          _isLocating = false;
        });
        return;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Location permission denied.';
            _isLocating = false;
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError =
              'Location permanently denied. Please enable in Settings.';
          _isLocating = false;
        });
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      setState(() {
        _latController.text = position.latitude.toStringAsFixed(6);
        _lngController.text = position.longitude.toStringAsFixed(6);
        _isLocating = false;
      });
    } catch (e) {
      setState(() {
        _locationError = 'Could not get location: ${e.toString()}';
        _isLocating = false;
      });
    }
  }

  Future<void> _openMapPicker() async {
    final double? initialLat = double.tryParse(_latController.text);
    final double? initialLng = double.tryParse(_lngController.text);

    final LatLng? pickedLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(
          initialLat: initialLat,
          initialLng: initialLng,
        ),
      ),
    );

    if (pickedLocation != null) {
      setState(() {
        _latController.text = pickedLocation.latitude.toStringAsFixed(6);
        _lngController.text = pickedLocation.longitude.toStringAsFixed(6);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Venue' : 'New Venue'),
        actions: [
          TextButton.icon(
            onPressed: _canSave ? _save : null,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Venue name
            TextFormField(
              controller: _nameController,
              autofocus: !_isEditing,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Venue Name',
                hintText: 'e.g. LHC Room 204',
                prefixIcon: Icon(Icons.location_city_rounded),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter a venue name'
                  : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),

            // Location section header
            Row(
              children: [
                Icon(Icons.location_on_rounded,
                    size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'GPS Coordinates',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Location buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _isLocating ? null : _useCurrentLocation,
                    icon: _isLocating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location_rounded),
                    label: Text(
                        _isLocating ? 'Locating...' : 'Current GPS'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openMapPicker,
                    icon: const Icon(Icons.map_rounded),
                    label: const Text('Pick on Map'),
                  ),
                ),
              ],
            ),

            if (_locationError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _locationError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // Lat/Lng fields
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      hintText: '10.7620',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final d = double.tryParse(v);
                      if (d == null || d < -90 || d > 90) return 'Invalid';
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lngController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      hintText: '79.4980',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final d = double.tryParse(v);
                      if (d == null || d < -180 || d > 180) return 'Invalid';
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Radius slider
            Row(
              children: [
                Icon(Icons.radar_rounded,
                    size: 20, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  'Detection Radius',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_radiusMeters.round()}m',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Slider(
              value: _radiusMeters,
              min: 10,
              max: 100,
              divisions: 18, // steps of 5m
              label: '${_radiusMeters.round()}m',
              onChanged: (v) => setState(() => _radiusMeters = v),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('10m', style: theme.textTheme.bodySmall),
                  Text('100m', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // WiFi SSID (optional)
            TextFormField(
              controller: _wifiController,
              decoration: const InputDecoration(
                labelText: 'WiFi SSID (optional)',
                hintText: 'e.g. NITT-WiFi',
                prefixIcon: Icon(Icons.wifi_rounded),
                helperText: 'Secondary signal for better accuracy in buildings',
              ),
            ),
            const SizedBox(height: 32),

            // Overlap warnings (computed live)
            _OverlapWarnings(
              currentLat: double.tryParse(_latController.text),
              currentLng: double.tryParse(_lngController.text),
              excludeVenueId: widget.existingVenue?.id,
            ),
          ],
        ),
      ),
    );
  }

  bool get _canSave {
    return _nameController.text.trim().isNotEmpty &&
        double.tryParse(_latController.text) != null &&
        double.tryParse(_lngController.text) != null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final lat = double.parse(_latController.text);
    final lng = double.parse(_lngController.text);
    final wifi = _wifiController.text.trim();

    if (_isEditing) {
      await ref.read(venuesDaoProvider).updateVenue(
            widget.existingVenue!.copyWith(
              name: _nameController.text.trim(),
              latitude: lat,
              longitude: lng,
              radiusMeters: _radiusMeters,
              wifiSsid: Value(wifi.isEmpty ? null : wifi),
            ),
          );
    } else {
      await ref.read(venuesDaoProvider).insertVenue(
            VenuesCompanion.insert(
              name: _nameController.text.trim(),
              latitude: lat,
              longitude: lng,
              radiusMeters: Value(_radiusMeters),
              wifiSsid: Value(wifi.isEmpty ? null : wifi),
            ),
          );
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }
}

/// Shows warnings for any existing venues within 60m of the current coordinates.
/// Per SPEC.md §8: "if under a risk threshold (e.g. 60m), show a warning"
class _OverlapWarnings extends ConsumerWidget {
  final double? currentLat;
  final double? currentLng;
  final int? excludeVenueId;

  const _OverlapWarnings({
    required this.currentLat,
    required this.currentLng,
    this.excludeVenueId,
  });

  static const double _overlapThresholdMeters = 60.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (currentLat == null || currentLng == null) return const SizedBox.shrink();

    final venuesAsync = ref.watch(allVenuesProvider);
    final theme = Theme.of(context);

    return venuesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (venues) {
        final nearbyVenues = <_NearbyVenue>[];

        for (final venue in venues) {
          if (venue.id == excludeVenueId) continue;

          final distance = haversineDistance(
            currentLat!,
            currentLng!,
            venue.latitude,
            venue.longitude,
          );

          if (distance <= _overlapThresholdMeters) {
            nearbyVenues.add(_NearbyVenue(venue: venue, distance: distance));
          }
        }

        if (nearbyVenues.isEmpty) return const SizedBox.shrink();

        nearbyVenues.sort((a, b) => a.distance.compareTo(b.distance));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 20, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Text(
                  'Overlap Warnings',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...nearbyVenues.map((nearby) => Card(
                  color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            color: theme.colorScheme.error, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text: 'Close to ',
                              style: theme.textTheme.bodyMedium,
                              children: [
                                TextSpan(
                                  text: nearby.venue.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                  text:
                                      ' (${nearby.distance.round()}m away) — GPS may confuse the two classes.',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        );
      },
    );
  }
}

class _NearbyVenue {
  final Venue venue;
  final double distance;
  _NearbyVenue({required this.venue, required this.distance});
}
