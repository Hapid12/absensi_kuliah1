import '../models/mahasiswa_model.dart';
import '../models/dosen_model.dart';
import '../models/jadwal_model.dart';
import '../models/user_model.dart';
import '../models/announcement_model.dart';

class DummyData {
  static List<Mahasiswa> mahasiswaList = [
    Mahasiswa(npm: '190001', nama: 'Ani Wijaya', prodi: 'Manajemen Informatika'),
    Mahasiswa(npm: '190002', nama: 'Budi Santoso', prodi: 'Manajemen Informatika'),
    Mahasiswa(npm: '190003', nama: 'Citra Lestari', prodi: 'Manajemen Informatika'),
  ];

  static List<Dosen> dosenList = [
    Dosen(nip: 'D001', nama: 'Dr. Agus', mataKuliah: 'Pemrograman Mobile'),
    Dosen(nip: 'D002', nama: 'Ibu Sari', mataKuliah: 'Basis Data'),
  ];

  static List<Jadwal> jadwalList = [
    Jadwal(id: 'J1', mataKuliah: 'Pemrograman Mobile', hari: 'Senin', jam: '09:00-11:00', ruang: 'R101', dosenNip: 'D001', peserta: ['190001','190002']),
    Jadwal(id: 'J2', mataKuliah: 'Basis Data', hari: 'Selasa', jam: '13:00-15:00', ruang: 'R102', dosenNip: 'D002', peserta: ['190002','190003']),
  ];

  // attendance records: key = jadwal.id, value = list of npm of present students
  static Map<String, List<String>> attendanceRecords = {
    'J1': ['190001'],
    'J2': [],
  };

  // announcements
  static List<Announcement> announcements = [
    Announcement(id: 'A1', jadwalId: 'J1', title: 'Pengumuman Pertama', message: 'Jangan lupa bawa laptop saat kuliah.'),
  ];

  static List<User> users = [
    User(username: 'admin', password: 'admin', role: 'admin', name: 'Administrator'),
    User(username: 'dosen1', password: '1234', role: 'dosen', name: 'Dr. Agus', nip: 'D001'),
    User(username: 'mhs1', password: '1234', role: 'mahasiswa', name: 'Ani Wijaya', npm: '190001'),
  ];
}
