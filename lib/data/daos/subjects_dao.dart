import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'subjects_dao.g.dart';

/// DAO for CRUD operations on the Subjects table.
@DriftAccessor(tables: [Subjects])
class SubjectsDao extends DatabaseAccessor<AppDatabase>
    with _$SubjectsDaoMixin {
  SubjectsDao(super.db);

  /// Get all subjects as a reactive stream.
  Stream<List<Subject>> watchAllSubjects() => select(subjects).watch();

  /// Get all subjects (one-shot).
  Future<List<Subject>> getAllSubjects() => select(subjects).get();

  /// Get a single subject by ID.
  Future<Subject> getSubjectById(int id) =>
      (select(subjects)..where((s) => s.id.equals(id))).getSingle();

  /// Insert a new subject, returns the generated ID.
  Future<int> insertSubject(SubjectsCompanion subject) =>
      into(subjects).insert(subject);

  /// Update an existing subject.
  Future<bool> updateSubject(Subject subject) => update(subjects).replace(subject);

  /// Delete a subject by ID.
  Future<int> deleteSubjectById(int id) =>
      (delete(subjects)..where((s) => s.id.equals(id))).go();
}
