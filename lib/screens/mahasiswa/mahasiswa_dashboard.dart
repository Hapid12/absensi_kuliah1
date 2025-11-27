import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../auth/login_screen.dart';
import 'mahasiswa_absensi_screen.dart';
import 'mahasiswa_informasi_screen.dart';
import 'mahasiswa_jadwal_screen.dart';

class MahasiswaDashboard extends StatelessWidget {
  final String name;
  final String npm;
  // Optional fields to show Fakultas & Prodi without breaking existing callers
  final String fakultas;
  final String prodi;

  const MahasiswaDashboard({
    super.key,
    required this.name,
    required this.npm,
    this.fakultas = '',
    this.prodi = '',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.person),
            SizedBox(width: 8),
            Text('Mahasiswa'),
          ],
        ),
        backgroundColor: AppColors.primary,
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (ctx) => [
              PopupMenuItem(
                child: ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card with profile and basic info (centered)
                Center(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Avatar + Upload button
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 44,
                                backgroundColor: Colors.grey[200],
                                child: const Icon(
                                  Icons.person,
                                  size: 44,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 36,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: AppColors.primary),
                                  ),
                                  onPressed: () {
                                    // TODO: Implement image picker/upload
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Upload photo tapped'),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.upload_file, size: 18),
                                  label: const Text('Upload Foto'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          // Info texts
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'MAHASISWA',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Nama : $name',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'NPM : $npm',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                if (fakultas.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Fakultas : $fakultas',
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                ],
                                if (prodi.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Prodi : $prodi',
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Notification card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: const [
                        Row(
                          children: [
                            Icon(Icons.notifications_active),
                            SizedBox(width: 8),
                            Text('Notifikasi'),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Jadwal Kuliah diubah, materi akan dikirim melalui e-learning',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Expandable spacer so content is centered above bottom icons
          const Expanded(child: SizedBox.shrink()),
        ],
      ),
      // Icon-only bottom bar
      bottomNavigationBar: Container(
        height: 72,
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              tooltip: 'Absensi',
              iconSize: 30,
              color: AppColors.secondary,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MahasiswaAbsensiScreen(npm: npm),
                  ),
                );
              },
              icon: const Icon(Icons.check_circle),
            ),
            IconButton(
              tooltip: 'Jadwal',
              iconSize: 30,
              color: AppColors.success,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MahasiswaJadwalScreen(npm: npm),
                  ),
                );
              },
              icon: const Icon(Icons.calendar_today),
            ),
            IconButton(
              tooltip: 'Informasi',
              iconSize: 30,
              color: AppColors.warning,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MahasiswaInformasiScreen(npm: npm),
                  ),
                );
              },
              icon: const Icon(Icons.info),
            ),
          ],
        ),
      ),
    );
  }
}
