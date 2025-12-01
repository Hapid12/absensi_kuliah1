// --- Move these methods inside DBHelper class below ---
import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../data/dummy_data.dart';
import '../models/jadwal_model.dart';

class DBHelper {
  // Add a broadcast stream to notify listeners about announcement changes
  final StreamController<void> _announcementsController =
      StreamController<void>.broadcast();

  // Provide external access to stream
  Stream<void> get announcementsStream => _announcementsController.stream;

  // internal helper to notify listeners
  void _notifyAnnouncementChanged() {
    try {
      _announcementsController.add(null);
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getAllMahasiswa() async {
    final db = await DBHelper.instance.database;
    return await db.query('mahasiswa');
  }

  Future<List<Map<String, dynamic>>> getAllDosen() async {
    final db = await DBHelper.instance.database;
    return await db.query('dosen');
  }

  Future<void> insertMahasiswa(Map<String, dynamic> m) async {
    final db = await DBHelper.instance.database;
    await db.insert('mahasiswa', m);
  }

  Future<void> updateMahasiswa(String npm, Map<String, dynamic> m) async {
    final db = await DBHelper.instance.database;
    await db.update('mahasiswa', m, where: 'npm = ?', whereArgs: [npm]);
  }

  Future<void> deleteMahasiswa(String npm) async {
    final db = await DBHelper.instance.database;
    await db.delete('mahasiswa', where: 'npm = ?', whereArgs: [npm]);
  }

  Future<void> insertDosen(Map<String, dynamic> d) async {
    final db = await DBHelper.instance.database;
    await db.insert('dosen', d);
  }

  Future<void> updateDosen(String nip, Map<String, dynamic> d) async {
    final db = await DBHelper.instance.database;
    await db.update('dosen', d, where: 'nip = ?', whereArgs: [nip]);
  }

  Future<void> deleteDosen(String nip) async {
    final db = await DBHelper.instance.database;
    await db.delete('dosen', where: 'nip = ?', whereArgs: [nip]);
  }

  static final DBHelper instance = DBHelper._init();

  DBHelper._init();

  Database? _database;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'absensi.db');
    _database = await openDatabase(path, version: 1, onCreate: _onCreate);
    // seed if empty
    await seedIfEmpty();
    return _database!;
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE mahasiswa(
        npm TEXT PRIMARY KEY,
        nama TEXT,
        prodi TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE dosen(
        nip TEXT PRIMARY KEY,
        nama TEXT,
        mataKuliah TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE jadwal(
        id TEXT PRIMARY KEY,
        mataKuliah TEXT,
        hari TEXT,
        jam TEXT,
        ruang TEXT,
        dosenNip TEXT,
        peserta TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE attendance(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        jadwalId TEXT,
        npm TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE dosen_attendance(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        jadwalId TEXT,
        nip TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE users(
        username TEXT,
        password TEXT,
        role TEXT,
        name TEXT,
        nip TEXT,
        npm TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS announcements(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        jadwalId TEXT,
        mataKuliah TEXT,
        subject TEXT,
        message TEXT,
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT,
        tableName TEXT,
        recordId TEXT,
        timestamp TEXT
      )
    ''');
  }

  // after database is opened/created, ensure announcements table exists in onCreate:
  Future<Database> _initDB(String filePath) async {
    final db = await openDatabase(
      filePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE mahasiswa(
            npm TEXT PRIMARY KEY,
            nama TEXT,
            prodi TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE dosen(
            nip TEXT PRIMARY KEY,
            nama TEXT,
            mataKuliah TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE jadwal(
            id TEXT PRIMARY KEY,
            mataKuliah TEXT,
            hari TEXT,
            jam TEXT,
            ruang TEXT,
            dosenNip TEXT,
            peserta TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE attendance(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            jadwalId TEXT,
            npm TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE dosen_attendance(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            jadwalId TEXT,
            nip TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE users(
            username TEXT,
            password TEXT,
            role TEXT,
            name TEXT,
            nip TEXT,
            npm TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS announcements(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            jadwalId TEXT,
            mataKuliah TEXT,
            subject TEXT,
            message TEXT,
            createdAt TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE logs(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            action TEXT,
            tableName TEXT,
            recordId TEXT,
            timestamp TEXT
          )
        ''');
      },
    );
    return db;
  }

  // Insert announcement
  Future<int> insertAnnouncement(Map<String, dynamic> data) async {
    final db = await database;
    final id = await db.insert(
      'announcements',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // notify listeners
    _notifyAnnouncementChanged();
    return id;
  }

  // Legacy/raw insert if needed - renamed to avoid duplicate method names
  Future<void> insertAnnouncementRaw(Map<String, dynamic> a) async {
    final db = await instance.database;
    await db.insert('announcements', a);
    _notifyAnnouncementChanged();
  }

  // get announcements by list of jadwal ids
  Future<List<Map<String, dynamic>>> getAnnouncementsByJadwalIds(
    List<String> ids,
  ) async {
    final db = await database;
    if (ids.isEmpty) return [];
    final placeholders = List.filled(ids.length, '?').join(',');
    final result = await db.rawQuery('''
      SELECT a.*, j.mataKuliah as mataKuliah
      FROM announcements a
      LEFT JOIN jadwal j ON j.id = a.jadwalId
      WHERE a.jadwalId IN ($placeholders)
      ORDER BY datetime(a.createdAt) DESC
    ''', ids);
    return result;
  }

  // Optionally: get all announcements (if needed)
  Future<List<Map<String, dynamic>>> getAllAnnouncements() async {
    final db = await database;
    final res = await db.query('announcements', orderBy: 'createdAt DESC');
    return res;
  }

  Future<void> seedIfEmpty() async {
    final db = await instance.database;

    final int mCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM mahasiswa'),
        ) ??
        0;

    if (mCount == 0) {
      // seed mahasiswa
      for (final m in DummyData.mahasiswaList) {
        await db.insert('mahasiswa', {
          'npm': m.npm,
          'nama': m.nama,
          'prodi': m.prodi,
        });
      }

      // seed dosen
      for (final d in DummyData.dosenList) {
        await db.insert('dosen', {
          'nip': d.nip,
          'nama': d.nama,
          'mataKuliah': d.mataKuliah,
        });
      }

      // seed jadwal (peserta as json)
      for (final j in DummyData.jadwalList) {
        await db.insert('jadwal', {
          'id': j.id,
          'mataKuliah': j.mataKuliah,
          'hari': j.hari,
          'jam': j.jam,
          'ruang': j.ruang,
          'dosenNip': j.dosenNip,
          'peserta': jsonEncode(j.peserta),
        });

        // seed attendance records
        final present = DummyData.attendanceRecords[j.id] ?? [];
        for (final npm in present) {
          await db.insert('attendance', {'jadwalId': j.id, 'npm': npm});
        }
      }

      // seed users
      for (final u in DummyData.users) {
        await db.insert('users', {
          'username': u.username,
          'password': u.password,
          'role': u.role,
          'name': u.name,
          'nip': u.nip,
          'npm': u.npm,
        });
      }

      // seed announcements
      for (final a in DummyData.announcements) {
        final createdAt = (a.timestamp is DateTime)
            ? (a.timestamp).toIso8601String()
            : DateTime.now().toIso8601String();
        await db.insert('announcements', {
          'id': a.id,
          'jadwalId': a.jadwalId,
          'mataKuliah': a.title ?? '',
          'message': a.message,
          'createdAt': createdAt,
        });
      }
    }
  }

  // Basic getters - more can be added as needed
  Future<List<Jadwal>> getAllJadwal() async {
    final db = await instance.database;
    final rows = await db.query('jadwal');
    return rows.map((r) {
      final pesertaJson = r['peserta'] as String?;
      final List<String> peserta = pesertaJson != null && pesertaJson.isNotEmpty
          ? List<String>.from(jsonDecode(pesertaJson))
          : <String>[];
      return Jadwal(
        id: r['id'] as String,
        mataKuliah: r['mataKuliah'] as String,
        hari: r['hari'] as String,
        jam: r['jam'] as String,
        ruang: r['ruang'] as String,
        dosenNip: r['dosenNip'] as String,
        peserta: peserta,
      );
    }).toList();
  }

  Future<void> insertJadwal(Jadwal j) async {
    final db = await instance.database;
    await db.insert('jadwal', {
      'id': j.id,
      'mataKuliah': j.mataKuliah,
      'hari': j.hari,
      'jam': j.jam,
      'ruang': j.ruang,
      'dosenNip': j.dosenNip,
      'peserta': jsonEncode(j.peserta),
    });
  }

  Future<void> updateJadwal(Jadwal j) async {
    final db = await instance.database;
    await db.update(
      'jadwal',
      {
        'mataKuliah': j.mataKuliah,
        'hari': j.hari,
        'jam': j.jam,
        'ruang': j.ruang,
        'dosenNip': j.dosenNip,
        'peserta': jsonEncode(j.peserta),
      },
      where: 'id = ?',
      whereArgs: [j.id],
    );
  }

  Future<void> deleteJadwal(String id) async {
    final db = await instance.database;
    await db.delete('jadwal', where: 'id = ?', whereArgs: [id]);
    await db.delete('attendance', where: 'jadwalId = ?', whereArgs: [id]);
    await db.delete('announcements', where: 'jadwalId = ?', whereArgs: [id]);
    _notifyAnnouncementChanged();
  }

  Future<bool> isPresent(String jadwalId, String npm) async {
    final db = await instance.database;
    final rows = await db.query(
      'attendance',
      where: 'jadwalId = ? AND npm = ?',
      whereArgs: [jadwalId, npm],
    );
    return rows.isNotEmpty;
  }

  Future<void> toggleAttendance(String jadwalId, String npm) async {
    final db = await instance.database;
    final exists = await isPresent(jadwalId, npm);
    if (exists) {
      await db.delete(
        'attendance',
        where: 'jadwalId = ? AND npm = ?',
        whereArgs: [jadwalId, npm],
      );
    } else {
      await db.insert('attendance', {'jadwalId': jadwalId, 'npm': npm});
    }
  }

  Future<List<String>> getAttendance(String jadwalId) async {
    final db = await instance.database;
    final rows = await db.query(
      'attendance',
      where: 'jadwalId = ?',
      whereArgs: [jadwalId],
    );
    return rows.map((r) => r['npm'] as String).toList();
  }

  // Dosen attendance (presence for the lecturer)
  Future<bool> isDosenPresent(String jadwalId, String nip) async {
    final db = await instance.database;
    final rows = await db.query(
      'dosen_attendance',
      where: 'jadwalId = ? AND nip = ?',
      whereArgs: [jadwalId, nip],
    );
    return rows.isNotEmpty;
  }

  Future<void> toggleDosenAttendance(String jadwalId, String nip) async {
    final db = await instance.database;
    final exists = await isDosenPresent(jadwalId, nip);
    if (exists) {
      await db.delete(
        'dosen_attendance',
        where: 'jadwalId = ? AND nip = ?',
        whereArgs: [jadwalId, nip],
      );
    } else {
      await db.insert('dosen_attendance', {'jadwalId': jadwalId, 'nip': nip});
    }
  }

  Future<List<String>> getDosenAttendance(String jadwalId) async {
    final db = await instance.database;
    final rows = await db.query(
      'dosen_attendance',
      where: 'jadwalId = ?',
      whereArgs: [jadwalId],
    );
    return rows.map((r) => r['nip'] as String).toList();
  }

  Future<Map<String, dynamic>?> getUserByCredential(
    String id,
    String password,
  ) async {
    final db = await instance.database;
    final rows = await db.query(
      'users',
      where: '(username = ? OR nip = ? OR npm = ?) AND password = ?',
      whereArgs: [id, id, id, password],
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<List<Map<String, dynamic>>> getAnnouncementsForJadwal(
    String jadwalId,
  ) async {
    final db = await instance.database;
    final rows = await db.query(
      'announcements',
      where: 'jadwalId = ?',
      whereArgs: [jadwalId],
      orderBy: 'createdAt DESC', // changed from timestamp
    );
    return rows;
  }

  Future<void> insertAnnouncementMap(Map<String, dynamic> a) async {
    final db = await instance.database;
    await db.insert('announcements', a);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
    try {
      await _announcementsController.close();
    } catch (_) {}
  }

  /// Development helper: delete the DB file and recreate + reseed from DummyData
  Future<void> resetDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'absensi.db');
    try {
      final db = _database;
      if (db != null && db.isOpen) await db.close();
    } catch (_) {}
    _database = null;
    await deleteDatabase(path);
    // Reopen and seed
    await database;
    await seedIfEmpty();
  }
}
