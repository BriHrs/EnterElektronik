import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uas_kelompok7/user/product.dart';
import 'package:uas_kelompok7/user/profilepageuser.dart';
import 'package:uas_kelompok7/user/userhomepage.dart';
import '../loginpage.dart';
import 'package:uas_kelompok7/user/cart.dart';
import 'pesanan.dart';

class UserSidebar extends StatefulWidget {
  @override
  _UserSidebarState createState() => _UserSidebarState();
}

class _UserSidebarState extends State<UserSidebar> {
  String _username = 'Pengguna'; // Default username

  @override
  void initState() {
    super.initState();
    _fetchUsername(); // Ambil username saat widget dimuat
  }

  Future<void> _fetchUsername() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pengguna belum login')),
        );
        return;
      }

      final response = await Supabase.instance.client
          .from('pelanggan')
          .select('username')
          .eq('id', userId)
          .single();

      if (response != null) {
        setState(() {
          _username = response['username'] ?? 'Pengguna';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'Hi, $_username!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Beranda'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => UserPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.receipt),
            title: Text('Pesanan'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserPesananPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.shopping_cart),
            title: Text('Keranjang'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Profil'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileUserPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.production_quantity_limits),
            title: Text('Produk'),
            onTap: () async {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ProdukUserPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Keluar'),
            onTap: () async {
              try {
                await Supabase.instance.client.auth.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal logout: $e')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
