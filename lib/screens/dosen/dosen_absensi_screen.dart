import 'package:flutter/material.dart';
import 'dart:math';
import '../../services/jadwal_service.dart';
import '../../services/dosen_service.dart';
import '../../services/db_helper.dart';
import '../../models/jadwal_model.dart';
import '../../utils/colors.dart';

// Layar Absensi Dosen: menampilkan daftar jadwal dosen yang login,
// menghitung kehadiran mahasiswa, memungkinkan dosen menandai dirinya hadir,
// dan mengelola (toggle) kehadiran mahasiswa per jadwal.

class DosenAbsensiScreen extends StatefulWidget {
  final String nip;
  const DosenAbsensiScreen({super.key, required this.nip});

  @override
  State<DosenAbsensiScreen> createState() => _DosenAbsensiScreenState();
}

class _DosenAbsensiScreenState extends State<DosenAbsensiScreen> {
  List<Jadwal> jadwals = [];
  final Map<String, Set<String>> attendanceMap = {}; // jadwalId -> set of npm
  final Map<String, bool> dosenPresentMap = {}; // jadwalId -> isDosenPresent
  final Map<String, String> mahasiswaNames = {}; // npm -> name
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final list = await JadwalService.getJadwalByDosen(widget.nip);
      // preload mahasiswa names
      final rows = await DBHelper.instance.getAllMahasiswa();
      mahasiswaNames.clear();
      for (final r in rows) {
        mahasiswaNames[r['npm'] as String] = r['nama'] as String;
      }

      for (final j in list) {
        try {
          final att = await DosenService.getAttendance(j.id);
          attendanceMap[j.id] = Set<String>.from(att);
        } catch (_) {
          attendanceMap[j.id] = <String>{};
        }
        try {
          final dPresent = await DosenService.isDosenPresent(j.id, widget.nip);
          dosenPresentMap[j.id] = dPresent;
        } catch (_) {
          dosenPresentMap[j.id] = false;
        }
      }

