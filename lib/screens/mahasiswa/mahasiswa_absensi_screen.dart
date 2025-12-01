import 'package:flutter/material.dart';
import '../../services/jadwal_service.dart';
import '../../services/mahasiswa_service.dart';
import '../../services/dosen_service.dart';
import '../../models/jadwal_model.dart';
import '../../utils/colors.dart';

class MahasiswaAbsensiScreen extends StatefulWidget {
  final String npm;
  const MahasiswaAbsensiScreen({super.key, required this.npm});

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

  // parsing helper: parse single time string like "07:00", "7:00", "07:00 AM", "7:00 PM"
  DateTime? _parseTimeToDateTime(String dateIso, String timeStr) {
    try {
      final date = DateTime.tryParse(dateIso);
      if (date == null) return null;

      final s = timeStr.trim();
      final ampmMatch = RegExp(
        r'^(\d{1,2}):(\d{2})\s*([AaPp][Mm])$',
      ).firstMatch(s);
      if (ampmMatch != null) {
        var hour = int.parse(ampmMatch.group(1)!);
        final minute = int.parse(ampmMatch.group(2)!);
        final ampm = ampmMatch.group(3)!.toLowerCase();
        if (ampm == 'pm' && hour < 12) hour += 12;
        if (ampm == 'am' && hour == 12) hour = 0;
        return DateTime(date.year, date.month, date.day, hour, minute);
      }
      final m24 = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(s);
      if (m24 != null) {
        final hour = int.parse(m24.group(1)!);
        final minute = int.parse(m24.group(2)!);
        return DateTime(date.year, date.month, date.day, hour, minute);
      }
      // fallback - can't parse
      return null;
    } catch (e) {
      return null;
    }
  }

  // split jam string "07:00 AM - 08:00 AM" or "07:00 - 08:00"
  Tuple2<DateTime?, DateTime?> _parseStartEnd(Jadwal j) {
    final parts = j.jam.split('-');
    final left = parts.isNotEmpty ? parts[0].trim() : '';
    final right = parts.length > 1 ? parts[1].trim() : '';
    final start = _parseTimeToDateTime(j.hari, left);
    final end = _parseTimeToDateTime(j.hari, right);
    return Tuple2(start, end);
  }

  // simple tuple helper for local use
  // we don't need to import tuple lib; create local class
  // (We'll define a small local type below)
  // Do check allowed absen: must be same date & current time in interval
  bool _isNowWithinSchedule(Jadwal j) {
    final pair = _parseStartEnd(j);
    final start = pair.item1;
    final end = pair.item2;
    if (start == null || end == null) return false;
    final now = DateTime.now();
    // require same calendar day (j.hari) as today
    final jadwalDay = DateTime(start.year, start.month, start.day);
    final today = DateTime(now.year, now.month, now.day);
    if (jadwalDay != today) return false;
    return now.isAfter(start.subtract(const Duration(seconds: 1))) &&
        now.isBefore(end.add(const Duration(seconds: 1)));
  }

