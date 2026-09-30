// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SubjectsTable extends Subjects with TableInfo<$SubjectsTable, Subject> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetAttendancePctMeta =
      const VerificationMeta('targetAttendancePct');
  @override
  late final GeneratedColumn<double> targetAttendancePct =
      GeneratedColumn<double>(
        'target_attendance_pct',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(75.0),
      );
  static const VerificationMeta _facultyNameMeta = const VerificationMeta(
    'facultyName',
  );
  @override
  late final GeneratedColumn<String> facultyName = GeneratedColumn<String>(
    'faculty_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    color,
    targetAttendancePct,
    facultyName,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subjects';
  @override
  VerificationContext validateIntegrity(
    Insertable<Subject> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('target_attendance_pct')) {
      context.handle(
        _targetAttendancePctMeta,
        targetAttendancePct.isAcceptableOrUnknown(
          data['target_attendance_pct']!,
          _targetAttendancePctMeta,
        ),
      );
    }
    if (data.containsKey('faculty_name')) {
      context.handle(
        _facultyNameMeta,
        facultyName.isAcceptableOrUnknown(
          data['faculty_name']!,
          _facultyNameMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Subject map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Subject(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      )!,
      targetAttendancePct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_attendance_pct'],
      )!,
      facultyName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}faculty_name'],
      ),
    );
  }

  @override
  $SubjectsTable createAlias(String alias) {
    return $SubjectsTable(attachedDatabase, alias);
  }
}

class Subject extends DataClass implements Insertable<Subject> {
  final int id;
  final String name;
  final int color;
  final double targetAttendancePct;
  final String? facultyName;
  const Subject({
    required this.id,
    required this.name,
    required this.color,
    required this.targetAttendancePct,
    this.facultyName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['color'] = Variable<int>(color);
    map['target_attendance_pct'] = Variable<double>(targetAttendancePct);
    if (!nullToAbsent || facultyName != null) {
      map['faculty_name'] = Variable<String>(facultyName);
    }
    return map;
  }

  SubjectsCompanion toCompanion(bool nullToAbsent) {
    return SubjectsCompanion(
      id: Value(id),
      name: Value(name),
      color: Value(color),
      targetAttendancePct: Value(targetAttendancePct),
      facultyName: facultyName == null && nullToAbsent
          ? const Value.absent()
          : Value(facultyName),
    );
  }

  factory Subject.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Subject(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<int>(json['color']),
      targetAttendancePct: serializer.fromJson<double>(
        json['targetAttendancePct'],
      ),
      facultyName: serializer.fromJson<String?>(json['facultyName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<int>(color),
      'targetAttendancePct': serializer.toJson<double>(targetAttendancePct),
      'facultyName': serializer.toJson<String?>(facultyName),
    };
  }

  Subject copyWith({
    int? id,
    String? name,
    int? color,
    double? targetAttendancePct,
    Value<String?> facultyName = const Value.absent(),
  }) => Subject(
    id: id ?? this.id,
    name: name ?? this.name,
    color: color ?? this.color,
    targetAttendancePct: targetAttendancePct ?? this.targetAttendancePct,
    facultyName: facultyName.present ? facultyName.value : this.facultyName,
  );
  Subject copyWithCompanion(SubjectsCompanion data) {
    return Subject(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      targetAttendancePct: data.targetAttendancePct.present
          ? data.targetAttendancePct.value
          : this.targetAttendancePct,
      facultyName: data.facultyName.present
          ? data.facultyName.value
          : this.facultyName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Subject(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('targetAttendancePct: $targetAttendancePct, ')
          ..write('facultyName: $facultyName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, color, targetAttendancePct, facultyName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Subject &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color &&
          other.targetAttendancePct == this.targetAttendancePct &&
          other.facultyName == this.facultyName);
}

class SubjectsCompanion extends UpdateCompanion<Subject> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> color;
  final Value<double> targetAttendancePct;
  final Value<String?> facultyName;
  const SubjectsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.targetAttendancePct = const Value.absent(),
    this.facultyName = const Value.absent(),
  });
  SubjectsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int color,
    this.targetAttendancePct = const Value.absent(),
    this.facultyName = const Value.absent(),
  }) : name = Value(name),
       color = Value(color);
  static Insertable<Subject> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? color,
    Expression<double>? targetAttendancePct,
    Expression<String>? facultyName,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (targetAttendancePct != null)
        'target_attendance_pct': targetAttendancePct,
      if (facultyName != null) 'faculty_name': facultyName,
    });
  }

  SubjectsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? color,
    Value<double>? targetAttendancePct,
    Value<String?>? facultyName,
  }) {
    return SubjectsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      targetAttendancePct: targetAttendancePct ?? this.targetAttendancePct,
      facultyName: facultyName ?? this.facultyName,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (targetAttendancePct.present) {
      map['target_attendance_pct'] = Variable<double>(
        targetAttendancePct.value,
      );
    }
    if (facultyName.present) {
      map['faculty_name'] = Variable<String>(facultyName.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubjectsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('targetAttendancePct: $targetAttendancePct, ')
          ..write('facultyName: $facultyName')
          ..write(')'))
        .toString();
  }
}

class $VenuesTable extends Venues with TableInfo<$VenuesTable, Venue> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VenuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _radiusMetersMeta = const VerificationMeta(
    'radiusMeters',
  );
  @override
  late final GeneratedColumn<double> radiusMeters = GeneratedColumn<double>(
    'radius_meters',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(30.0),
  );
  static const VerificationMeta _wifiSsidMeta = const VerificationMeta(
    'wifiSsid',
  );
  @override
  late final GeneratedColumn<String> wifiSsid = GeneratedColumn<String>(
    'wifi_ssid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    latitude,
    longitude,
    radiusMeters,
    wifiSsid,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'venues';
  @override
  VerificationContext validateIntegrity(
    Insertable<Venue> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('radius_meters')) {
      context.handle(
        _radiusMetersMeta,
        radiusMeters.isAcceptableOrUnknown(
          data['radius_meters']!,
          _radiusMetersMeta,
        ),
      );
    }
    if (data.containsKey('wifi_ssid')) {
      context.handle(
        _wifiSsidMeta,
        wifiSsid.isAcceptableOrUnknown(data['wifi_ssid']!, _wifiSsidMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Venue map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Venue(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      radiusMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}radius_meters'],
      )!,
      wifiSsid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wifi_ssid'],
      ),
    );
  }

  @override
  $VenuesTable createAlias(String alias) {
    return $VenuesTable(attachedDatabase, alias);
  }
}

