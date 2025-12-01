import 'package:flutter/material.dart';
import '../../models/jadwal_model.dart';
import '../../services/jadwal_service.dart';

class DosenJadwalScreen extends StatefulWidget {
  final String nip;

  const DosenJadwalScreen({super.key, required this.nip});

  @override
  State<DosenJadwalScreen> createState() => _DosenJadwalScreenState();
}

class _DosenJadwalScreenState extends State<DosenJadwalScreen> {
  List<Jadwal> _allJadwal = [];
  List<Jadwal> _filteredJadwal = [];
  String _searchQuery = '';
  String _selectedHari = 'Semua';

  final List<String> hariList = [
    'Semua',
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
  ];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final data = await JadwalService.getJadwalByDosen(widget.nip);
    setState(() {
      _allJadwal = data;
      _filteredJadwal = data;
    });
    applyFilters();
  }

  // Filter search + hari
  void applyFilters() {
    List<Jadwal> result = _allJadwal;

    // filter berdasarkan hari
    if (_selectedHari != 'Semua') {
      result = result.where((j) => j.hari == _selectedHari).toList();
    }

    // filter berdasarkan search
    if (_searchQuery.isNotEmpty) {
      result = result
          .where((j) =>
              j.mataKuliah.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    setState(() {
      _filteredJadwal = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal Saya')),
      body: Column(
        children: [
          // SEARCH
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari mata kuliah...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                _searchQuery = value;
                applyFilters();
              },
            ),
          ),

          // FILTER HARI
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Text(
                  'Filter Hari:',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _selectedHari,
                  items: hariList
                      .map((h) => DropdownMenuItem(
                            value: h,
                            child: Text(h),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedHari = value!;
                    });
                    applyFilters();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // TABEL JADWAL
          Expanded(
            child: _filteredJadwal.isEmpty
                ? const Center(child: Text('Tidak ada jadwal.'))
                : ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      Table(
                        border: TableBorder.all(color: Colors.grey),
                        columnWidths: const {
                          0: FixedColumnWidth(70), // Kode
                          1: FlexColumnWidth(), // Mata Kuliah
                          2: FixedColumnWidth(140), // Info detail
                        },
                        children: [
                          // HEADER
                          TableRow(
                            decoration:
                                BoxDecoration(color: Colors.deepPurple.shade100),
                            children: const [
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  'Kode',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  'Mata Kuliah',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  'Pertemuan',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                            ],
                          ),

                          // DATA ROWS
                          ..._filteredJadwal.map((j) {
                            return TableRow(
                              children: [
                                // Kode
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    j.id,
                                    textAlign: TextAlign.center,
                                  ),
                                ),

                                // Mata kuliah
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        j.mataKuliah,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text('Kelas: -'),
                                    ],
                                  ),
                                ),

                                // Detail
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("Hari: ${j.hari}"),
                                      Text("Jam: ${j.jam}"),
                                      Text("Ruang: ${j.ruang}"),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
