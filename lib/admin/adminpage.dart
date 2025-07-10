import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uas_kelompok7/admin/sidebar.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _bestSellers = [];
  List<Map<String, dynamic>> _recentOrders = []; // Menambahkan variabel untuk pesanan terbaru
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _fetchRecentOrders(); // Ambil pesanan terbaru
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _supabase
          .from('produk')
          .select('id, nama_barang, stok , pics')
          .order('stok', ascending: true);

      if (response != null && response is List) {
        final products = List<Map<String, dynamic>>.from(response);
        final bestSellers = products.where((produk) => produk['stok'] <= 5).toList();

        setState(() {
          _allProducts = products;
          _bestSellers = bestSellers;
        });
      } else {
        throw Exception('Gagal memuat produk: Data tidak valid.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchRecentOrders() async {
    try {
      final response = await _supabase
          .from('transaksi')
          .select('id_transaksi, jumlah_barang, total_harga, pelanggan(username, nomor_hp), produk(nama_barang)')
          .order('id_transaksi', ascending: false)
          .limit(5); // Batasi 5 pesanan terbaru

      if (response != null && response is List) {
        final orders = List<Map<String, dynamic>>.from(response);

        setState(() {
          _recentOrders = orders;
        });
      } else {
        throw Exception('Gagal memuat pesanan: Data tidak valid.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Penjualan Elektronik")),
      drawer: Sidebar(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Semua Produk",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            _buildProductList(_allProducts),

            SizedBox(height: 16),

            Text(
              "Produk Best Seller",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            _bestSellers.isNotEmpty
                ? _buildProductList(_bestSellers)
                : Text("Tidak ada produk best seller saat ini."),

            SizedBox(height: 16),

            Text(
              "Pesanan Terbaru",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            _recentOrders.isNotEmpty
                ? _buildOrderList(_recentOrders)
                : Text("Tidak ada pesanan terbaru."),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList(List<Map<String, dynamic>> produkList) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: produkList.length,
      itemBuilder: (context, index) {
        final produk = produkList[index];
        final imageUrl = produk['pics'];
        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                : Icon(Icons.image, size: 50),
            title: Text(produk['nama_barang']),
            subtitle: Text("Stok: ${produk['stok']}"),
          ),
        );
      },
    );
  }

  Widget _buildOrderList(List<Map<String, dynamic>> orderList) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: orderList.length,
      itemBuilder: (context, index) {
        final order = orderList[index];
        final customerName = order['pelanggan']['username'] ?? 'Nama tidak tersedia';
        final customerPhone = order['pelanggan']['nomor_hp']?.toString() ?? 'Nomor tidak tersedia';
        final productName = order['produk']['nama_barang'] ?? 'Produk tidak tersedia';
        final quantity = order['jumlah_barang'] ?? 0;
        final totalPrice = order['total_harga'] ?? 0;

        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text("Pemesan: $customerName"),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Barang: $productName"),
                Text("Total Harga: Rp$totalPrice"),
              ],
            ),
          ),
        );
      },
    );
  }
}