class Venue extends DataClass implements Insertable<Venue> {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String? wifiSsid;
  const Venue({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.wifiSsid,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['radius_meters'] = Variable<double>(radiusMeters);
    if (!nullToAbsent || wifiSsid != null) {
      map['wifi_ssid'] = Variable<String>(wifiSsid);
    }
    return map;
  }

  VenuesCompanion toCompanion(bool nullToAbsent) {
    return VenuesCompanion(
      id: Value(id),
      name: Value(name),
      latitude: Value(latitude),
      longitude: Value(longitude),
      radiusMeters: Value(radiusMeters),
      wifiSsid: wifiSsid == null && nullToAbsent
          ? const Value.absent()
          : Value(wifiSsid),
    );
  }

  factory Venue.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Venue(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      radiusMeters: serializer.fromJson<double>(json['radiusMeters']),
      wifiSsid: serializer.fromJson<String?>(json['wifiSsid']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'radiusMeters': serializer.toJson<double>(radiusMeters),
      'wifiSsid': serializer.toJson<String?>(wifiSsid),
    };
  }

  Venue copyWith({
    int? id,
    String? name,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    Value<String?> wifiSsid = const Value.absent(),
  }) => Venue(
    id: id ?? this.id,
    name: name ?? this.name,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    radiusMeters: radiusMeters ?? this.radiusMeters,
    wifiSsid: wifiSsid.present ? wifiSsid.value : this.wifiSsid,
  );
  Venue copyWithCompanion(VenuesCompanion data) {
    return Venue(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      radiusMeters: data.radiusMeters.present
          ? data.radiusMeters.value
          : this.radiusMeters,
      wifiSsid: data.wifiSsid.present ? data.wifiSsid.value : this.wifiSsid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Venue(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('radiusMeters: $radiusMeters, ')
          ..write('wifiSsid: $wifiSsid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, latitude, longitude, radiusMeters, wifiSsid);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Venue &&
          other.id == this.id &&
          other.name == this.name &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.radiusMeters == this.radiusMeters &&
          other.wifiSsid == this.wifiSsid);
}

class VenuesCompanion extends UpdateCompanion<Venue> {
  final Value<int> id;
  final Value<String> name;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<double> radiusMeters;
  final Value<String?> wifiSsid;
  const VenuesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.radiusMeters = const Value.absent(),
    this.wifiSsid = const Value.absent(),
  });
  VenuesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required double latitude,
    required double longitude,
    this.radiusMeters = const Value.absent(),
    this.wifiSsid = const Value.absent(),
  }) : name = Value(name),
       latitude = Value(latitude),
       longitude = Value(longitude);
  static Insertable<Venue> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? radiusMeters,
    Expression<String>? wifiSsid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (radiusMeters != null) 'radius_meters': radiusMeters,
      if (wifiSsid != null) 'wifi_ssid': wifiSsid,
    });
  }

  VenuesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<double>? radiusMeters,
    Value<String?>? wifiSsid,
  }) {
    return VenuesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      wifiSsid: wifiSsid ?? this.wifiSsid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (radiusMeters.present) {
      map['radius_meters'] = Variable<double>(radiusMeters.value);
    }
    if (wifiSsid.present) {
      map['wifi_ssid'] = Variable<String>(wifiSsid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VenuesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('radiusMeters: $radiusMeters, ')
          ..write('wifiSsid: $wifiSsid')
          ..write(')'))
        .toString();
  }
}

class $TimetableEntriesTable extends TimetableEntries
    with TableInfo<$TimetableEntriesTable, TimetableEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimetableEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _subjectIdMeta = const VerificationMeta(
    'subjectId',
  );
  @override
  late final GeneratedColumn<int> subjectId = GeneratedColumn<int>(
    'subject_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES subjects (id)',
    ),
  );
  static const VerificationMeta _venueIdMeta = const VerificationMeta(
    'venueId',
  );
  @override
  late final GeneratedColumn<int> venueId = GeneratedColumn<int>(
    'venue_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES venues (id)',
    ),
  );
  static const VerificationMeta _dayOfWeekMeta = const VerificationMeta(
    'dayOfWeek',
  );
  @override
  late final GeneratedColumn<int> dayOfWeek = GeneratedColumn<int>(
    'day_of_week',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<String> startTime = GeneratedColumn<String>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<String> endTime = GeneratedColumn<String>(
    'end_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    subjectId,
    venueId,
    dayOfWeek,
    startTime,
    endTime,
    active,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'timetable_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<TimetableEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('subject_id')) {
      context.handle(
        _subjectIdMeta,
        subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectIdMeta);
    }
    if (data.containsKey('venue_id')) {
      context.handle(
        _venueIdMeta,
        venueId.isAcceptableOrUnknown(data['venue_id']!, _venueIdMeta),
      );
    }
    if (data.containsKey('day_of_week')) {
      context.handle(
        _dayOfWeekMeta,
        dayOfWeek.isAcceptableOrUnknown(data['day_of_week']!, _dayOfWeekMeta),
      );
    } else if (isInserting) {
      context.missing(_dayOfWeekMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TimetableEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimetableEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      subjectId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}subject_id'],
      )!,
      venueId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}venue_id'],
      ),
      dayOfWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_of_week'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_time'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
    );
  }

  @override
  $TimetableEntriesTable createAlias(String alias) {
    return $TimetableEntriesTable(attachedDatabase, alias);
  }
}

