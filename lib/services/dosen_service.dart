import '../models/announcement_model.dart';
import 'db_helper.dart';
import 'jadwal_service.dart';

class DosenService {
	/// Post announcement for a jadwal
	static Future<void> postAnnouncement(String jadwalId, String title, String message) async {
		final id = 'A${DateTime.now().millisecondsSinceEpoch}';
		final a = {
			'id': id,
			'jadwalId': jadwalId,
			'title': title,
			'message': message,
			'timestamp': DateTime.now().millisecondsSinceEpoch,
		};
		await DBHelper.instance.insertAnnouncement(a);
	}

	/// Get announcements for given dosen's jadwal ids
	static Future<List<Announcement>> getAnnouncementsForDosen(String dosenNip) async {
		final jadwals = await JadwalService.getJadwalByDosen(dosenNip);
		final List<Announcement> result = [];
		for (final j in jadwals) {
			final rows = await DBHelper.instance.getAnnouncementsForJadwal(j.id);
			for (final r in rows) {
				result.add(Announcement(
					id: r['id'] as String,
					jadwalId: r['jadwalId'] as String,
					title: r['title'] as String,
					message: r['message'] as String,
					timestamp: DateTime.fromMillisecondsSinceEpoch(r['timestamp'] as int),
				));
			}
		}
		return result;
	}

	/// Toggle attendance for a jadwal and student npm
	static Future<void> toggleAttendance(String jadwalId, String npm) async {
		final jadwal = await JadwalService.getById(jadwalId);
		if (jadwal == null) return;
		if (!jadwal.peserta.contains(npm)) return; // only enrolled students can be toggled
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
}

