import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../auth/login_screen.dart';
import 'mahasiswa_absensi_screen.dart';
import 'mahasiswa_informasi_screen.dart';
import 'mahasiswa_jadwal_screen.dart';

class MahasiswaDashboard extends StatelessWidget {
  final String name;
  final String npm;
  const MahasiswaDashboard({Key? key, required this.name, required this.npm}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: const [Icon(Icons.person), SizedBox(width: 8), Text('Mahasiswa')]),
        backgroundColor: AppColors.primary,
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (ctx) => [
              PopupMenuItem(child: ListTile(leading: const Icon(Icons.logout), title: const Text('Logout'), onTap: () {
                Navigator.pop(ctx);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              })),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Halo, $name, apa kabar, $name', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('NPM: $npm', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(children: const [
                    Row(children: [Icon(Icons.notifications_active), SizedBox(width: 8), Text('Notifikasi')]),
                    SizedBox(height: 8),
                    Text('Jadwal Kuliah diubah, materi akan dikirim melalui e-learning')
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
                _buildMenuCard(context, 'Absensi', Icons.check_circle, AppColors.secondary, () => Navigator.push(context, MaterialPageRoute(builder: (_) => MahasiswaAbsensiScreen(npm: npm)))),
                _buildMenuCard(context, 'Jadwal', Icons.calendar_today, AppColors.success, () => Navigator.push(context, MaterialPageRoute(builder: (_) => MahasiswaJadwalScreen(npm: npm)))),
                _buildMenuCard(context, 'Informasi', Icons.info, AppColors.warning, () => Navigator.push(context, MaterialPageRoute(builder: (_) => MahasiswaInformasiScreen(npm: npm)))),
              ],
            ),
          ),
          Container(
            height: 70,
            decoration: const BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: const [Icon(Icons.home, color: Colors.white), Icon(Icons.note, color: Colors.white), Icon(Icons.calendar_today, color: Colors.white), Icon(Icons.person, color: Colors.white)]),
          )
        ],
      ),
    );
  }
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
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 48, color: color), const SizedBox(height: 12), Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))]),
      ),
    ),
  );
}