class TimetableEntry extends DataClass implements Insertable<TimetableEntry> {
  final int id;
  final int subjectId;
  final int? venueId;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final bool active;
  const TimetableEntry({
    required this.id,
    required this.subjectId,
    this.venueId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.active,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['subject_id'] = Variable<int>(subjectId);
    if (!nullToAbsent || venueId != null) {
      map['venue_id'] = Variable<int>(venueId);
    }
    map['day_of_week'] = Variable<int>(dayOfWeek);
    map['start_time'] = Variable<String>(startTime);
    map['end_time'] = Variable<String>(endTime);
    map['active'] = Variable<bool>(active);
    return map;
  }

  TimetableEntriesCompanion toCompanion(bool nullToAbsent) {
    return TimetableEntriesCompanion(
      id: Value(id),
      subjectId: Value(subjectId),
      venueId: venueId == null && nullToAbsent
          ? const Value.absent()
          : Value(venueId),
      dayOfWeek: Value(dayOfWeek),
      startTime: Value(startTime),
      endTime: Value(endTime),
      active: Value(active),
    );
  }

  factory TimetableEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimetableEntry(
      id: serializer.fromJson<int>(json['id']),
      subjectId: serializer.fromJson<int>(json['subjectId']),
      venueId: serializer.fromJson<int?>(json['venueId']),
      dayOfWeek: serializer.fromJson<int>(json['dayOfWeek']),
      startTime: serializer.fromJson<String>(json['startTime']),
      endTime: serializer.fromJson<String>(json['endTime']),
      active: serializer.fromJson<bool>(json['active']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'subjectId': serializer.toJson<int>(subjectId),
      'venueId': serializer.toJson<int?>(venueId),
      'dayOfWeek': serializer.toJson<int>(dayOfWeek),
      'startTime': serializer.toJson<String>(startTime),
      'endTime': serializer.toJson<String>(endTime),
      'active': serializer.toJson<bool>(active),
    };
  }

  TimetableEntry copyWith({
    int? id,
    int? subjectId,
    Value<int?> venueId = const Value.absent(),
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    bool? active,
  }) => TimetableEntry(
    id: id ?? this.id,
    subjectId: subjectId ?? this.subjectId,
    venueId: venueId.present ? venueId.value : this.venueId,
    dayOfWeek: dayOfWeek ?? this.dayOfWeek,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    active: active ?? this.active,
  );
  TimetableEntry copyWithCompanion(TimetableEntriesCompanion data) {
    return TimetableEntry(
      id: data.id.present ? data.id.value : this.id,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      venueId: data.venueId.present ? data.venueId.value : this.venueId,
      dayOfWeek: data.dayOfWeek.present ? data.dayOfWeek.value : this.dayOfWeek,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      active: data.active.present ? data.active.value : this.active,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimetableEntry(')
          ..write('id: $id, ')
          ..write('subjectId: $subjectId, ')
          ..write('venueId: $venueId, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    subjectId,
    venueId,
    dayOfWeek,
    startTime,
    endTime,
    active,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimetableEntry &&
          other.id == this.id &&
          other.subjectId == this.subjectId &&
          other.venueId == this.venueId &&
          other.dayOfWeek == this.dayOfWeek &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.active == this.active);
}

class TimetableEntriesCompanion extends UpdateCompanion<TimetableEntry> {
  final Value<int> id;
  final Value<int> subjectId;
  final Value<int?> venueId;
  final Value<int> dayOfWeek;
  final Value<String> startTime;
  final Value<String> endTime;
  final Value<bool> active;
  const TimetableEntriesCompanion({
    this.id = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.venueId = const Value.absent(),
    this.dayOfWeek = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.active = const Value.absent(),
  });
  TimetableEntriesCompanion.insert({
    this.id = const Value.absent(),
    required int subjectId,
    this.venueId = const Value.absent(),
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    this.active = const Value.absent(),
  }) : subjectId = Value(subjectId),
       dayOfWeek = Value(dayOfWeek),
       startTime = Value(startTime),
       endTime = Value(endTime);
  static Insertable<TimetableEntry> custom({
    Expression<int>? id,
    Expression<int>? subjectId,
    Expression<int>? venueId,
    Expression<int>? dayOfWeek,
    Expression<String>? startTime,
    Expression<String>? endTime,
    Expression<bool>? active,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (subjectId != null) 'subject_id': subjectId,
      if (venueId != null) 'venue_id': venueId,
      if (dayOfWeek != null) 'day_of_week': dayOfWeek,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (active != null) 'active': active,
    });
  }

  TimetableEntriesCompanion copyWith({
    Value<int>? id,
    Value<int>? subjectId,
    Value<int?>? venueId,
    Value<int>? dayOfWeek,
    Value<String>? startTime,
    Value<String>? endTime,
    Value<bool>? active,
  }) {
    return TimetableEntriesCompanion(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      venueId: venueId ?? this.venueId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      active: active ?? this.active,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<int>(subjectId.value);
    }
    if (venueId.present) {
      map['venue_id'] = Variable<int>(venueId.value);
    }
    if (dayOfWeek.present) {
      map['day_of_week'] = Variable<int>(dayOfWeek.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<String>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<String>(endTime.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimetableEntriesCompanion(')
          ..write('id: $id, ')
          ..write('subjectId: $subjectId, ')
          ..write('venueId: $venueId, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }
}

class $AttendanceRecordsTable extends AttendanceRecords
    with TableInfo<$AttendanceRecordsTable, AttendanceRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttendanceRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _timetableEntryIdMeta = const VerificationMeta(
    'timetableEntryId',
  );
  @override
  late final GeneratedColumn<int> timetableEntryId = GeneratedColumn<int>(
    'timetable_entry_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES timetable_entries (id)',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _confidenceScoreMeta = const VerificationMeta(
    'confidenceScore',
  );
  @override
  late final GeneratedColumn<double> confidenceScore = GeneratedColumn<double>(
    'confidence_score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _checksJsonMeta = const VerificationMeta(
    'checksJson',
  );
  @override
  late final GeneratedColumn<String> checksJson = GeneratedColumn<String>(
    'checks_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _overrideReasonMeta = const VerificationMeta(
    'overrideReason',
  );
  @override
  late final GeneratedColumn<String> overrideReason = GeneratedColumn<String>(
    'override_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    timetableEntryId,
    date,
    status,
    confidenceScore,
    checksJson,
    overrideReason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attendance_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttendanceRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('timetable_entry_id')) {
      context.handle(
        _timetableEntryIdMeta,
        timetableEntryId.isAcceptableOrUnknown(
          data['timetable_entry_id']!,
          _timetableEntryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timetableEntryIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('confidence_score')) {
      context.handle(
        _confidenceScoreMeta,
        confidenceScore.isAcceptableOrUnknown(
          data['confidence_score']!,
          _confidenceScoreMeta,
        ),
      );
    }
    if (data.containsKey('checks_json')) {
      context.handle(
        _checksJsonMeta,
        checksJson.isAcceptableOrUnknown(data['checks_json']!, _checksJsonMeta),
      );
    }
    if (data.containsKey('override_reason')) {
      context.handle(
        _overrideReasonMeta,
        overrideReason.isAcceptableOrUnknown(
          data['override_reason']!,
          _overrideReasonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttendanceRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttendanceRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      timetableEntryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timetable_entry_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      confidenceScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence_score'],
      )!,
      checksJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checks_json'],
      )!,
      overrideReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}override_reason'],
      ),
    );
  }

  @override
  $AttendanceRecordsTable createAlias(String alias) {
    return $AttendanceRecordsTable(attachedDatabase, alias);
  }
}

class AttendanceRecord extends DataClass
    implements Insertable<AttendanceRecord> {
  final int id;
  final int timetableEntryId;
  final DateTime date;
  final String status;
  final double confidenceScore;
  final String checksJson;
  final String? overrideReason;
  const AttendanceRecord({
    required this.id,
    required this.timetableEntryId,
    required this.date,
    required this.status,
    required this.confidenceScore,
    required this.checksJson,
    this.overrideReason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['timetable_entry_id'] = Variable<int>(timetableEntryId);
    map['date'] = Variable<DateTime>(date);
    map['status'] = Variable<String>(status);
    map['confidence_score'] = Variable<double>(confidenceScore);
    map['checks_json'] = Variable<String>(checksJson);
    if (!nullToAbsent || overrideReason != null) {
      map['override_reason'] = Variable<String>(overrideReason);
    }
    return map;
  }

  AttendanceRecordsCompanion toCompanion(bool nullToAbsent) {
    return AttendanceRecordsCompanion(
      id: Value(id),
      timetableEntryId: Value(timetableEntryId),
      date: Value(date),
      status: Value(status),
      confidenceScore: Value(confidenceScore),
      checksJson: Value(checksJson),
      overrideReason: overrideReason == null && nullToAbsent
          ? const Value.absent()
          : Value(overrideReason),
    );
  }

  factory AttendanceRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttendanceRecord(
      id: serializer.fromJson<int>(json['id']),
      timetableEntryId: serializer.fromJson<int>(json['timetableEntryId']),
      date: serializer.fromJson<DateTime>(json['date']),
      status: serializer.fromJson<String>(json['status']),
      confidenceScore: serializer.fromJson<double>(json['confidenceScore']),
      checksJson: serializer.fromJson<String>(json['checksJson']),
      overrideReason: serializer.fromJson<String?>(json['overrideReason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'timetableEntryId': serializer.toJson<int>(timetableEntryId),
      'date': serializer.toJson<DateTime>(date),
      'status': serializer.toJson<String>(status),
      'confidenceScore': serializer.toJson<double>(confidenceScore),
      'checksJson': serializer.toJson<String>(checksJson),
      'overrideReason': serializer.toJson<String?>(overrideReason),
    };
  }

  AttendanceRecord copyWith({
    int? id,
    int? timetableEntryId,
    DateTime? date,
    String? status,
    double? confidenceScore,
    String? checksJson,
    Value<String?> overrideReason = const Value.absent(),
  }) => AttendanceRecord(
    id: id ?? this.id,
    timetableEntryId: timetableEntryId ?? this.timetableEntryId,
    date: date ?? this.date,
    status: status ?? this.status,
    confidenceScore: confidenceScore ?? this.confidenceScore,
    checksJson: checksJson ?? this.checksJson,
    overrideReason: overrideReason.present
        ? overrideReason.value
        : this.overrideReason,
  );
  AttendanceRecord copyWithCompanion(AttendanceRecordsCompanion data) {
    return AttendanceRecord(
      id: data.id.present ? data.id.value : this.id,
      timetableEntryId: data.timetableEntryId.present
          ? data.timetableEntryId.value
          : this.timetableEntryId,
      date: data.date.present ? data.date.value : this.date,
      status: data.status.present ? data.status.value : this.status,
      confidenceScore: data.confidenceScore.present
          ? data.confidenceScore.value
          : this.confidenceScore,
      checksJson: data.checksJson.present
          ? data.checksJson.value
          : this.checksJson,
      overrideReason: data.overrideReason.present
          ? data.overrideReason.value
          : this.overrideReason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceRecord(')
          ..write('id: $id, ')
          ..write('timetableEntryId: $timetableEntryId, ')
          ..write('date: $date, ')
          ..write('status: $status, ')
          ..write('confidenceScore: $confidenceScore, ')
          ..write('checksJson: $checksJson, ')
          ..write('overrideReason: $overrideReason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    timetableEntryId,
    date,
    status,
    confidenceScore,
    checksJson,
    overrideReason,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttendanceRecord &&
          other.id == this.id &&
          other.timetableEntryId == this.timetableEntryId &&
          other.date == this.date &&
          other.status == this.status &&
          other.confidenceScore == this.confidenceScore &&
          other.checksJson == this.checksJson &&
          other.overrideReason == this.overrideReason);
}

class AttendanceRecordsCompanion extends UpdateCompanion<AttendanceRecord> {
  final Value<int> id;
  final Value<int> timetableEntryId;
  final Value<DateTime> date;
  final Value<String> status;
  final Value<double> confidenceScore;
  final Value<String> checksJson;
  final Value<String?> overrideReason;
  const AttendanceRecordsCompanion({
    this.id = const Value.absent(),
    this.timetableEntryId = const Value.absent(),
    this.date = const Value.absent(),
    this.status = const Value.absent(),
    this.confidenceScore = const Value.absent(),
    this.checksJson = const Value.absent(),
    this.overrideReason = const Value.absent(),
  });
  AttendanceRecordsCompanion.insert({
    this.id = const Value.absent(),
    required int timetableEntryId,
    required DateTime date,
    required String status,
    this.confidenceScore = const Value.absent(),
    this.checksJson = const Value.absent(),
    this.overrideReason = const Value.absent(),
  }) : timetableEntryId = Value(timetableEntryId),
       date = Value(date),
       status = Value(status);
  static Insertable<AttendanceRecord> custom({
    Expression<int>? id,
    Expression<int>? timetableEntryId,
    Expression<DateTime>? date,
    Expression<String>? status,
    Expression<double>? confidenceScore,
    Expression<String>? checksJson,
    Expression<String>? overrideReason,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timetableEntryId != null) 'timetable_entry_id': timetableEntryId,
      if (date != null) 'date': date,
      if (status != null) 'status': status,
      if (confidenceScore != null) 'confidence_score': confidenceScore,
      if (checksJson != null) 'checks_json': checksJson,
      if (overrideReason != null) 'override_reason': overrideReason,
    });
  }

  AttendanceRecordsCompanion copyWith({
    Value<int>? id,
    Value<int>? timetableEntryId,
    Value<DateTime>? date,
    Value<String>? status,
    Value<double>? confidenceScore,
    Value<String>? checksJson,
    Value<String?>? overrideReason,
  }) {
    return AttendanceRecordsCompanion(
      id: id ?? this.id,
      timetableEntryId: timetableEntryId ?? this.timetableEntryId,
      date: date ?? this.date,
      status: status ?? this.status,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      checksJson: checksJson ?? this.checksJson,
      overrideReason: overrideReason ?? this.overrideReason,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (timetableEntryId.present) {
      map['timetable_entry_id'] = Variable<int>(timetableEntryId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (confidenceScore.present) {
      map['confidence_score'] = Variable<double>(confidenceScore.value);
    }
    if (checksJson.present) {
      map['checks_json'] = Variable<String>(checksJson.value);
    }
    if (overrideReason.present) {
      map['override_reason'] = Variable<String>(overrideReason.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceRecordsCompanion(')
          ..write('id: $id, ')
          ..write('timetableEntryId: $timetableEntryId, ')
          ..write('date: $date, ')
          ..write('status: $status, ')
          ..write('confidenceScore: $confidenceScore, ')
          ..write('checksJson: $checksJson, ')
          ..write('overrideReason: $overrideReason')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SubjectsTable subjects = $SubjectsTable(this);
  late final $VenuesTable venues = $VenuesTable(this);
  late final $TimetableEntriesTable timetableEntries = $TimetableEntriesTable(
    this,
  );
  late final $AttendanceRecordsTable attendanceRecords =
      $AttendanceRecordsTable(this);
  late final SubjectsDao subjectsDao = SubjectsDao(this as AppDatabase);
  late final VenuesDao venuesDao = VenuesDao(this as AppDatabase);
  late final TimetableEntriesDao timetableEntriesDao = TimetableEntriesDao(
    this as AppDatabase,
  );
  late final AttendanceRecordsDao attendanceRecordsDao = AttendanceRecordsDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    subjects,
    venues,
    timetableEntries,
    attendanceRecords,
  ];
}

typedef $$SubjectsTableCreateCompanionBuilder = SubjectsCompanion Function({
  Value<int> id,
  required String name,
  required int color,
  Value<double> targetAttendancePct,
  Value<String?> facultyName,
});
typedef $$SubjectsTableUpdateCompanionBuilder = SubjectsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> color,
  Value<double> targetAttendancePct,
  Value<String?> facultyName,
});

final class $$SubjectsTableReferences
    extends BaseReferences<_$AppDatabase, $SubjectsTable, Subject> {
  $$SubjectsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TimetableEntriesTable, List<TimetableEntry>>
  _timetableEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.timetableEntries,
    aliasName: 'subjects__id__timetable_entries__subject_id',
  );

  $$TimetableEntriesTableProcessedTableManager get timetableEntriesRefs {
    final manager = $$TimetableEntriesTableTableManager(
      $_db,
      $_db.timetableEntries,
    ).filter((f) => f.subjectId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _timetableEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SubjectsTableFilterComposer
    extends Composer<_$AppDatabase, $SubjectsTable> {
  $$SubjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetAttendancePct => $composableBuilder(
    column: $table.targetAttendancePct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get facultyName => $composableBuilder(
    column: $table.facultyName,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> timetableEntriesRefs(
    Expression<bool> Function($$TimetableEntriesTableFilterComposer f) f,
  ) {
    final $$TimetableEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.timetableEntries,
      getReferencedColumn: (t) => t.subjectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimetableEntriesTableFilterComposer(
            $db: $db,
            $table: $db.timetableEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SubjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $SubjectsTable> {
  $$SubjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetAttendancePct => $composableBuilder(
    column: $table.targetAttendancePct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get facultyName => $composableBuilder(
    column: $table.facultyName,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SubjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubjectsTable> {
  $$SubjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<double> get targetAttendancePct => $composableBuilder(
    column: $table.targetAttendancePct,
    builder: (column) => column,
  );

  GeneratedColumn<String> get facultyName => $composableBuilder(
    column: $table.facultyName,
    builder: (column) => column,
  );

  Expression<T> timetableEntriesRefs<T extends Object>(
    Expression<T> Function($$TimetableEntriesTableAnnotationComposer a) f,
  ) {
    final $$TimetableEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.timetableEntries,
      getReferencedColumn: (t) => t.subjectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimetableEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.timetableEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SubjectsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SubjectsTable,
          Subject,
          $$SubjectsTableFilterComposer,
          $$SubjectsTableOrderingComposer,
          $$SubjectsTableAnnotationComposer,
          $$SubjectsTableCreateCompanionBuilder,
          $$SubjectsTableUpdateCompanionBuilder,
          (Subject, $$SubjectsTableReferences),
          Subject,
          PrefetchHooks Function({bool timetableEntriesRefs})
        > {
  $$SubjectsTableTableManager(_$AppDatabase db, $SubjectsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<double> targetAttendancePct = const Value.absent(),
                Value<String?> facultyName = const Value.absent(),
              }) => SubjectsCompanion(
                id: id,
                name: name,
                color: color,
                targetAttendancePct: targetAttendancePct,
                facultyName: facultyName,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int color,
                Value<double> targetAttendancePct = const Value.absent(),
                Value<String?> facultyName = const Value.absent(),
              }) => SubjectsCompanion.insert(
                id: id,
                name: name,
                color: color,
                targetAttendancePct: targetAttendancePct,
                facultyName: facultyName,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SubjectsTable, Subject>(table),
                  $$SubjectsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({timetableEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (timetableEntriesRefs) db.timetableEntries,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (timetableEntriesRefs)
                    await $_getPrefetchedData<
                      Subject,
                      $SubjectsTable,
                      TimetableEntry
                    >(
                      currentTable: table,
                      referencedTable: $$SubjectsTableReferences
                          ._timetableEntriesRefsTable(db),
                      managerFromTypedResult: (p0) => $$SubjectsTableReferences(
                        db,
                        table,
                        p0,
                      ).timetableEntriesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.subjectId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SubjectsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SubjectsTable,
      Subject,
      $$SubjectsTableFilterComposer,
      $$SubjectsTableOrderingComposer,
      $$SubjectsTableAnnotationComposer,
      $$SubjectsTableCreateCompanionBuilder,
      $$SubjectsTableUpdateCompanionBuilder,
      (Subject, $$SubjectsTableReferences),
      Subject,
      PrefetchHooks Function({bool timetableEntriesRefs})
    >;
typedef $$VenuesTableCreateCompanionBuilder = VenuesCompanion Function({
  Value<int> id,
  required String name,
  required double latitude,
  required double longitude,
  Value<double> radiusMeters,
  Value<String?> wifiSsid,
});
typedef $$VenuesTableUpdateCompanionBuilder = VenuesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<double> latitude,
  Value<double> longitude,
  Value<double> radiusMeters,
  Value<String?> wifiSsid,
});

final class $$VenuesTableReferences
    extends BaseReferences<_$AppDatabase, $VenuesTable, Venue> {
  $$VenuesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TimetableEntriesTable, List<TimetableEntry>>
  _timetableEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.timetableEntries,
    aliasName: 'venues__id__timetable_entries__venue_id',
  );

  $$TimetableEntriesTableProcessedTableManager get timetableEntriesRefs {
    final manager = $$TimetableEntriesTableTableManager(
      $_db,
      $_db.timetableEntries,
    ).filter((f) => f.venueId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _timetableEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$VenuesTableFilterComposer
    extends Composer<_$AppDatabase, $VenuesTable> {
  $$VenuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get radiusMeters => $composableBuilder(
    column: $table.radiusMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get wifiSsid => $composableBuilder(
    column: $table.wifiSsid,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> timetableEntriesRefs(
    Expression<bool> Function($$TimetableEntriesTableFilterComposer f) f,
  ) {
    final $$TimetableEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.timetableEntries,
      getReferencedColumn: (t) => t.venueId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimetableEntriesTableFilterComposer(
            $db: $db,
            $table: $db.timetableEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VenuesTableOrderingComposer
    extends Composer<_$AppDatabase, $VenuesTable> {
  $$VenuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get radiusMeters => $composableBuilder(
    column: $table.radiusMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wifiSsid => $composableBuilder(
    column: $table.wifiSsid,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VenuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VenuesTable> {
  $$VenuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get radiusMeters => $composableBuilder(
    column: $table.radiusMeters,
    builder: (column) => column,
  );

  GeneratedColumn<String> get wifiSsid =>
      $composableBuilder(column: $table.wifiSsid, builder: (column) => column);

  Expression<T> timetableEntriesRefs<T extends Object>(
    Expression<T> Function($$TimetableEntriesTableAnnotationComposer a) f,
  ) {
    final $$TimetableEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.timetableEntries,
      getReferencedColumn: (t) => t.venueId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimetableEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.timetableEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VenuesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VenuesTable,
          Venue,
          $$VenuesTableFilterComposer,
          $$VenuesTableOrderingComposer,
          $$VenuesTableAnnotationComposer,
          $$VenuesTableCreateCompanionBuilder,
          $$VenuesTableUpdateCompanionBuilder,
          (Venue, $$VenuesTableReferences),
          Venue,
          PrefetchHooks Function({bool timetableEntriesRefs})
        > {
  $$VenuesTableTableManager(_$AppDatabase db, $VenuesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VenuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VenuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VenuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<double> radiusMeters = const Value.absent(),
                Value<String?> wifiSsid = const Value.absent(),
              }) => VenuesCompanion(
                id: id,
                name: name,
                latitude: latitude,
                longitude: longitude,
                radiusMeters: radiusMeters,
                wifiSsid: wifiSsid,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required double latitude,
                required double longitude,
                Value<double> radiusMeters = const Value.absent(),
                Value<String?> wifiSsid = const Value.absent(),
              }) => VenuesCompanion.insert(
                id: id,
                name: name,
                latitude: latitude,
                longitude: longitude,
                radiusMeters: radiusMeters,
                wifiSsid: wifiSsid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VenuesTable, Venue>(table),
                  $$VenuesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({timetableEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (timetableEntriesRefs) db.timetableEntries,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (timetableEntriesRefs)
                    await $_getPrefetchedData<
                      Venue,
                      $VenuesTable,
                      TimetableEntry
                    >(
                      currentTable: table,
                      referencedTable: $$VenuesTableReferences
                          ._timetableEntriesRefsTable(db),
                      managerFromTypedResult: (p0) => $$VenuesTableReferences(
                        db,
                        table,
                        p0,
                      ).timetableEntriesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.venueId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$VenuesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VenuesTable,
      Venue,
      $$VenuesTableFilterComposer,
      $$VenuesTableOrderingComposer,
      $$VenuesTableAnnotationComposer,
      $$VenuesTableCreateCompanionBuilder,
      $$VenuesTableUpdateCompanionBuilder,
      (Venue, $$VenuesTableReferences),
      Venue,
      PrefetchHooks Function({bool timetableEntriesRefs})
    >;
typedef $$TimetableEntriesTableCreateCompanionBuilder =
    TimetableEntriesCompanion Function({
      Value<int> id,
      required int subjectId,
      Value<int?> venueId,
      required int dayOfWeek,
      required String startTime,
      required String endTime,
      Value<bool> active,
    });
typedef $$TimetableEntriesTableUpdateCompanionBuilder =
    TimetableEntriesCompanion Function({
      Value<int> id,
      Value<int> subjectId,
      Value<int?> venueId,
      Value<int> dayOfWeek,
      Value<String> startTime,
      Value<String> endTime,
      Value<bool> active,
    });

final class $$TimetableEntriesTableReferences
    extends
        BaseReferences<_$AppDatabase, $TimetableEntriesTable, TimetableEntry> {
  $$TimetableEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SubjectsTable _subjectIdTable(_$AppDatabase db) =>
      db.subjects.createAlias('timetable_entries__subject_id__subjects__id');

  $$SubjectsTableProcessedTableManager get subjectId {
    final $_column = $_itemColumn<int>('subject_id')!;

    final manager = $$SubjectsTableTableManager(
      $_db,
      $_db.subjects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_subjectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $VenuesTable _venueIdTable(_$AppDatabase db) =>
      db.venues.createAlias('timetable_entries__venue_id__venues__id');

  $$VenuesTableProcessedTableManager? get venueId {
    final $_column = $_itemColumn<int>('venue_id');
    if ($_column == null) return null;
    final manager = $$VenuesTableTableManager(
      $_db,
      $_db.venues,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_venueIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$AttendanceRecordsTable, List<AttendanceRecord>>
  _attendanceRecordsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.attendanceRecords,
        aliasName:
            'timetable_entries__id__attendance_records__timetable_entry_id',
      );

  $$AttendanceRecordsTableProcessedTableManager get attendanceRecordsRefs {
    final manager = $$AttendanceRecordsTableTableManager(
      $_db,
      $_db.attendanceRecords,
    ).filter((f) => f.timetableEntryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _attendanceRecordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TimetableEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $TimetableEntriesTable> {
  $$TimetableEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayOfWeek => $composableBuilder(
    column: $table.dayOfWeek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  $$SubjectsTableFilterComposer get subjectId {
    final $$SubjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableFilterComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VenuesTableFilterComposer get venueId {
    final $$VenuesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.venueId,
      referencedTable: $db.venues,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VenuesTableFilterComposer(
            $db: $db,
            $table: $db.venues,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> attendanceRecordsRefs(
    Expression<bool> Function($$AttendanceRecordsTableFilterComposer f) f,
  ) {
    final $$AttendanceRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attendanceRecords,
      getReferencedColumn: (t) => t.timetableEntryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttendanceRecordsTableFilterComposer(
            $db: $db,
            $table: $db.attendanceRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TimetableEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $TimetableEntriesTable> {
  $$TimetableEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayOfWeek => $composableBuilder(
    column: $table.dayOfWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  $$SubjectsTableOrderingComposer get subjectId {
    final $$SubjectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableOrderingComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VenuesTableOrderingComposer get venueId {
    final $$VenuesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.venueId,
      referencedTable: $db.venues,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VenuesTableOrderingComposer(
            $db: $db,
            $table: $db.venues,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TimetableEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TimetableEntriesTable> {
  $$TimetableEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dayOfWeek =>
      $composableBuilder(column: $table.dayOfWeek, builder: (column) => column);

  GeneratedColumn<String> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<String> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  $$SubjectsTableAnnotationComposer get subjectId {
    final $$SubjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VenuesTableAnnotationComposer get venueId {
    final $$VenuesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.venueId,
      referencedTable: $db.venues,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VenuesTableAnnotationComposer(
            $db: $db,
            $table: $db.venues,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> attendanceRecordsRefs<T extends Object>(
    Expression<T> Function($$AttendanceRecordsTableAnnotationComposer a) f,
  ) {
    final $$AttendanceRecordsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.attendanceRecords,
          getReferencedColumn: (t) => t.timetableEntryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AttendanceRecordsTableAnnotationComposer(
                $db: $db,
                $table: $db.attendanceRecords,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$TimetableEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TimetableEntriesTable,
          TimetableEntry,
          $$TimetableEntriesTableFilterComposer,
          $$TimetableEntriesTableOrderingComposer,
          $$TimetableEntriesTableAnnotationComposer,
          $$TimetableEntriesTableCreateCompanionBuilder,
          $$TimetableEntriesTableUpdateCompanionBuilder,
          (TimetableEntry, $$TimetableEntriesTableReferences),
          TimetableEntry,
          PrefetchHooks Function({
            bool subjectId,
            bool venueId,
            bool attendanceRecordsRefs,
          })
        > {
  $$TimetableEntriesTableTableManager(
    _$AppDatabase db,
    $TimetableEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimetableEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TimetableEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TimetableEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> subjectId = const Value.absent(),
                Value<int?> venueId = const Value.absent(),
                Value<int> dayOfWeek = const Value.absent(),
                Value<String> startTime = const Value.absent(),
                Value<String> endTime = const Value.absent(),
                Value<bool> active = const Value.absent(),
              }) => TimetableEntriesCompanion(
                id: id,
                subjectId: subjectId,
                venueId: venueId,
                dayOfWeek: dayOfWeek,
                startTime: startTime,
                endTime: endTime,
                active: active,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int subjectId,
                Value<int?> venueId = const Value.absent(),
                required int dayOfWeek,
                required String startTime,
                required String endTime,
                Value<bool> active = const Value.absent(),
              }) => TimetableEntriesCompanion.insert(
                id: id,
                subjectId: subjectId,
                venueId: venueId,
                dayOfWeek: dayOfWeek,
                startTime: startTime,
                endTime: endTime,
                active: active,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TimetableEntriesTable, TimetableEntry>(table),
                  $$TimetableEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                subjectId = false,
                venueId = false,
                attendanceRecordsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (attendanceRecordsRefs) db.attendanceRecords,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (subjectId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.subjectId,
                            referencedTable: $$TimetableEntriesTableReferences
                                ._subjectIdTable(db),
                            referencedColumn: $$TimetableEntriesTableReferences
                                ._subjectIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (venueId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.venueId,
                            referencedTable: $$TimetableEntriesTableReferences
                                ._venueIdTable(db),
                            referencedColumn: $$TimetableEntriesTableReferences
                                ._venueIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (attendanceRecordsRefs)
                        await $_getPrefetchedData<
                          TimetableEntry,
                          $TimetableEntriesTable,
                          AttendanceRecord
                        >(
                          currentTable: table,
                          referencedTable: $$TimetableEntriesTableReferences
                              ._attendanceRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TimetableEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).attendanceRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.timetableEntryId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TimetableEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TimetableEntriesTable,
      TimetableEntry,
      $$TimetableEntriesTableFilterComposer,
      $$TimetableEntriesTableOrderingComposer,
      $$TimetableEntriesTableAnnotationComposer,
      $$TimetableEntriesTableCreateCompanionBuilder,
      $$TimetableEntriesTableUpdateCompanionBuilder,
      (TimetableEntry, $$TimetableEntriesTableReferences),
      TimetableEntry,
      PrefetchHooks Function({
        bool subjectId,
        bool venueId,
        bool attendanceRecordsRefs,
      })
    >;
typedef $$AttendanceRecordsTableCreateCompanionBuilder =
    AttendanceRecordsCompanion Function({
      Value<int> id,
      required int timetableEntryId,
      required DateTime date,
      required String status,
      Value<double> confidenceScore,
      Value<String> checksJson,
      Value<String?> overrideReason,
    });
typedef $$AttendanceRecordsTableUpdateCompanionBuilder =
    AttendanceRecordsCompanion Function({
      Value<int> id,
      Value<int> timetableEntryId,
      Value<DateTime> date,
      Value<String> status,
      Value<double> confidenceScore,
      Value<String> checksJson,
      Value<String?> overrideReason,
    });

final class $$AttendanceRecordsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $AttendanceRecordsTable,
          AttendanceRecord
        > {
  $$AttendanceRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TimetableEntriesTable _timetableEntryIdTable(_$AppDatabase db) =>
      db.timetableEntries.createAlias(
        'attendance_records__timetable_entry_id__timetable_entries__id',
      );

  $$TimetableEntriesTableProcessedTableManager get timetableEntryId {
    final $_column = $_itemColumn<int>('timetable_entry_id')!;

    final manager = $$TimetableEntriesTableTableManager(
      $_db,
      $_db.timetableEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_timetableEntryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AttendanceRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $AttendanceRecordsTable> {
  $$AttendanceRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidenceScore => $composableBuilder(
    column: $table.confidenceScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checksJson => $composableBuilder(
    column: $table.checksJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overrideReason => $composableBuilder(
    column: $table.overrideReason,
    builder: (column) => ColumnFilters(column),
  );

  $$TimetableEntriesTableFilterComposer get timetableEntryId {
    final $$TimetableEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.timetableEntryId,
      referencedTable: $db.timetableEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimetableEntriesTableFilterComposer(
            $db: $db,
            $table: $db.timetableEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttendanceRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttendanceRecordsTable> {
  $$AttendanceRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidenceScore => $composableBuilder(
    column: $table.confidenceScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checksJson => $composableBuilder(
    column: $table.checksJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overrideReason => $composableBuilder(
    column: $table.overrideReason,
    builder: (column) => ColumnOrderings(column),
  );

  $$TimetableEntriesTableOrderingComposer get timetableEntryId {
    final $$TimetableEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.timetableEntryId,
      referencedTable: $db.timetableEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimetableEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.timetableEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttendanceRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttendanceRecordsTable> {
  $$AttendanceRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get confidenceScore => $composableBuilder(
    column: $table.confidenceScore,
    builder: (column) => column,
  );

  GeneratedColumn<String> get checksJson => $composableBuilder(
    column: $table.checksJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get overrideReason => $composableBuilder(
    column: $table.overrideReason,
    builder: (column) => column,
  );

  $$TimetableEntriesTableAnnotationComposer get timetableEntryId {
    final $$TimetableEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.timetableEntryId,
      referencedTable: $db.timetableEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimetableEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.timetableEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttendanceRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttendanceRecordsTable,
          AttendanceRecord,
          $$AttendanceRecordsTableFilterComposer,
          $$AttendanceRecordsTableOrderingComposer,
          $$AttendanceRecordsTableAnnotationComposer,
          $$AttendanceRecordsTableCreateCompanionBuilder,
          $$AttendanceRecordsTableUpdateCompanionBuilder,
          (AttendanceRecord, $$AttendanceRecordsTableReferences),
          AttendanceRecord,
          PrefetchHooks Function({bool timetableEntryId})
        > {
  $$AttendanceRecordsTableTableManager(
    _$AppDatabase db,
    $AttendanceRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttendanceRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttendanceRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttendanceRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> timetableEntryId = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<double> confidenceScore = const Value.absent(),
                Value<String> checksJson = const Value.absent(),
                Value<String?> overrideReason = const Value.absent(),
              }) => AttendanceRecordsCompanion(
                id: id,
                timetableEntryId: timetableEntryId,
                date: date,
                status: status,
                confidenceScore: confidenceScore,
                checksJson: checksJson,
                overrideReason: overrideReason,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int timetableEntryId,
                required DateTime date,
                required String status,
                Value<double> confidenceScore = const Value.absent(),
                Value<String> checksJson = const Value.absent(),
                Value<String?> overrideReason = const Value.absent(),
              }) => AttendanceRecordsCompanion.insert(
                id: id,
                timetableEntryId: timetableEntryId,
                date: date,
                status: status,
                confidenceScore: confidenceScore,
                checksJson: checksJson,
                overrideReason: overrideReason,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AttendanceRecordsTable, AttendanceRecord>(table),
                  $$AttendanceRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({timetableEntryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (timetableEntryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.timetableEntryId,
                        referencedTable: $$AttendanceRecordsTableReferences
                            ._timetableEntryIdTable(db),
                        referencedColumn: $$AttendanceRecordsTableReferences
                            ._timetableEntryIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AttendanceRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttendanceRecordsTable,
      AttendanceRecord,
      $$AttendanceRecordsTableFilterComposer,
      $$AttendanceRecordsTableOrderingComposer,
      $$AttendanceRecordsTableAnnotationComposer,
      $$AttendanceRecordsTableCreateCompanionBuilder,
      $$AttendanceRecordsTableUpdateCompanionBuilder,
      (AttendanceRecord, $$AttendanceRecordsTableReferences),
      AttendanceRecord,
      PrefetchHooks Function({bool timetableEntryId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SubjectsTableTableManager get subjects =>
      $$SubjectsTableTableManager(_db, _db.subjects);
  $$VenuesTableTableManager get venues =>
      $$VenuesTableTableManager(_db, _db.venues);
  $$TimetableEntriesTableTableManager get timetableEntries =>
      $$TimetableEntriesTableTableManager(_db, _db.timetableEntries);
  $$AttendanceRecordsTableTableManager get attendanceRecords =>
      $$AttendanceRecordsTableTableManager(_db, _db.attendanceRecords);
}
