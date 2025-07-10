import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'registerpage.dart';
import 'admin/adminpage.dart';
import 'package:uas_kelompok7/user/userhomepage.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> _login() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email dan password tidak boleh kosong')),
      );
      return;
    }

    try {
      // Menjalankan login
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Periksa apakah login berhasil
      if (response.user != null) {
        // Ambil role pengguna dari database
        final userId = response.user!.id;
        final userResponse = await _supabase
            .from('pelanggan')  // Sesuaikan dengan nama tabel yang menyimpan data pengguna
            .select('role')  // Mengambil role
            .eq('id', userId)
            .single();

        final userRole = userResponse['role'];

        // Arahkan ke halaman sesuai role pengguna
        if (userRole == 'admin') {
          // Jika role adalah admin, arahkan ke halaman admin
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        } else if (userRole == 'user') {
          // Jika role adalah user, arahkan ke halaman user
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => UserPage()),
          );
        } else {
          // Jika role tidak dikenali, tampilkan pesan error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Role tidak dikenali')),
          );
        }
      } else {
        // Jika response.user null, tampilkan pesan kesalahan
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Email atau password salah')),
        );
      }
    } catch (e) {
      // Menangani kesalahan jika ada
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Menambahkan tulisan di atas form login
            Text(
              'Welcome to Enter Elektronik',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Best of the Best',
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.blueGrey,
              ),
            ),
            SizedBox(height: 32), // Memberi jarak antara tulisan dan form login
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible, // Menentukan apakah password visible atau tidak
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    // Tampilkan ikon berdasarkan status visibility password
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    // Toggle status visibility password
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: _login,
              child: Text('Login'),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterPage()),
                );
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero, // Hilangkan padding
                minimumSize: Size(0, 0), // Hilangkan ukuran minimum
                tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Kurangi area klik
                alignment: Alignment.centerLeft, // Sesuaikan posisi teks
              ),
              child: Text(
                'Belum punya akun?',
                style: TextStyle(
                  fontSize: 14, // Sesuaikan ukuran teks
                  color: Colors.blue, // Warna teks (misalnya biru)
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

