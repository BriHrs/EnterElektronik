import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uas_kelompok7/admin/sidebar.dart';
import 'package:uas_kelompok7/admin/updateprofilepage.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _supabase = Supabase.instance.client;
  late User? _user;
  String _username = '';
  String _email = '';
  String _phone = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      // Mendapatkan user yang sedang login
      _user = _supabase.auth.currentUser;

      if (_user != null) {
        // Mendapatkan data profil pengguna dari tabel 'pelanggan'
        final response = await _supabase
            .from('pelanggan')
            .select('username, nomor_hp')
            .eq('id', _user!.id)
            .single();  // Use single to get only one result

        if (response != null) {
          setState(() {
            _username = response['username'] ?? '';
            _phone = response['nomor_hp'].toString(); // Ensure it's string
            _email = _user!.email ?? '';
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat profil: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profil Pengguna"),
        actions: [
          // Add an Edit Icon Button on the top-right of the AppBar
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              // Navigate to UpdateProfilePage when the icon is clicked
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UpdateProfilePage()),
              );
            },
          ),
        ],
      ),
      drawer: Sidebar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Email: $_email", style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text("Username: $_username", style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text("Nomor HP: $_phone", style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
