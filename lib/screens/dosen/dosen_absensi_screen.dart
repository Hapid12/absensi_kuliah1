import 'package:flutter/material.dart';
import '../../services/jadwal_service.dart';
import '../../services/dosen_service.dart';
import '../../services/db_helper.dart';
import '../../models/jadwal_model.dart';
import '../../utils/colors.dart';

// This screen now uses async DB-backed services. Attendance data is cached in-memory
// in `attendanceMap` and updated when toggles occur.

class DosenAbsensiScreen extends StatefulWidget {
  final String nip;
  const DosenAbsensiScreen({Key? key, required this.nip}) : super(key: key);

  @override
  State<DosenAbsensiScreen> createState() => _DosenAbsensiScreenState();
}

class _DosenAbsensiScreenState extends State<DosenAbsensiScreen> {
  List<Jadwal> jadwals = [];
  final Map<String, Set<String>> attendanceMap = {}; // jadwalId -> set of npm
  final Map<String, bool> dosenPresentMap = {}; // jadwalId -> isDosenPresent
  final Map<String, String> mahasiswaNames = {}; // npm -> name

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final list = await JadwalService.getJadwalByDosen(widget.nip);
    // preload mahasiswa names
    final rows = await DBHelper.instance.getAllMahasiswa();
    for (final r in rows) {
      mahasiswaNames[r['npm'] as String] = r['nama'] as String;
    }
    for (final j in list) {
      final att = await DosenService.getAttendance(j.id);
      attendanceMap[j.id] = Set<String>.from(att);
      final dPresent = await DosenService.isDosenPresent(j.id, widget.nip);
      dosenPresentMap[j.id] = dPresent;
    }
    setState(() {
      jadwals = list;
    });
  }

  void _openAttendanceEditor(Jadwal j) {
    final pesertaNpms = j.peserta;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Absensi: ${j.mataKuliah}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
              itemCount: pesertaNpms.length,
            itemBuilder: (context, index) {
              final npm = pesertaNpms[index];
              final mName = mahasiswaNames[npm] ?? npm;
              final present = attendanceMap[j.id]?.contains(npm) ?? false;
              return CheckboxListTile(
                value: present,
                title: Text('$mName ($npm)'),
                onChanged: (_) {
                  // toggle in DB and update local cache
                  DosenService.toggleAttendance(j.id, npm).then((_) async {
                    final att = await DosenService.getAttendance(j.id);
                    setState(() {
                      attendanceMap[j.id] = Set<String>.from(att);
                    });
                  });
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Absensi Dosen'), backgroundColor: AppColors.primary),
      body: ListView.builder(
        itemCount: jadwals.length,
        itemBuilder: (context, index) {
          final j = jadwals[index];
          final presentCount = attendanceMap[j.id]?.length ?? 0;
          final dosenPresent = dosenPresentMap[j.id] ?? false;
          return ListTile(
            title: Text('${j.mataKuliah} — ${j.hari} ${j.jam}'),
            subtitle: Text('Ruang ${j.ruang} • Hadir: $presentCount'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () => _openAttendanceEditor(j),
                child: const Text('Kelola'),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Saya Hadir', style: TextStyle(fontSize: 12)),
                  Switch(
                    value: dosenPresent,
                    onChanged: (v) async {
                      await DosenService.toggleDosenPresence(j.id, widget.nip);
                      final now = await DosenService.isDosenPresent(j.id, widget.nip);
                      setState(() {
                        dosenPresentMap[j.id] = now;
                      });
                    },
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ]),
          );
        },
      ),
    );
  }
}
