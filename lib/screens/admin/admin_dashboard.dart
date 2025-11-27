import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'manage_mahasiswa_screen.dart';
import 'manage_dosen_screen.dart';
import 'manage_jadwal_screen.dart';
import '../../utils/colors.dart';
import '../../services/db_helper.dart';
import '../auth/login_screen.dart';
import '../../services/auth_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int mahasiswaCount = 0;
  int dosenCount = 0;
  int jadwalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final db = await DBHelper.instance.database;
    final m = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM mahasiswa')) ?? 0;
    final d = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM dosen')) ?? 0;
    final j = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM jadwal')) ?? 0;
    setState(() {
      mahasiswaCount = m;
      dosenCount = d;
      jadwalCount = j;
    });
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
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: const [Icon(Icons.school), SizedBox(width: 8), Text('Agenda Kuliah')]),
        backgroundColor: AppColors.primary,
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'logout') {
                AuthService.logout();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'logout', child: ListTile(leading: Icon(Icons.logout), title: Text('Logout'))),
            ],
            child: Padding(padding: const EdgeInsets.only(right: 8), child: ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryLight), child: const Text('Admin'))),
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
                const Text('Dashboard', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _statCard('Mahasiswa', mahasiswaCount.toString())),
                    const SizedBox(width: 8),
                    Expanded(child: _statCard('Dosen', dosenCount.toString())),
                    const SizedBox(width: 8),
                    Expanded(child: _statCard('Jadwal Kuliah', jadwalCount.toString())),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Buat Pengumuman', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const TextField(decoration: InputDecoration(hintText: 'Subjek', border: OutlineInputBorder())),
                      const SizedBox(height: 8),
                      const TextField(maxLines: 3, decoration: InputDecoration(hintText: 'Informasi Lanjutan', border: OutlineInputBorder())),
                      const SizedBox(height: 8),
                      Row(children: [
                        ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary), child: const Text('Kirim')),
                        const SizedBox(width: 8),
                        ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300]), child: const Text('Grafik', style: TextStyle(color: Colors.black)))
                      ])
                    ]),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Manajemen Data', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageMahasiswaScreen())), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary), child: const Text('Mahasiswa')),
                  ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageDosenScreen())), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary), child: const Text('Dosen')),
                  ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageJadwalScreen())), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary), child: const Text('Jadwal Kuliah')),
                ])
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