  Future<void> _absen(String jadwalId) async {
    // find jadwal
    final j = jadwals.firstWhere((e) => e.id == jadwalId);
    final allowed = _isNowWithinSchedule(j);
    if (!allowed) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Gagal Absen'),
          content: const Text(
            'Absen hanya dapat dilakukan saat jam kuliah berlangsung pada tanggal yang sama.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // call service to mark attendance
    final ok = await MahasiswaService.markMyAttendance(jadwalId, widget.npm);
    if (ok) {
      // refresh attendance map for this jadwal
      final att = await DosenService.getAttendance(jadwalId);
      setState(() {
        attendanceMap[jadwalId] = Set<String>.from(att);
      });
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Berhasil Absen'),
          content: const Text('Absensi Anda telah tercatat.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      // failure - can mean already absen or blocked by dosen
      // we try to detect if already absen
      final att = attendanceMap[jadwalId] ?? {};
      final already = att.contains(widget.npm);
      final msg = already
          ? 'Anda sudah absen sebelumnya.'
          : 'Absen ditolak (mungkin absen diblokir oleh dosen).';
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Gagal Absen'),
          content: Text(msg),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  // small helper to format only time portion for display "HH:MM" or "HH:MM AM/PM"
  String _formatShortTimeForDisplay(DateTime? dt) {
    if (dt == null) return '-';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    // use 24h representation; if want AM/PM, convert
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Absensi Mahasiswa'),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Absensi Kehadiran',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: jadwals.isEmpty
                  ? const Center(child: Text('Belum ada jadwal untuk Anda.'))
                  : ListView.builder(
                      itemCount: jadwals.length,
                      itemBuilder: (context, index) {
                        final j = jadwals[index];
                        final present =
                            attendanceMap[j.id]?.contains(widget.npm) ?? false;
                        final presentCount = attendanceMap[j.id]?.length ?? 0;
                        final pair = _parseStartEnd(j);
                        final start = pair.item1;
                        final end = pair.item2;
                        final isOpen = _isNowWithinSchedule(j);

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.95),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        j.mataKuliah,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'KODE: ${j.id} • SKS: - • Pertemuan: 1',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Info Absensi header
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'INFO ABSENSI',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      present
                                          ? 'Anda Telah Absen'
                                          : 'Anda Belum Absen',
                                      style: TextStyle(
                                        color: present
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Table with details
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columnSpacing: 12,
                                    headingRowHeight: 28,
                                    dataRowHeight: 38,
                                    columns: const [
                                      DataColumn(label: Text('Kelas')),
                                      DataColumn(label: Text('Gedung')),
                                      DataColumn(label: Text('Ruang')),
                                      DataColumn(label: Text('Jam Mulai')),
                                      DataColumn(label: Text('Jam Berakhir')),
                                    ],
                                    rows: [
                                      DataRow(
                                        cells: [
                                          DataCell(
                                            Text(j.id),
                                          ), // use id as Kelas (adjust if model changes)
                                          DataCell(
                                            Text('Gedung MIPA'),
                                          ), // static as sample; update model to support real field if needed
                                          DataCell(Text(j.ruang)),
                                          DataCell(
                                            Text(
                                              _formatShortTimeForDisplay(start),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              _formatShortTimeForDisplay(end),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // footer with buttons (Edit Absen, Pengumuman, Absen)
                                Row(
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        // edit absen for mahasiswa is not allowed; show info
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Fitur Edit Absen hanya untuk dosen',
                                            ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.yellow[700],
                                      ),
                                      child: const Text(
                                        'Edit Absen',
                                        style: TextStyle(color: Colors.black),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    OutlinedButton(
                                      onPressed: () {
                                        // open announcement - placeholder
                                        showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text('Pengumuman'),
                                            content: const Text(
                                              'Tidak ada pengumuman.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('OK'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: Colors.blue[100],
                                      ),
                                      child: const Text(
                                        'Pengumuman',
                                        style: TextStyle(color: Colors.black),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: present
                                            ? null
                                            : (isOpen
                                                  ? () => _absen(j.id)
                                                  : () {
                                                      // not allowed to absen now
                                                      showDialog(
                                                        context: context,
                                                        builder: (ctx) => AlertDialog(
                                                          title: const Text(
                                                            'Absen Tidak Tersedia',
                                                          ),
                                                          content: const Text(
                                                            'Absen hanya bisa dilakukan saat jam berlangsung.',
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                    ctx,
                                                                  ),
                                                              child: const Text(
                                                                'OK',
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    }),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: present
                                              ? Colors.grey
                                              : AppColors.primary,
                                        ),
                                        child: Text(
                                          present
                                              ? 'Sudah'
                                              : (isOpen
                                                    ? 'Absen'
                                                    : 'Absen (Tutup)'),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // summary
                                Text(
                                  'Hadir: $presentCount',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// small tuple used for returning two DateTimes
class Tuple2<T1, T2> {
  final T1? item1;
  final T2? item2;
  Tuple2(this.item1, this.item2);
}
