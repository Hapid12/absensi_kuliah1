import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../../services/auth_service.dart';
import 'manage_mahasiswa_screen.dart';
import 'manage_dosen_screen.dart';
import 'manage_jadwal_screen.dart';
import '../../utils/colors.dart';
import '../../services/db_helper.dart';
import '../../services/jadwal_service.dart';
import '../../models/jadwal_model.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int mahasiswaCount = 0;
  int dosenCount = 0;
  int jadwalCount = 0;

  final TextEditingController _subjectCtrl = TextEditingController();
  final TextEditingController _messageCtrl = TextEditingController();

  List<Jadwal> _jadwals = [];
  String? _selectedJadwalId; // null => semua jadwal

  @override
  void initState() {
    super.initState();
    _loadCounts();
    _loadJadwals();
  }

  Future<void> _loadCounts() async {
    try {
      final ms = await DBHelper.instance.getAllMahasiswa();
      final ds = await DBHelper.instance.getAllDosen();
      final jd = await JadwalService.getAllJadwal();
      setState(() {
        mahasiswaCount = ms.length;
        dosenCount = ds.length;
        jadwalCount = jd.length;
      });
    } catch (e) {
      setState(() {
        mahasiswaCount = 0;
        dosenCount = 0;
        jadwalCount = 0;
      });
    }
  }

  Future<void> _loadJadwals() async {
    try {
      final all = await JadwalService.getAllJadwal();
      setState(() {
        _jadwals = all;
        if (_jadwals.isNotEmpty) _selectedJadwalId = _jadwals.first.id;
      });
    } catch (_) {
      setState(() => _jadwals = []);
    }
  }

  Future<void> _sendAnnouncement() async {
    final subject = _subjectCtrl.text.trim();
    final message = _messageCtrl.text.trim();
    if (subject.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Isi subject & message')));
      return;
    }

    final createdAt = DateTime.now().toIso8601String();
    if (_selectedJadwalId == null) {
      final all = _jadwals;
      for (final j in all) {
        await DBHelper.instance.insertAnnouncement({
          'jadwalId': j.id,
          'mataKuliah': j.mataKuliah,
          'subject': subject,
          'message': message,
          'createdAt': createdAt,
        });
      }
    } else {
      final j = _jadwals.firstWhere(
        (e) => e.id == _selectedJadwalId,
        orElse: () => Jadwal(
          id: _selectedJadwalId!,
          mataKuliah: '',
          ruang: '',
          hari: '',
          jam: '',
          dosenNip: '',
        ),
      );
      await DBHelper.instance.insertAnnouncement({
        'jadwalId': j.id,
        'mataKuliah': j.mataKuliah,
        'subject': subject,
        'message': message,
        'createdAt': createdAt,
      });
    }

    _subjectCtrl.clear();
    _messageCtrl.clear();

    // existing snackbar
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Pengumuman terkirim')));

    // New: show success popup dialog
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Berhasil'),
        content: const Text('Pengumuman berhasil dikirim ke tujuan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Widget _statCard(String label, String value) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.school),
            SizedBox(width: 8),
            Text('Agenda Kuliah'),
          ],
        ),
        backgroundColor: AppColors.primary,
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'logout') {
                AuthService.logout();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Logout'),
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                ),
                child: const Text('Admin'),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dashboard',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _statCard('Mahasiswa', mahasiswaCount.toString()),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: _statCard('Dosen', dosenCount.toString())),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statCard('Jadwal Kuliah', jadwalCount.toString()),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Buat Pengumuman',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _subjectCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Subjek',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _messageCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Informasi Lanjutan',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String?>(
                                decoration: const InputDecoration(
                                  labelText: 'Tujuan (Pilih Jadwal atau Semua)',
                                  border: OutlineInputBorder(),
                                ),
                                value: _selectedJadwalId,
                                onChanged: (v) {
                                  setState(() => _selectedJadwalId = v);
                                },
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('Semua Jadwal'),
                                  ),
                                  ..._jadwals.map(
                                    (j) => DropdownMenuItem(
                                      value: j.id,
                                      child: Text('${j.id} - ${j.mataKuliah}'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _sendAnnouncement,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                              ),
                              child: const Text('Kirim'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                              ),
                              child: const Text(
                                'Grafik',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Manajemen Data',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ManageMahasiswaScreen(),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text('Mahasiswa'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ManageDosenScreen(),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text('Dosen'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ManageJadwalScreen(),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text('Jadwal Kuliah'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // decorative footer curve
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 100,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
              ),
              child: const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}
