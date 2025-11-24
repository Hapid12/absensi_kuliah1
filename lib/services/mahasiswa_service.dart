import 'db_helper.dart';

class MahasiswaService {
  /// Student toggles their own attendance for a jadwal
  static Future<bool> markMyAttendance(String jadwalId, String npm) async {
    final present = await DBHelper.instance.isPresent(jadwalId, npm);
    await DBHelper.instance.toggleAttendance(jadwalId, npm);
    return !present;
  }

  static Future<List<String>> getMyAttendanceRecords(String npm) async {
    final db = await DBHelper.instance.database;
    final rows = await db.query('attendance', where: 'npm = ?', whereArgs: [npm]);
    return rows.map((r) => r['jadwalId'] as String).toList();
  }
}

