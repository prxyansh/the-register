// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'holidays_dao.dart';

// ignore_for_file: type=lint
mixin _$HolidaysDaoMixin on DatabaseAccessor<AppDatabase> {
  $HolidaysTable get holidays => attachedDatabase.holidays;
  HolidaysDaoManager get managers => HolidaysDaoManager(this);
}

class HolidaysDaoManager {
  final _$HolidaysDaoMixin _db;
  HolidaysDaoManager(this._db);
  $$HolidaysTableTableManager get holidays =>
      $$HolidaysTableTableManager(_db.attachedDatabase, _db.holidays);
}
