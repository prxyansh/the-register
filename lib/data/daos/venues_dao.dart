import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'venues_dao.g.dart';

/// DAO for CRUD operations on the Venues table.
@DriftAccessor(tables: [Venues])
class VenuesDao extends DatabaseAccessor<AppDatabase> with _$VenuesDaoMixin {
  VenuesDao(super.db);

  /// Get all venues as a reactive stream.
  Stream<List<Venue>> watchAllVenues() => select(venues).watch();

  /// Get all venues (one-shot).
  Future<List<Venue>> getAllVenues() => select(venues).get();

  /// Get a single venue by ID.
  Future<Venue> getVenueById(int id) =>
      (select(venues)..where((v) => v.id.equals(id))).getSingle();

  /// Insert a new venue, returns the generated ID.
  Future<int> insertVenue(VenuesCompanion venue) =>
      into(venues).insert(venue);

  /// Update an existing venue.
  Future<bool> updateVenue(Venue venue) => update(venues).replace(venue);

  /// Delete a venue by ID.
  Future<int> deleteVenueById(int id) =>
      (delete(venues)..where((v) => v.id.equals(id))).go();
}
