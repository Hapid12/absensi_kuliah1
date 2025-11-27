import 'package:flutter/material.dart'; // Import yang hilang
import '../../models/jadwal_model.dart';

import '../../services/jadwal_service.dart';

class DosenJadwalScreen extends StatelessWidget {
  final String nip;
  const DosenJadwalScreen({super.key, required this.nip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal Saya')),
      body: FutureBuilder<List<Jadwal>>( // Pastikan JadwalService.getJadwalsByDosen mengembalikan Future<List<Jadwal>>
        future: JadwalService.getJadwalByDosen(nip),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi error: \\${snapshot.error}'));
          }
          final jadwalDosen = snapshot.data ?? [];
          if (jadwalDosen.isEmpty) {
            return const Center(child: Text('Tidak ada jadwal.'));
          }
          return ListView.builder(
            itemCount: jadwalDosen.length,
            itemBuilder: (context, index) {
              final j = jadwalDosen[index];
              return ListTile(
                title: Text(j.mataKuliah),
                subtitle: Text('${j.hari} - ${j.jam}'),
              );
            },
          );
        },
      ),
    );
  }
}