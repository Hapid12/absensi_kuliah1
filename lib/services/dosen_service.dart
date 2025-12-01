import 'dart:async';
import '../models/announcement_model.dart';
import '../models/mahasiswa_model.dart';
import 'db_helper.dart';
import 'jadwal_service.dart';

class DosenService {
  /// Post announcement for a jadwal (returns inserted row id)
  static Future<int> postAnnouncement(
    String jadwalId,
    String title,
    String message, {
    String? subject,
  }) async {
    final createdAt = DateTime.now().toIso8601String();
    final Map<String, dynamic> payload = {
      'jadwalId': jadwalId,
      'mataKuliah': title ?? '',
      'subject': subject ?? '',
      'message': message ?? '',
      'createdAt': createdAt,
    };
    // DBHelper.insertAnnouncement expects a Map<String, dynamic>
    return await DBHelper.instance.insertAnnouncement(payload);
  }

  /// Get announcements for given dosen's jadwal ids
  static Future<List<Announcement>> getAnnouncementsForDosen(
    String dosenNip,
  ) async {
    final jadwals = await JadwalService.getJadwalByDosen(dosenNip);
    final List<Announcement> result = [];
    for (final j in jadwals) {
      final rows = await DBHelper.instance.getAnnouncementsForJadwal(j.id);
      for (final r in rows) {
        final idStr = (r['id']?.toString() ?? '');
        final createdAtStr = r['createdAt'] as String? ?? '';
        DateTime ts;
        try {
          ts = DateTime.parse(createdAtStr);
        } catch (_) {
          ts = DateTime.now();
        }

        result.add(
          Announcement(
            id: idStr,
            jadwalId: r['jadwalId']?.toString() ?? '',
            title: r['mataKuliah']?.toString() ?? '',
            message: r['message']?.toString() ?? '',
            timestamp: ts,
          ),
        );
      }
    }
    return result;
  }

  /// Toggle attendance for a jadwal and student npm
  static Future<void> toggleAttendance(String jadwalId, String npm) async {
    final jadwal = await JadwalService.getById(jadwalId);
    if (jadwal == null) return;
    if (!jadwal.peserta.contains(npm)) {
      return; // only enrolled students can be toggled
    }
    await DBHelper.instance.toggleAttendance(jadwalId, npm);
  }

  static Future<List<String>> getAttendance(String jadwalId) async {
    return await DBHelper.instance.getAttendance(jadwalId);
  }

  // Dosen presence methods
  static Future<bool> isDosenPresent(String jadwalId, String nip) async {
    return await DBHelper.instance.isDosenPresent(jadwalId, nip);
  }

  static Future<void> toggleDosenPresence(String jadwalId, String nip) async {
    await DBHelper.instance.toggleDosenAttendance(jadwalId, nip);
  }

  static Future<List<String>> getDosenPresenceList(String jadwalId) async {
    return await DBHelper.instance.getDosenAttendance(jadwalId);
  }

  // contoh in-memory data per jadwalId
  static final Map<String, List<Mahasiswa>> _data = {
    'A': [
      Mahasiswa(
        id: 'm1',
        npm: '202001',
        nama: 'Andi',
        status: 'Hadir',
        prodi: '',
      ),
      Mahasiswa(
        id: 'm2',
        npm: '202002',
        nama: 'Budi',
        status: 'Tidak Hadir',
        prodi: '',
      ),
      Mahasiswa(
        id: 'm3',
        npm: '202003',
        nama: 'Citra',
        status: 'Sakit',
        prodi: '',
      ),
    ],
    // tambahkan jadwal lain sesuai kebutuhan
  };

  // fetch mahasiswa peserta untuk jadwal
  static Future<List<Mahasiswa>> fetchMahasiswa(String jadwalId) async {
    await Future.delayed(const Duration(milliseconds: 400)); // simulasi network
    final list = _data[jadwalId] ?? [];
    // return copy agar tidak dimodifikasi langsung
    return list.map((e) => e.copyWith()).toList();
  }

  // update absensi mahasiswa
  static Future<void> updateAbsensi(
    String jadwalId,
    String mahasiswaId,
    String status,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final list = _data[jadwalId];
    if (list == null) return;
    final idx = list.indexWhere((e) => e.id == mahasiswaId);
    if (idx == -1) return;
    list[idx] = list[idx].copyWith(status: status);
  }

  // kirim pengumuman ke mahasiswa (simulasi)
  static Future<void> sendAnnouncement(String jadwalId, String message) async {
    // save to DB, use the jadwal title as title
    final j = await JadwalService.getById(jadwalId);
    final title = j?.mataKuliah ?? '';
    await postAnnouncement(jadwalId, title, message, subject: '');
    return;
  }
}
