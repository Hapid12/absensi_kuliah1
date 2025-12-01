// lib/screens/mahasiswa/mahasiswa_jadwal_screen.dart
import 'package:flutter/material.dart';
import '../../services/jadwal_service.dart';
import '../../models/jadwal_model.dart';
import '../../utils/colors.dart';

class MahasiswaJadwalScreen extends StatefulWidget {
  final String npm;
  const MahasiswaJadwalScreen({super.key, required this.npm});

  @override
  State<MahasiswaJadwalScreen> createState() => _MahasiswaJadwalScreenState();
}

class _MahasiswaJadwalScreenState extends State<MahasiswaJadwalScreen> {
  List<Jadwal> _all = [];
  List<Jadwal> _visible = [];
  String _search = '';
  int _selectedDay = 0; // 0 = Semua, 1 = Senin, ... 6 = Sabtu
  bool _loading = true;

  final List<String> _days = [
    'Semua Hari',
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    "Jumat",
    'Sabtu'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });

    final all = await JadwalService.getAllJadwal();

    // Normalisasi peserta tiap jadwal supaya perbandingan lebih aman
    final normalized = all.map((j) {
      final peserta = j.peserta
          .map((e) => e.toString().replaceAll('"', '').trim())
          .where((e) => e.isNotEmpty)
          .toList();
      return Jadwal(
        id: j.id,
        mataKuliah: j.mataKuliah,
        hari: j.hari,
        jam: j.jam,
        ruang: j.ruang,
        dosenNip: j.dosenNip,
        peserta: peserta,
      );
    }).toList();

    // Filter hanya jadwal yang peserta-nya mengandung npm (safety: trim)
    final npmTry = widget.npm.replaceAll('"', '').trim();
    final own = normalized.where((j) {
      return j.peserta.any((p) => p.replaceAll('"', '').trim() == npmTry);
    }).toList();

    setState(() {
      _all = own;
      _applyFilters();
      _loading = false;
    });
  }

  void _applyFilters() {
    final q = _search.trim().toLowerCase();
    final filtered = _all.where((j) {
      final matchSearch =
          q.isEmpty || j.mataKuliah.toLowerCase().contains(q) || j.id.toLowerCase().contains(q);
      final dayMatch = _selectedDay == 0 ? true : _weekdayFromString(j.hari) == _selectedDay;
      return matchSearch && dayMatch;
    }).toList();

    // sort by hari -> jam mulai
    filtered.sort((a, b) {
      final da = _weekdayFromString(a.hari);
      final db = _weekdayFromString(b.hari);
      if (da != db) return da - db;
      final sa = _startMinutesFromJam(a.jam);
      final sb = _startMinutesFromJam(b.jam);
      return sa.compareTo(sb);
    });

    setState(() {
      _visible = filtered;
    });
  }

  int _weekdayFromString(String hari) {
    final dt = DateTime.tryParse(hari);
    if (dt != null) return dt.weekday;
    final normalized = hari.trim().toLowerCase();
    final map = {
      'senin': 1,
      'monday': 1,
      'selasa': 2,
      'tuesday': 2,
      'rabu': 3,
      'wednesday': 3,
      'kamis': 4,
      'thursday': 4,
      "jumat": 5,
      "jum'at": 5,
      'friday': 5,
      'sabtu': 6,
      'saturday': 6,
      'minggu': 7,
      'sunday': 7,
    };
    return map[normalized] ?? 7;
  }

  int _startMinutesFromJam(String jamStr) {
    final parts = jamStr.split('-');
    if (parts.isEmpty) return 0;
    final left = parts[0].trim();
    final ampmReg = RegExp(r'^(\d{1,2}):(\d{2})\s*([AaPp][Mm])$');
    final m24Reg = RegExp(r'^(\d{1,2}):(\d{2})$');

    final ampmMatch = ampmReg.firstMatch(left);
    if (ampmMatch != null) {
      var hour = int.parse(ampmMatch.group(1)!);
      final minute = int.parse(ampmMatch.group(2)!);
      final ampm = ampmMatch.group(3)!.toLowerCase();
      if (ampm == 'pm' && hour < 12) hour += 12;
      if (ampm == 'am' && hour == 12) hour = 0;
      return hour * 60 + minute;
    }

    final m24Match = m24Reg.firstMatch(left);
    if (m24Match != null) {
      final hour = int.parse(m24Match.group(1)!);
      final minute = int.parse(m24Match.group(2)!);
      return hour * 60 + minute;
    }

    return 0;
  }

  String _dayNameFromWeekday(int wd) {
    switch (wd) {
      case 1:
        return 'Senin';
      case 2:
        return 'Selasa';
      case 3:
        return 'Rabu';
      case 4:
        return 'Kamis';
      case 5:
        return 'Jumat';
      case 6:
        return 'Sabtu';
      default:
        return 'Minggu';
    }
  }

  void _prevDay() {
    if (_selectedDay <= 0) return;
    setState(() {
      _selectedDay = (_selectedDay - 1).clamp(0, 6);
      _applyFilters();
    });
  }

  void _nextDay() {
    if (_selectedDay >= 6) return;
    setState(() {
      _selectedDay = (_selectedDay + 1).clamp(0, 6);
      _applyFilters();
    });
  }

  Widget _buildTable() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_visible.isEmpty) {
      return const Center(child: Text('Belum ada jadwal untuk Anda.'));
    }

    // Gunakan ListView dengan card per-row agar lebih mirip gambar
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _visible.length,
      itemBuilder: (context, index) {
        final j = _visible[index];

        final jamParts = j.jam.split('-').map((s) => s.trim()).toList();
        final jamMulai = jamParts.isNotEmpty ? jamParts[0] : '-';
        final jamSelesai = jamParts.length > 1 ? jamParts[1] : '-';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // KODE
              Container(
                width: 120,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kode',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    Text(j.id, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

              // MATA KULIAH
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        j.mataKuliah,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('(Kelas : A)', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                    ],
                  ),
                ),
              ),

              // DETAIL / PERTEMUAN
              Container(
                width: 240,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pertemuan', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text('1', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Hari: ${j.hari}', style: const TextStyle(fontSize: 12)),
                    Text('Jam: $jamMulai - $jamSelesai', style: const TextStyle(fontSize: 12)),
                    Text('Ruang: ${j.ruang}', style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _openDetailDialog(j),
                      icon: const Icon(Icons.info_outline, size: 16),
                      label: const Text('Detail'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openDetailDialog(Jadwal j) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(j.mataKuliah),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kode: ${j.id}'),
              const SizedBox(height: 6),
              Text('Hari: ${j.hari}'),
              Text('Jam: ${j.jam}'),
              Text('Ruang: ${j.ruang}'),
              Text('Dosen NIP: ${j.dosenNip}'),
              const SizedBox(height: 6),
              Text('Peserta: ${j.peserta.length} mahasiswa'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayWd = DateTime.now().weekday;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Kuliah'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          // Search + Controls
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Search
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Cari mata kuliah atau kode...'),
                    onChanged: (v) {
                      setState(() {
                        _search = v;
                        _applyFilters();
                      });
                    },
                  ),
                ),

                const SizedBox(width: 8),

                // Day dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: DropdownButton<int>(
                    value: _selectedDay,
                    underline: const SizedBox(),
                    items: List.generate(_days.length, (i) => DropdownMenuItem(value: i, child: Text(_days[i]))),
                    onChanged: (v) {
                      setState(() {
                        _selectedDay = v ?? 0;
                        _applyFilters();
                      });
                    },
                  ),
                ),

                const SizedBox(width: 8),

                // Prev / Next
                IconButton(
                  tooltip: 'Prev hari',
                  onPressed: _prevDay,
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  tooltip: 'Next hari',
                  onPressed: _nextDay,
                  icon: const Icon(Icons.chevron_right),
                ),

                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _load,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Refresh'),
                ),
              ],
            ),
          ),

          // Hari header kecil
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
            child: Row(
              children: [
                Text(
                  'Menampilkan: ${_selectedDay == 0 ? 'Semua Hari' : _dayNameFromWeekday(_selectedDay)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_all.isNotEmpty)
                  Text('Total jadwal: ${_visible.length} / ${_all.length}', style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),

          // Table / List
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: _buildTable(),
            ),
          ),
        ],
      ),
    );
  }
}
