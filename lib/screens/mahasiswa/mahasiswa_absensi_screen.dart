import 'package:flutter/material.dart';
import '../../services/jadwal_service.dart';
import '../../services/mahasiswa_service.dart';
import '../../services/dosen_service.dart';
import '../../models/jadwal_model.dart';
import '../../utils/colors.dart';

// Use DB-backed services; prefetch attendance state for listed jadwals.

class MahasiswaAbsensiScreen extends StatefulWidget {
  final String npm;
  const MahasiswaAbsensiScreen({Key? key, required this.npm}) : super(key: key);

  @override
  State<MahasiswaAbsensiScreen> createState() => _MahasiswaAbsensiScreenState();
}

class _MahasiswaAbsensiScreenState extends State<MahasiswaAbsensiScreen> {
  List<Jadwal> jadwals = [];
  final Map<String, Set<String>> attendanceMap = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final all = await JadwalService.getAllJadwal();
    final list = all.where((j) => j.peserta.contains(widget.npm)).toList();
    for (final j in list) {
      final att = await DosenService.getAttendance(j.id);
      attendanceMap[j.id] = Set<String>.from(att);
    }
    setState(() {
      jadwals = list;
    });
  }

  void _absen(String jadwalId) async {
    final ok = await MahasiswaService.markMyAttendance(jadwalId, widget.npm);
    // refresh attendance map for this jadwal
    final att = await DosenService.getAttendance(jadwalId);
    setState(() {
      attendanceMap[jadwalId] = Set<String>.from(att);
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Absen berhasil' : 'Anda sudah absen')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Absensi Mahasiswa'), backgroundColor: AppColors.primary),
      body: ListView.builder(
        itemCount: jadwals.length,
        itemBuilder: (context, index) {
          final j = jadwals[index];
          final present = attendanceMap[j.id]?.contains(widget.npm) ?? false;
          final presentCount = attendanceMap[j.id]?.length ?? 0;
          return ListTile(
            title: Text('${j.mataKuliah} — ${j.hari} ${j.jam}'),
            subtitle: Text('Ruang ${j.ruang} • Hadir: $presentCount'),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: present ? Colors.grey : AppColors.primary),
              onPressed: present ? null : () => _absen(j.id),
              child: Text(present ? 'Sudah' : 'Absen'),
            ),
          );
        },
      ),
    );
  }
}
