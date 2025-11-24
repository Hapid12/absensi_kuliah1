
import '../models/jadwal_model.dart';
import 'db_helper.dart';

class JadwalService {
	static Future<List<Jadwal>> getAllJadwal() async => await DBHelper.instance.getAllJadwal();

	static Future<List<Jadwal>> getJadwalByDosen(String nip) async {
		final all = await getAllJadwal();
		return all.where((j) => j.dosenNip == nip).toList();
	}

	static Future<Jadwal?> getById(String id) async {
		final all = await getAllJadwal();
		final matches = all.where((j) => j.id == id).toList();
		return matches.isNotEmpty ? matches.first : null;
	}

	static Future<void> addJadwal(Jadwal j) async {
		await DBHelper.instance.insertJadwal(j);
	}

	static Future<void> updateJadwal(Jadwal j) async {
		await DBHelper.instance.updateJadwal(j);
	}

	static Future<void> deleteJadwal(String id) async {
		await DBHelper.instance.deleteJadwal(id);
	}
}

