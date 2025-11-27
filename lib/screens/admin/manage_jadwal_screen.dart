import 'package:flutter/material.dart';
import '../../models/jadwal_model.dart';
import '../../services/db_helper.dart';
import '../../services/jadwal_service.dart';
import '../../utils/colors.dart';
import 'add_jadwal_screen.dart'; // <-- import baru

class ManageJadwalScreen extends StatefulWidget {
  const ManageJadwalScreen({super.key});

  @override
  State<ManageJadwalScreen> createState() => _ManageJadwalScreenState();
}

class _ManageJadwalScreenState extends State<ManageJadwalScreen> {
  List<Jadwal> jadwalList = [];

  @override
  void initState() {
    super.initState();
    _loadJadwals();
  }

  Future<void> _loadJadwals() async {
    final list = await JadwalService.getAllJadwal();
    setState(() {
      jadwalList = list;
    });
  }

  // Replace the old dialog function: open the AddJadwalScreen full-screen
  void _openAddJadwalScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddJadwalScreen()),
    );
    if (result == true) {
      await _loadJadwals();
    }
  }

  // Keep delete and manage peserta implementations (no change)
  void _deleteJadwal(int index) {
    final j = jadwalList[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Jadwal'),
        content: Text('Yakin ingin menghapus ${j.mataKuliah} (${j.id})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              await JadwalService.deleteJadwal(j.id);
              await _loadJadwals();
              Navigator.pop(context);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Jadwal'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(child: Container()),
                ElevatedButton(
                  onPressed: _openAddJadwalScreen,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Tambah Jadwal'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: jadwalList.length,
              itemBuilder: (context, index) {
                final j = jadwalList[index];
                return ListTile(
                  title: Text('${j.mataKuliah} - ${j.hari} ${j.jam}'),
                  subtitle: Text('Ruang: ${j.ruang} | Dosen: ${j.dosenNip}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => _managePeserta(index),
                        child: const Text('Peserta'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteJadwal(index),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _managePeserta(int index) {
    final jadwal = jadwalList[index];
    final selected = Set<String>.from(jadwal.peserta);
    showDialog(
      context: context,
      builder: (ctx) => FutureBuilder<List<Map<String, dynamic>>>(
        future: DBHelper.instance.getAllMahasiswa(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const AlertDialog(
              content: Center(child: CircularProgressIndicator()),
            );
          }
          final mhsList = snapshot.data!;
          return AlertDialog(
            title: Text('Kelola Peserta: ${jadwal.mataKuliah}'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: mhsList.length,
                itemBuilder: (c, i) {
                  final m = mhsList[i];
                  final npm = m['npm'] as String;
                  final nama = m['nama'] as String;
                  final isSel = selected.contains(npm);
                  return CheckboxListTile(
                    value: isSel,
                    title: Text('$nama ($npm)'),
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          selected.add(npm);
                        } else {
                          selected.remove(npm);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    jadwalList[index] = Jadwal(
                      id: jadwal.id,
                      mataKuliah: jadwal.mataKuliah,
                      hari: jadwal.hari,
                      jam: jadwal.jam,
                      ruang: jadwal.ruang,
                      dosenNip: jadwal.dosenNip,
                      peserta: selected.toList(),
                    );
                  });
                  await JadwalService.updateJadwal(jadwalList[index]);
                  Navigator.pop(ctx);
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }
}