      setState(() {
        jadwals = list;
      });
    } catch (e) {
      // jika error, tetap set loading false dan jadwals tetap kosong
    } finally {
      setState(() => isLoading = false);
    }
  }

  // helper to mark student present (use existing toggleAttendance)
  Future<void> _markStudentPresent(String jadwalId, String npm) async {
    try {
      final current = attendanceMap[jadwalId] ?? <String>{};
      if (!current.contains(npm)) {
        await DosenService.toggleAttendance(jadwalId, npm);
        final att = await DosenService.getAttendance(jadwalId);
        setState(() {
          attendanceMap[jadwalId] = Set<String>.from(att);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Berhasil menandai hadir: $npm')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Mahasiswa sudah hadir: $npm')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menandai hadir: $npm')));
    }
  }

  // helper to reject student presence (remove hadir if exists)
  Future<void> _rejectStudentAttendance(String jadwalId, String npm) async {
    try {
      final current = attendanceMap[jadwalId] ?? <String>{};
      if (current.contains(npm)) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Konfirmasi Tolak'),
            content: Text('Anda yakin ingin menolak absensi $npm?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Tolak'),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
        await DosenService.toggleAttendance(jadwalId, npm);
        final att = await DosenService.getAttendance(jadwalId);
        setState(() {
          attendanceMap[jadwalId] = Set<String>.from(att);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Absensi $npm ditolak.')));
      } else {
        // jika belum hadir, 'tolak' hanya menampilkan info; untuk memblokir absen,
        // butuh API tambahan di backend (contoh: DosenService.rejectAttendance).
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Mahasiswa $npm belum absen. Gunakan fitur blokir jika tersedia.',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal tolak absensi: $npm')));
    }
  }

  // helper to force refresh attendance for a particular jadwal
  Future<void> _refreshAttendanceForJadwal(String jadwalId) async {
    try {
      final att = await DosenService.getAttendance(jadwalId);
      setState(() {
        attendanceMap[jadwalId] = Set<String>.from(att);
      });
    } catch (_) {
      // ignore for now
    }
  }

  // tambahkan dialog pengumuman sederhana
  Future<void> _showAnnouncementDialog(Jadwal j) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pengumuman: ${j.mataKuliah}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Tulis pengumuman di sini...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kirim'),
          ),
        ],
      ),
    );

    if (confirmed == true && controller.text.trim().isNotEmpty) {
      // panggil service jika ada backend; contoh di sini hanya snackbar
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pengumuman dikirim.')));
    }
  }

  void _openAttendanceEditor(BuildContext ctx, Jadwal j) {
    final pesertaNpms = j.peserta;
    showDialog(
      context: ctx,
      builder: (ctx2) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text('Absensi: ${j.mataKuliah}')),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FutureBuilder(
                  future: DosenService.getAttendance(j.id),
                  builder: (context, snapshot) {
                    final presentCount = snapshot.hasData
                        ? (snapshot.data as List).length
                        : (attendanceMap[j.id]?.length ?? 0);
                    final total = j.peserta.length;
                    return Text(
                      'Hadir: $presentCount/$total',
                      style: const TextStyle(fontSize: 12),
                    );
                  },
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: () => _refreshAttendanceForJadwal(j.id),
                  icon: const Icon(Icons.refresh, size: 20),
                ),
              ],
            ),
          ],
        ),
        content: LayoutBuilder(
          builder: (context, constraints) {
            final maxHeight = min(
              MediaQuery.of(context).size.height * 0.75,
              600.0,
            );
            return SizedBox(
              width: double.maxFinite,
              height: maxHeight,
              child: Scrollbar(
                thumbVisibility: true,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: pesertaNpms.length,
                  itemBuilder: (context, index) {
                    final npm = pesertaNpms[index];
                    final mName = mahasiswaNames[npm] ?? npm;
                    final present = attendanceMap[j.id]?.contains(npm) ?? false;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Card(
                        elevation: 1,
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(mName.isNotEmpty ? mName[0] : '?'),
                          ),
                          title: Text('$mName ($npm)'),
                          subtitle: Text(
                            present ? 'Status: Hadir' : 'Status: Belum absen',
                          ),
                          trailing: Wrap(
                            spacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: present
                                    ? null
                                    : () => _markStudentPresent(j.id, npm),
                                icon: const Icon(Icons.check, size: 16),
                                label: const Text('Absen'),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(72, 36),
                                  textStyle: const TextStyle(fontSize: 13),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _rejectStudentAttendance(j.id, npm),
                                icon: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.red,
                                ),
                                label: const Text('Tolak'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  minimumSize: const Size(72, 36),
                                  textStyle: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx2),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleDosenPresence(Jadwal j) async {
    try {
      await DosenService.toggleDosenPresence(j.id, widget.nip);
      final now = await DosenService.isDosenPresent(j.id, widget.nip);
      setState(() {
        dosenPresentMap[j.id] = now;
      });
    } catch (e) {
      // handle error if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Absensi Dosen'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : jadwals.isEmpty
          ? const Center(child: Text('Belum ada jadwal terkait.'))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: jadwals.length,
                itemBuilder: (context, index) {
                  final j = jadwals[index];
                  final presentCount = attendanceMap[j.id]?.length ?? 0;
                  final dosenPresent = dosenPresentMap[j.id] ?? false;
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    elevation: 2,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      title: Text('${j.mataKuliah} — ${j.hari} ${j.jam}'),
                      subtitle: Text('Ruang ${j.ruang} • Hadir: $presentCount'),
                      trailing: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          alignment: WrapAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () =>
                                  _openAttendanceEditor(context, j),
                              child: const Text('Kelola'),
                            ),
                            OutlinedButton(
                              onPressed: () => _showAnnouncementDialog(j),
                              child: const Text('Pengumuman'),
                            ),
                            ElevatedButton(
                              onPressed: () => _toggleDosenPresence(j),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: dosenPresent
                                    ? Colors.green[600]
                                    : AppColors.primary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(72, 36),
                              ),
                              child: const Text('Absen'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
