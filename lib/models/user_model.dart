class User {
  final String username;
  final String password;
  final String role; // 'admin' | 'dosen' | 'mahasiswa'
  final String name;
  final String? nip;
  final String? npm;

  User({required this.username, required this.password, required this.role, required this.name, this.nip, this.npm});
}
