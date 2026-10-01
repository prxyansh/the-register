import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/app_database.dart';
import '../data/providers.dart';
import 'venue_form_screen.dart';

/// Venue management screen — lists all saved venues with edit/delete.
class VenuesScreen extends ConsumerWidget {
  const VenuesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venuesAsync = ref.watch(allVenuesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Venues'),
      ),
      body: venuesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (venues) {
          if (venues.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outline, width: 4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.location_off_rounded,
                        size: 48,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'NO VENUES SET.\nADD ONE.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: theme.colorScheme.onSurface,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Pin your classroom locations and WiFi to enable auto-tracking.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => _addVenue(context),
                      icon: const Icon(Icons.add_location_alt_rounded),
                      label: const Text('Add Venue'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            itemCount: venues.length,
            itemBuilder: (context, index) {
              return _VenueCard(venue: venues[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addVenue(context),
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text('Add Venue'),
      ),
    );
  }

  void _addVenue(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VenueFormScreen()),
    );
  }
}

class _VenueCard extends ConsumerWidget {
  final Venue venue;

  const _VenueCard({required this.venue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _editVenue(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venue.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${venue.latitude.toStringAsFixed(4)}, ${venue.longitude.toStringAsFixed(4)} · ${venue.radiusMeters.round()}m radius',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (venue.wifiSsid != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.wifi_rounded,
                              size: 14, color: theme.colorScheme.outline),
                          const SizedBox(width: 4),
                          Text(
                            venue.wifiSsid!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _editVenue(context);
                  } else if (value == 'delete') {
                    _deleteVenue(context, ref);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_rounded,
                            size: 18, color: theme.colorScheme.error),
                        const SizedBox(width: 8),
                        Text('Delete',
                            style: TextStyle(color: theme.colorScheme.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editVenue(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => VenueFormScreen(existingVenue: venue)),
    );
  }

  Future<void> _deleteVenue(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Venue?'),
        content: Text(
            'This will delete "${venue.name}". Timetable entries using this venue will be unlinked.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(venuesDaoProvider).deleteVenueById(venue.id);
    }
  }
}
