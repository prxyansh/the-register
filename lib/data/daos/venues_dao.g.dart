// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'venues_dao.dart';

// ignore_for_file: type=lint
mixin _$VenuesDaoMixin on DatabaseAccessor<AppDatabase> {
  $VenuesTable get venues => attachedDatabase.venues;
  VenuesDaoManager get managers => VenuesDaoManager(this);
}

class VenuesDaoManager {
  final _$VenuesDaoMixin _db;
  VenuesDaoManager(this._db);
  $$VenuesTableTableManager get venues =>
      $$VenuesTableTableManager(_db.attachedDatabase, _db.venues);
}
