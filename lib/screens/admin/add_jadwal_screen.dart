import 'package:flutter/material.dart';
import '../../models/jadwal_model.dart';
import '../../services/db_helper.dart';
import '../../services/jadwal_service.dart';
import '../../utils/colors.dart';

class AddJadwalScreen extends StatefulWidget {
  const AddJadwalScreen({super.key});

  @override
  State<AddJadwalScreen> createState() => _AddJadwalScreenState();
}

class _AddJadwalScreenState extends State<AddJadwalScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController idC = TextEditingController();
  final TextEditingController mkC = TextEditingController();
  final TextEditingController ruangC = TextEditingController();
  final TextEditingController nipC = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  final Set<String> selectedPeserta = {};

  Future<void> pickDate() async {
    final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (d != null) setState(() => selectedDate = d);
  }

  Future<void> pickStartTime() async {
    final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 7, minute: 0));
    if (t != null) setState(() => startTime = t);
  }

  Future<void> pickEndTime() async {
    final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 8, minute: 0));
    if (t != null) setState(() => endTime = t);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedDate == null || startTime == null || endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih hari dan jam terlebih dahulu')));
      return;
    }

    final hariStr = selectedDate!.toIso8601String().split('T')[0];
    final jamStr = '${startTime!.format(context)} - ${endTime!.format(context)}';

    final newJ = Jadwal(
      id: idC.text.trim(),
      mataKuliah: mkC.text.trim(),
      hari: hariStr,
      jam: jamStr,
      ruang: ruangC.text.trim(),
      dosenNip: nipC.text.trim(),
      peserta: selectedPeserta.toList(),
    );

    await JadwalService.addJadwal(newJ);

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jadwal berhasil ditambahkan')));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Jadwal'), backgroundColor: AppColors.primary),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: Column(children: [
                  TextFormField(controller: idC, decoration: const InputDecoration(labelText: 'ID'), validator: (v) => (v == null || v.isEmpty) ? 'ID wajib diisi' : null),
                  const SizedBox(height: 8),
                  TextFormField(controller: mkC, decoration: const InputDecoration(labelText: 'Mata Kuliah'), validator: (v) => (v == null || v.isEmpty) ? 'Mata Kuliah wajib diisi' : null),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: OutlinedButton(onPressed: pickDate, child: Text(selectedDate == null ? 'Pilih Hari' : selectedDate!.toLocal().toString().split(' ')[0]))),
                    const SizedBox(width: 8),
                    Expanded(child: OutlinedButton(onPressed: pickStartTime, child: Text(startTime == null ? 'Jam Mulai' : startTime!.format(context)))),
                    const SizedBox(width: 8),
                    Expanded(child: OutlinedButton(onPressed: pickEndTime, child: Text(endTime == null ? 'Jam Selesai' : endTime!.format(context)))),
                  ]),
                  const SizedBox(height: 8),
                  TextFormField(controller: ruangC, decoration: const InputDecoration(labelText: 'Ruang'), validator: (v) => (v == null || v.isEmpty) ? 'Ruang wajib diisi' : null),
                  const SizedBox(height: 8),
                  TextFormField(controller: nipC, decoration: const InputDecoration(labelText: 'NIP Dosen'), validator: (v) => (v == null || v.isEmpty) ? 'NIP wajib diisi' : null),
                ]),
              ),
              const SizedBox(height: 12),
              const Align(alignment: Alignment.centerLeft, child: Text('Pilih Peserta (Mahasiswa)', style: TextStyle(fontWeight: FontWeight.w600))),
              const SizedBox(height: 8),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: DBHelper.instance.getAllMahasiswa(),
                builder: (context, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final rows = snap.data!;
                  if (rows.isEmpty) return const Text('Belum ada mahasiswa terdaftar.');
                  return SizedBox(
                    height: 240,
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
                          onChanged: (v) => setState(() => v == true ? selectedPeserta.add(npm) : selectedPeserta.remove(npm)),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Batal'))),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary), onPressed: _save, child: const Text('Simpan'))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}