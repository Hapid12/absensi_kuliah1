import 'package:flutter/material.dart';
import '../../models/jadwal_model.dart';
import '../../services/db_helper.dart';
import '../../services/jadwal_service.dart';
import '../../utils/colors.dart';

class ManageJadwalScreen extends StatefulWidget {
  const ManageJadwalScreen({Key? key}) : super(key: key);

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

  void _addJadwal() {
    final idC = TextEditingController();
    final mkC = TextEditingController();
    final ruangC = TextEditingController();
    final nipC = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    final selectedPeserta = <String>{};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setStateDialog) {

        Future<void> pickDate() async {
          final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
          if (d != null) setStateDialog(() => selectedDate = d);
        }

        Future<void> pickStartTime() async {
          final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: 7, minute: 0));
          if (t != null) setStateDialog(() => startTime = t);
        }

        Future<void> pickEndTime() async {
          final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: 8, minute: 0));
          if (t != null) setStateDialog(() => endTime = t);
        }

        return AlertDialog(
          title: const Text('Tambah Jadwal'),
          content: SingleChildScrollView(
            child: Column(children: [
              TextField(controller: idC, decoration: const InputDecoration(labelText: 'ID')),
              const SizedBox(height: 8),
              TextField(controller: mkC, decoration: const InputDecoration(labelText: 'Mata Kuliah')),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: pickDate, child: Text(selectedDate == null ? 'Pilih Hari' : selectedDate!.toLocal().toString().split(' ')[0]))),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton(onPressed: pickStartTime, child: Text(startTime == null ? 'Jam Mulai' : startTime!.format(context)))),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton(onPressed: pickEndTime, child: Text(endTime == null ? 'Jam Selesai' : endTime!.format(context)))),
              ]),
              const SizedBox(height: 8),
              TextField(controller: ruangC, decoration: const InputDecoration(labelText: 'Ruang')),
              const SizedBox(height: 8),
              TextField(controller: nipC, decoration: const InputDecoration(labelText: 'NIP Dosen')),
              const SizedBox(height: 8),
              // peserta multi-select
              FutureBuilder<List<Map<String, dynamic>>>(
                future: DBHelper.instance.getAllMahasiswa(),
                builder: (context, snap) {
                  if (!snap.hasData) return const CircularProgressIndicator();
                  final rows = snap.data!;
                  return SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: rows.length,
                      itemBuilder: (c, i) {
                        final r = rows[i];
                        final npm = r['npm'] as String;
                        final nama = r['nama'] as String;
                        final sel = selectedPeserta.contains(npm);
                        return CheckboxListTile(
                          value: sel,
                          title: Text('$nama ($npm)'),
                          onChanged: (v) => setStateDialog(() => v == true ? selectedPeserta.add(npm) : selectedPeserta.remove(npm)),
                        );
                      },
                    ),
                  );
                },
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                if (idC.text.isNotEmpty && mkC.text.isNotEmpty && selectedDate != null && startTime != null && endTime != null) {
                  final hariStr = selectedDate!.toIso8601String().split('T')[0];
                  final jamStr = '${startTime!.format(context)} - ${endTime!.format(context)}';
                  final newJ = Jadwal(id: idC.text, mataKuliah: mkC.text, hari: hariStr, jam: jamStr, ruang: ruangC.text, dosenNip: nipC.text, peserta: selectedPeserta.toList());
                  await JadwalService.addJadwal(newJ);
                  await _loadJadwals();
                  Navigator.pop(context);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      }),
    );
  }

  void _deleteJadwal(int index) {
    final j = jadwalList[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Jadwal'),
        content: Text('Yakin ingin menghapus ${j.mataKuliah} (${j.id})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
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
      appBar: AppBar(title: const Text('Data Jadwal'), backgroundColor: AppColors.primary),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(child: Container()),
                ElevatedButton(onPressed: _addJadwal, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary), child: const Text('Tambah Jadwal')),
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
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    TextButton(onPressed: () => _managePeserta(index), child: const Text('Peserta')),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteJadwal(index)),
                  ]),
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
            return const AlertDialog(content: Center(child: CircularProgressIndicator()));
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
                        if (v == true) selected.add(npm); else selected.remove(npm);
                      });
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              ElevatedButton(onPressed: () async {
                setState(() {
                  jadwalList[index] = Jadwal(id: jadwal.id, mataKuliah: jadwal.mataKuliah, hari: jadwal.hari, jam: jadwal.jam, ruang: jadwal.ruang, dosenNip: jadwal.dosenNip, peserta: selected.toList());
                });
                await JadwalService.updateJadwal(jadwalList[index]);
                Navigator.pop(ctx);
              }, child: const Text('Simpan'))
            ],
          );
        },
      ),
    );
  }
}
