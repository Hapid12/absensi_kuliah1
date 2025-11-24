import 'package:flutter/material.dart';
import '../../services/dosen_service.dart';
import '../../services/jadwal_service.dart';
import '../../models/jadwal_model.dart';
import '../../models/announcement_model.dart';
import '../../utils/colors.dart';

class DosenInformasiScreen extends StatefulWidget {
  final String nip;
  const DosenInformasiScreen({Key? key, required this.nip}) : super(key: key);

  @override
  State<DosenInformasiScreen> createState() => _DosenInformasiScreenState();
}

class _DosenInformasiScreenState extends State<DosenInformasiScreen> {
  List<Jadwal> jadwals = [];
  String? selectedJadwal;
  final TextEditingController _titleC = TextEditingController();
  final TextEditingController _msgC = TextEditingController();
  List<Announcement> anns = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await JadwalService.getJadwalByDosen(widget.nip);
    setState(() {
      jadwals = list;
      if (jadwals.isNotEmpty && selectedJadwal == null) selectedJadwal = jadwals.first.id;
    });
    final an = await DosenService.getAnnouncementsForDosen(widget.nip);
    setState(() => anns = an);
  }

  void _post() async {
    if (selectedJadwal == null) return;
    final t = _titleC.text.trim();
    final m = _msgC.text.trim();
    if (t.isEmpty || m.isEmpty) return;
    await DosenService.postAnnouncement(selectedJadwal!, t, m);
    _titleC.clear();
    _msgC.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Informasi Dosen'), backgroundColor: AppColors.primary),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(children: [
          if (jadwals.isNotEmpty)
            DropdownButton<String>(value: selectedJadwal, items: jadwals.map((j) => DropdownMenuItem(value: j.id, child: Text(j.mataKuliah))).toList(), onChanged: (v) => setState(() => selectedJadwal = v)),
          TextField(controller: _titleC, decoration: const InputDecoration(labelText: 'Judul')),
          TextField(controller: _msgC, decoration: const InputDecoration(labelText: 'Pesan')),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _post, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary), child: const Text('Kirim')),
          const SizedBox(height: 12),
          const Divider(),
          const Text('Pengumuman'),
          Expanded(
            child: ListView.builder(
              itemCount: anns.length,
              itemBuilder: (context, index) {
                final a = anns[index];
                return ListTile(title: Text(a.title), subtitle: Text('${a.message}\n(${a.timestamp})'));
              },
            ),
          ),
        ]),
      ),
    );
  }
}
