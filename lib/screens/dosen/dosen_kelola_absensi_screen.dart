import 'package:flutter/material.dart';
import '../../models/mahasiswa_model.dart';
import '../../services/dosen_service.dart';

class DosenKelolaAbsensiScreen extends StatefulWidget {
  final String jadwalId;
  const DosenKelolaAbsensiScreen({super.key, required this.jadwalId});

  @override
  State<DosenKelolaAbsensiScreen> createState() =>
      _DosenKelolaAbsensiScreenState();
}

class _DosenKelolaAbsensiScreenState extends State<DosenKelolaAbsensiScreen> {
  late Future<List<Mahasiswa>> _future;

  @override
  void initState() {
    super.initState();
    _future = DosenService.fetchMahasiswa(widget.jadwalId);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = DosenService.fetchMahasiswa(widget.jadwalId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kelola Absen Mahasiswa")),
      body: FutureBuilder<List<Mahasiswa>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text("Error: ${snap.error}"));
          }
          final list = snap.data ?? [];
          if (list.isEmpty)
            return const Center(child: Text("Tidak ada mahasiswa."));

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final m = list[idx];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    title: Text(m.nama),
                    subtitle: Text("NPM: ${m.npm}"),
                    trailing: PopupMenuButton<String>(
                      initialValue: m.status,
                      onSelected: (val) async {
                        // update status ke backend service
                        await DosenService.updateAbsensi(
                          widget.jadwalId,
                          m.id,
                          val,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("${m.nama} diubah menjadi $val"),
                          ),
                        );
                        _refresh();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'Hadir', child: Text('Hadir')),
                        PopupMenuItem(value: 'Sakit', child: Text('Sakit')),
                        PopupMenuItem(
                          value: 'Tidak Hadir',
                          child: Text('Tidak Hadir'),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: m.status == 'Hadir'
                              ? Colors.green.shade300
                              : m.status == 'Sakit'
                              ? Colors.orange.shade200
                              : Colors.red.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          m.status,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
