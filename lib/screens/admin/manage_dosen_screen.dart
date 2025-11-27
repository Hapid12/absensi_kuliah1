// lib/screens/admin/manage_dosen_screen.dart
import 'package:flutter/material.dart';
import '../../models/dosen_model.dart';
import '../../services/db_helper.dart';
import '../../utils/colors.dart';

class ManageDosenScreen extends StatefulWidget {
  const ManageDosenScreen({super.key});

  @override
  State<ManageDosenScreen> createState() => _ManageDosenScreenState();
}

class _ManageDosenScreenState extends State<ManageDosenScreen> {
  List<Dosen> dosenList = [];
  List<Dosen> filteredList = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDosen();
  }

  Future<void> _loadDosen() async {
    final rows = await DBHelper.instance.getAllDosen();
    final list = rows.map((d) => Dosen(
      nip: d['nip'] as String,
      nama: d['nama'] as String,
      mataKuliah: d['mataKuliah'] as String,
    )).toList();
    setState(() {
      dosenList = list;
      filteredList = list;
    });
  }

  void _filterDosen(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredList = dosenList;
      } else {
        filteredList = dosenList
            .where((dosen) =>
                dosen.nama.toLowerCase().contains(query.toLowerCase()) ||
                dosen.nip.toLowerCase().contains(query.toLowerCase()) ||
                dosen.mataKuliah.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _addDosen() {
    final nipController = TextEditingController();
    final namaController = TextEditingController();
    final mkController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Dosen'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nipController,
                decoration: const InputDecoration(
                  labelText: 'NIP',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Dosen',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: mkController,
                decoration: const InputDecoration(
                  labelText: 'Jurusan',
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
              if (nipController.text.isNotEmpty &&
                  namaController.text.isNotEmpty &&
                  mkController.text.isNotEmpty &&
                  passwordController.text.isNotEmpty) {
                final newDosen = Dosen(
                  nip: nipController.text,
                  nama: namaController.text,
                  mataKuliah: mkController.text,
                );
                await DBHelper.instance.insertDosen({
                  'nip': newDosen.nip,
                  'nama': newDosen.nama,
                  'mataKuliah': newDosen.mataKuliah,
                });
                // Insert user ke tabel users
                await DBHelper.instance.database.then((db) async {
                  await db.insert('users', {
                    'username': newDosen.nip,
                    'password': passwordController.text,
                    'role': 'dosen',
                    'name': newDosen.nama,
                    'nip': newDosen.nip,
                    'npm': null,
                  });
                });
                await _loadDosen();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dosen berhasil ditambahkan')),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _editDosen(int index) {
    final dosen = filteredList[index];
    final actualIndex = dosenList.indexWhere((d) => d.nip == dosen.nip);
    final nipController = TextEditingController(text: dosen.nip);
    final namaController = TextEditingController(text: dosen.nama);
    final mkController = TextEditingController(text: dosen.mataKuliah);
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Dosen'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nipController,
                decoration: const InputDecoration(
                  labelText: 'NIP',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Dosen',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: mkController,
                decoration: const InputDecoration(
                  labelText: 'Jurusan',
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
              final updated = Dosen(
                nip: nipController.text,
                nama: namaController.text,
                mataKuliah: mkController.text,
              );
              await DBHelper.instance.updateDosen(dosen.nip, {
                'nip': updated.nip,
                'nama': updated.nama,
                'mataKuliah': updated.mataKuliah,
              });
              // Update user di tabel users
              await DBHelper.instance.database.then((db) async {
                final updateUser = {
                  'username': updated.nip,
                  'role': 'dosen',
                  'name': updated.nama,
                  'nip': updated.nip,
                  'npm': null,
                };
                if (passwordController.text.isNotEmpty) {
                  updateUser['password'] = passwordController.text;
                }
                await db.update('users', updateUser,
                  where: 'nip = ?', whereArgs: [dosen.nip]);
              });
              await _loadDosen();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dosen berhasil diupdate')),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _deleteDosen(int index) {
    final dosen = filteredList[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Dosen'),
        content: Text('Yakin ingin menghapus ${dosen.nama}?'),
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
              await DBHelper.instance.deleteDosen(dosen.nip);
              await _loadDosen();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dosen berhasil dihapus')),
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
        title: const Text('Data Dosen'),
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
                    onChanged: _filterDosen,
                    decoration: InputDecoration(
                      hintText: 'Cari dosen...',
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
                  onPressed: _addDosen,
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
                            'NIP',
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
                            'Jurusan',
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
                            child: Text('Tidak ada data dosen'),
                          )
                        : ListView.separated(
                            itemCount: filteredList.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final dosen = filteredList[index];
                              return Container(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Expanded(flex: 2, child: Text(dosen.nip)),
                                    Expanded(flex: 3, child: Text(dosen.nama)),
                                    Expanded(
                                      flex: 2,
                                      child: Text(dosen.mataKuliah),
                                    ),
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
                                            onPressed: () => _editDosen(index),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: AppColors.danger,
                                              size: 20,
                                            ),
                                            onPressed: () => _deleteDosen(index),
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