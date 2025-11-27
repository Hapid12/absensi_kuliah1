import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../services/jadwal_service.dart';
import '../../services/db_helper.dart';

class MahasiswaInformasiScreen extends StatefulWidget {
  final String npm;
  const MahasiswaInformasiScreen({super.key, required this.npm});

  @override
  State<MahasiswaInformasiScreen> createState() => _MahasiswaInformasiScreenState();
}

class _MahasiswaInformasiScreenState extends State<MahasiswaInformasiScreen> {
  List<Map<String, dynamic>> anns = [];

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    final all = await JadwalService.getAllJadwal();
    final my = all.where((j) => j.peserta.contains(widget.npm)).toList();
    final List<Map<String, dynamic>> collected = [];
    for (final j in my) {
      final rows = await DBHelper.instance.getAnnouncementsForJadwal(j.id);
      collected.addAll(rows);
    }
    collected.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));
    setState(() {
      anns = collected;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Informasi Mahasiswa'), backgroundColor: AppColors.primary),
      body: ListView.builder(
        itemCount: anns.length,
        itemBuilder: (context, index) {
          final a = anns[index];
          final ts = DateTime.fromMillisecondsSinceEpoch(a['timestamp'] as int);
          return ListTile(title: Text(a['title'] as String), subtitle: Text('${a['message']}\n($ts)'));
        },
      ),
    );
  }
}
