// lib/screens/admin/manage_mahasiswa_screen.dart
import 'package:flutter/material.dart';
import '../../models/mahasiswa_model.dart';
import '../../services/db_helper.dart';
import '../../utils/colors.dart';

class ManageMahasiswaScreen extends StatefulWidget {
  const ManageMahasiswaScreen({super.key});

  @override
  State<ManageMahasiswaScreen> createState() => _ManageMahasiswaScreenState();
}

class _ManageMahasiswaScreenState extends State<ManageMahasiswaScreen> {
  List<Mahasiswa> mahasiswaList = [];
  List<Mahasiswa> filteredList = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMahasiswa();
  }

  Future<void> _loadMahasiswa() async {
    final rows = await DBHelper.instance.getAllMahasiswa();
    final list = rows.map((m) => Mahasiswa(
      npm: m['npm'] as String,
      nama: m['nama'] as String,
      prodi: m['prodi'] as String,
    )).toList();
    setState(() {
      mahasiswaList = list;
      filteredList = list;
    });
  }

  void _filterMahasiswa(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredList = mahasiswaList;
      } else {
        filteredList = mahasiswaList
            .where((mhs) =>
                mhs.nama.toLowerCase().contains(query.toLowerCase()) ||
                mhs.npm.toLowerCase().contains(query.toLowerCase()) ||
                mhs.prodi.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _addMahasiswa() {
    final npmController = TextEditingController();
    final namaController = TextEditingController();
    final prodiController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Mahasiswa'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: npmController,
                decoration: const InputDecoration(
                  labelText: 'NPM',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: prodiController,
                decoration: const InputDecoration(
                  labelText: 'Program Studi',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (npmController.text.isNotEmpty &&
                  namaController.text.isNotEmpty &&
                  prodiController.text.isNotEmpty &&
                  passwordController.text.isNotEmpty) {
                final newMhs = Mahasiswa(
                  npm: npmController.text,
                  nama: namaController.text,
                  prodi: prodiController.text,
                );
                await DBHelper.instance.insertMahasiswa({
                  'npm': newMhs.npm,
                  'nama': newMhs.nama,
                  'prodi': newMhs.prodi,
                });
                // Insert user ke tabel users
                await DBHelper.instance.database.then((db) async {
                  await db.insert('users', {
                    'username': newMhs.npm,
                    'password': passwordController.text,
                    'role': 'mahasiswa',
                    'name': newMhs.nama,
                    'npm': newMhs.npm,
                    'nip': null,
                  });
                });
                await _loadMahasiswa();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mahasiswa berhasil ditambahkan')),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _editMahasiswa(int index) {
    final mhs = filteredList[index];
    final actualIndex = mahasiswaList.indexWhere((m) => m.npm == mhs.npm);
    final npmController = TextEditingController(text: mhs.npm);
    final namaController = TextEditingController(text: mhs.nama);
    final prodiController = TextEditingController(text: mhs.prodi);
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Mahasiswa'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: npmController,
                decoration: const InputDecoration(
                  labelText: 'NPM',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: prodiController,
                decoration: const InputDecoration(
                  labelText: 'Program Studi',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password (kosongkan jika tidak diubah)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final updated = Mahasiswa(
                npm: npmController.text,
                nama: namaController.text,
                prodi: prodiController.text,
              );
              await DBHelper.instance.updateMahasiswa(mhs.npm, {
                'npm': updated.npm,
                'nama': updated.nama,
                'prodi': updated.prodi,
              });
              // Update user di tabel users
              await DBHelper.instance.database.then((db) async {
                final updateUser = {
                  'username': updated.npm,
                  'role': 'mahasiswa',
                  'name': updated.nama,
                  'npm': updated.npm,
                  'nip': null,
                };
                if (passwordController.text.isNotEmpty) {
                  updateUser['password'] = passwordController.text;
                }
                await db.update('users', updateUser,
                  where: 'npm = ?', whereArgs: [mhs.npm]);
              });
              await _loadMahasiswa();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mahasiswa berhasil diupdate')),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _deleteMahasiswa(int index) {
    final mhs = filteredList[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Mahasiswa'),
        content: Text('Yakin ingin menghapus ${mhs.nama}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await DBHelper.instance.deleteMahasiswa(mhs.npm);
              await _loadMahasiswa();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mahasiswa berhasil dihapus')),
              );
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Mahasiswa'),
        backgroundColor: AppColors.primary,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: Colors.white,
              ),
              child: const Text('Admin'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterMahasiswa,
                    decoration: InputDecoration(
                      hintText: 'Cari mahasiswa...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _addMahasiswa,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                  child: const Text('Tambah'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'NPM',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Nama',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Prodi',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: Text(
                            'Aksi',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: filteredList.isEmpty
                        ? const Center(
                            child: Text('Tidak ada data mahasiswa'),
                          )
                        : ListView.separated(
                            itemCount: filteredList.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final mhs = filteredList[index];
                              return Container(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Expanded(flex: 2, child: Text(mhs.npm)),
                                    Expanded(flex: 3, child: Text(mhs.nama)),
                                    Expanded(flex: 2, child: Text(mhs.prodi)),
                                    SizedBox(
                                      width: 100,
                                      child: Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: AppColors.secondary,
                                              size: 20,
                                            ),
                                            onPressed: () =>
                                                _editMahasiswa(index),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: AppColors.danger,
                                              size: 20,
                                            ),
                                            onPressed: () =>
                                                _deleteMahasiswa(index),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}