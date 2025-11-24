import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../dosen/dosen_dashboard.dart';
import '../mahasiswa/mahasiswa_dashboard.dart';
import '../admin/admin_dashboard.dart';
import '../../utils/colors.dart';

class LoginScreen extends StatefulWidget {
	const LoginScreen({Key? key}) : super(key: key);

	@override
	State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
	final TextEditingController _idController = TextEditingController();
	final TextEditingController _passController = TextEditingController();
	bool _loading = false;

	void _doLogin() async {
		final id = _idController.text.trim();
		final p = _passController.text.trim();
		if (id.isEmpty || p.isEmpty) {
			ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lengkapi NPM/NIP dan Password')));
			return;
		}
		setState(() => _loading = true);
		final user = await AuthService.login(id, p);
		setState(() => _loading = false);
		if (user == null) {
			ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login gagal: cek NPM/NIP dan Password')));
			return;
		}
		if (user.role == 'admin') {
			Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
		} else if (user.role == 'dosen') {
			Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DosenDashboard(name: user.name, nip: user.nip ?? '')));
		} else {
			Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MahasiswaDashboard(name: user.name, npm: user.npm ?? '')));
		}
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: Colors.grey[200],
			body: Center(
				child: SingleChildScrollView(
					padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
					child: Column(
						mainAxisSize: MainAxisSize.min,
						children: [
							const SizedBox(height: 12),
							// logo and title
							Column(
								children: [
									Container(
										width: 120,
										height: 120,
										decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
										child: const Icon(Icons.school, size: 72, color: Colors.white),
									),
									const SizedBox(height: 16),
									const Text('AGENDA KULIAH', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
								],
							),
							const SizedBox(height: 24),

							// white card
							Container(
								width: double.infinity,
								decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
								padding: const EdgeInsets.all(18),
								child: Column(children: [
									const Align(alignment: Alignment.centerLeft, child: Text('Log in', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
									const SizedBox(height: 12),
									TextField(controller: _idController, decoration: const InputDecoration(labelText: 'NPM/NIP', border: OutlineInputBorder())),
									const SizedBox(height: 12),
									TextField(controller: _passController, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
									const SizedBox(height: 16),
									SizedBox(
										width: double.infinity,
										child: ElevatedButton(
											onPressed: _loading ? null : _doLogin,
											style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
											child: _loading ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Log in'),
										),
									),
								]),
							),
							const SizedBox(height: 12),
							const Text('Contoh akun: admin/admin, dosen1/1234, mhs1/1234', style: TextStyle(color: Colors.black54)),
						],
					),
				),
			),
		);
	}
}
