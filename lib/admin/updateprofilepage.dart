import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'sidebar.dart';

class UpdateProfilePage extends StatefulWidget {
  @override
  _UpdateProfilePageState createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  final _supabase = Supabase.instance.client;
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _currentUsername = '';
  String _currentPhone = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  Future<void> _loadCurrentProfile() async {
    try {
      // Mendapatkan user yang sedang login
      final user = _supabase.auth.currentUser;

      if (user != null) {
        // Mendapatkan data profil pengguna dari tabel 'pelanggan'
        final response = await _supabase
            .from('pelanggan')
            .select('username, nomor_hp')
            .eq('id', user.id)
            .single();

        if (response != null) {
          setState(() {
            _currentUsername = response['username'] ?? '';
            _currentPhone = response['nomor_hp'].toString();
            _usernameController.text = _currentUsername;
            _phoneController.text = _currentPhone;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat profil: $e')),
      );
    }
  }

  Future<void> _updateProfile() async {
    final newUsername = _usernameController.text.trim();
    final newPhone = _phoneController.text.trim();

    if (newUsername.isEmpty || newPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Semua kolom wajib diisi')),
      );
      return;
    }

    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        // Update data profil pengguna di tabel 'pelanggan'
        final response = await _supabase.from('pelanggan').update({
          'username': newUsername,
          'nomor_hp': int.parse(newPhone),
        }).eq('id', user.id).select();

        if (response != null && response.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profil berhasil diperbarui')),
          );
          Navigator.pop(context); // Kembali ke halaman sebelumnya
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memperbarui profil.')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Update Profil"),
      ),
      drawer: Sidebar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Username", style: TextStyle(fontSize: 16)),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  hintText: 'Masukkan username baru',
                ),
              ),
              SizedBox(height: 16),
              Text("Nomor HP", style: TextStyle(fontSize: 16)),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Masukkan nomor HP baru',
                ),
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _updateProfile,
                child: Text('Perbarui Profil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

