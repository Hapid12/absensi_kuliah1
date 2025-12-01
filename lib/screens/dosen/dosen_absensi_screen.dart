import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../models/jadwal_model.dart';
import '../../screens/dosen/dosen_kelola_absensi_screen.dart';
import '../../services/dosen_service.dart';

class DosenAbsensiScreen extends StatelessWidget {
  final Jadwal jadwal;
  final bool sudahAbsenDosen;

  const DosenAbsensiScreen({
    super.key,
    required this.jadwal,
    required this.sudahAbsenDosen,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text("Absensi Kehadiran"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =========================
            //     HEADER MATA KULIAH (mirip gambar)
            // =========================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF3B1E6A), // ungu gelap
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueAccent.shade100, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "ABSENSI KELAS ${jadwal.id}",
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "KODE MK - ${jadwal.mataKuliah}",
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "PERTEMUAN KE-1 | SKS MENGAJAR 2",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // =========================
            //         INFO ABSEN (latar ungu muda)
            // =========================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xffefe6ff), // ungu muda
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "INFO ABSENSI",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    sudahAbsenDosen ? "Anda sudah absen" : "Anda belum absen",
                    style: const TextStyle(fontSize: 13),
                  ),

                  const SizedBox(height: 16),

                  // =========================
                  //         TABEL (simple)
                  // =========================
                  Table(
                    border: TableBorder.all(color: Colors.black45, width: 1),
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      TableRow(
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade100,
                        ),
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(6),
                            child: Text(
                              "Kelas",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(6),
                            child: Text(
                              "Gedung",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(6),
                            child: Text(
                              "Ruang",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(6),
                            child: Text(
                              "Jam Mulai",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(6),
                            child: Text(
                              "Jam Berakhir",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),

                      TableRow(
                        children: [
                          tableCell(jadwal.id),
                          tableCell("Gedung Mipa"),
                          tableCell(jadwal.ruang),
                          tableCell("20-10-2025 10:45"),
                          tableCell("20-10-2025 11:55"),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // =========================
                  //         TOMBOL
                  // =========================
                  Row(
                    children: [
                      // KELOLA ABSEN (mengganti Edit Absen)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            // buka layar kelola absen
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DosenKelolaAbsensiScreen(
                                  jadwalId: jadwal.id,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text("Kelola Absen"),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // PENGUMUMAN -> popup untuk menulis pengumuman
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) {
                                final TextEditingController ctrl =
                                    TextEditingController();
                                bool sending = false;
                                return StatefulBuilder(
                                  builder: (c, setState) => AlertDialog(
                                    title: const Text("Kirim Pengumuman"),
                                    content: TextField(
                                      controller: ctrl,
                                      maxLines: 5,
                                      decoration: const InputDecoration(
                                        hintText:
                                            "Tulis pengumuman untuk mahasiswa...",
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: sending
                                            ? null
                                            : () => Navigator.pop(ctx),
                                        child: const Text("Batal"),
                                      ),
                                      ElevatedButton(
                                        onPressed: sending
                                            ? null
                                            : () async {
                                                final text = ctrl.text.trim();
                                                if (text.isEmpty) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        "Isi pengumuman terlebih dahulu",
                                                      ),
                                                    ),
                                                  );
                                                  return;
                                                }
                                                setState(() {
                                                  sending = true;
                                                });
                                                // Store announcement (persist) using service
                                                await DosenService.postAnnouncement(
                                                  jadwal.id,
                                                  jadwal.mataKuliah,
                                                  text,
                                                  subject: '',
                                                );
                                                setState(() {
                                                  sending = false;
                                                });
                                                Navigator.pop(ctx);
                                                // show success dialog
                                                await showDialog(
                                                  context: context,
                                                  builder: (ctx2) => AlertDialog(
                                                    title: const Text(
                                                      'Berhasil',
                                                    ),
                                                    content: const Text(
                                                      'Pengumuman berhasil dikirim.',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(ctx2),
                                                        child: const Text('OK'),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      "Pengumuman terkirim",
                                                    ),
                                                  ),
                                                );
                                              },
                                        child: sending
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Text("Kirim"),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text("Pengumuman"),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // ABSEN (tidak diubah)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text("Absen"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget tableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}
