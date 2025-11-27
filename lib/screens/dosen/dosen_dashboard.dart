// lib/screens/dosen/dosen_dashboard.dart
import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../auth/login_screen.dart';
import 'dosen_absensi_screen.dart';
import 'dosen_jadwal_screen.dart';
import 'dosen_informasi_screen.dart';

class DosenDashboard extends StatelessWidget {
  final String name;
  final String nip;
  const DosenDashboard({super.key, required this.name, required this.nip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.school, size: 30),
            const SizedBox(width: 10),
            const Text('Agenda Kuliah'),
          ],
        ),
        backgroundColor: AppColors.primary,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: Colors.white,
              ),
              child: const Text('Dosen'),
            ),
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Selamat datang, $name', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('NIP: $nip', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(children: [
                    Row(children: const [Icon(Icons.info_outline), SizedBox(width: 8), Text('Informasi')]),
                    const SizedBox(height: 8),
                    const Text('Sistem belum mengalami update')
                  ]),
                ),
              ),
            ]),
          ),
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildMenuCard(context, 'Absensi', Icons.check_circle, AppColors.secondary, () => Navigator.push(context, MaterialPageRoute(builder: (_) => DosenAbsensiScreen(nip: nip)))),
                _buildMenuCard(context, 'Jadwal', Icons.calendar_today, AppColors.success, () => Navigator.push(context, MaterialPageRoute(builder: (_) => DosenJadwalScreen(nip: nip)))),
                _buildMenuCard(context, 'Informasi', Icons.info, AppColors.warning, () => Navigator.push(context, MaterialPageRoute(builder: (_) => DosenInformasiScreen(nip: nip)))),
                _buildMenuCard(context, 'Nilai', Icons.grade, Colors.purple, () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur Nilai akan segera hadir')))),
              ],
            ),
          ),
          // bottom nav / decorative footer
          Container(
            height: 70,
            decoration: const BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: const [Icon(Icons.home, color: Colors.white), Icon(Icons.note, color: Colors.white), Icon(Icons.calendar_today, color: Colors.white), Icon(Icons.person, color: Colors.white)]),
          )
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}