import 'package:flutter/material.dart';
import '../../services/jadwal_service.dart';
import '../../models/jadwal_model.dart';
import '../../utils/colors.dart';

class MahasiswaJadwalScreen extends StatefulWidget {
  final String npm;
  const MahasiswaJadwalScreen({Key? key, required this.npm}) : super(key: key);

  @override
  State<MahasiswaJadwalScreen> createState() => _MahasiswaJadwalScreenState();
}

class _MahasiswaJadwalScreenState extends State<MahasiswaJadwalScreen> {
  List<Jadwal> jadwals = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await JadwalService.getAllJadwal();
    setState(() {
      jadwals = all.where((j) => j.peserta.contains(widget.npm)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal Kuliah'), backgroundColor: AppColors.primary),
      body: ListView.builder(
        itemCount: jadwals.length,
        itemBuilder: (context, index) {
          final j = jadwals[index];
          return ListTile(title: Text(j.mataKuliah), subtitle: Text('${j.hari} ${j.jam} • ${j.ruang}'));
        },
      ),
    );
  }
}
