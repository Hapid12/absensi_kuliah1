import 'package:flutter/material.dart';
import 'dart:async';
import '../../utils/colors.dart';
import '../auth/login_screen.dart';
import 'mahasiswa_absensi_screen.dart';
import 'mahasiswa_informasi_screen.dart';
import 'mahasiswa_jadwal_screen.dart';
import '../../services/db_helper.dart';
import '../../services/jadwal_service.dart';

class MahasiswaDashboard extends StatefulWidget {
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
  State<MahasiswaDashboard> createState() => _MahasiswaDashboardState();
}

class _MahasiswaDashboardState extends State<MahasiswaDashboard> {
  List<Map<String, dynamic>> _announcements = [];
  bool _loadingAnnouncements = true;
  StreamSubscription<void>? _annSub;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
    _annSub = DBHelper.instance.announcementsStream.listen((_) {
      _loadAnnouncements();
    });
  }

  @override
  void dispose() {
    _annSub?.cancel();
    super.dispose();
  }

  Future<void> _loadAnnouncements() async {
    setState(() {
      _loadingAnnouncements = true;
    });
    try {
      // Get all jadwals and filter to those that include this npm
      final all = await JadwalService.getAllJadwal();
      final myJadwals = all
          .where((j) => j.peserta.contains(widget.npm))
          .toList();
      final ids = myJadwals.map((j) => j.id).toList();
      final rows = await DBHelper.instance.getAnnouncementsByJadwalIds(ids);
      setState(() {
        _announcements = rows;
      });
    } catch (e) {
      // ignore or log
      setState(() {
        _announcements = [];
      });
    } finally {
      setState(() {
        _loadingAnnouncements = false;
      });
    }
  }

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
                                  'Nama : ${widget.name}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'NPM : ${widget.npm}',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                if (widget.fakultas.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Fakultas : ${widget.fakultas}',
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                ],
                                if (widget.prodi.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Prodi : ${widget.prodi}',
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
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.notifications_active),
                            SizedBox(width: 8),
                            Text('Notifikasi'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildAnnouncementsSection(),
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
                    builder: (_) => MahasiswaAbsensiScreen(npm: widget.npm),
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
                    builder: (_) => MahasiswaJadwalScreen(npm: widget.npm),
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
                    builder: (_) => MahasiswaInformasiScreen(npm: widget.npm),
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

  Widget _buildAnnouncementsSection() {
    if (_loadingAnnouncements) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_announcements.isEmpty) {
      return const Text('Belum ada notifikasi.');
    }
    return Column(
      children: _announcements.map((a) {
        final createdAt = a['createdAt'] as String? ?? '';
        final mata = a['mataKuliah'] as String? ?? '';
        final message = a['message'] as String? ?? '';
        return ListTile(
          dense: true,
          title: Text(
            mata,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(message),
          trailing: Text(
            createdAt.isNotEmpty ? createdAt.split('T').first : '',
            style: const TextStyle(fontSize: 10),
          ),
        );
      }).toList(),
    );
  }
}
