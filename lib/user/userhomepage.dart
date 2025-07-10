import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uas_kelompok7/user/usersidebar.dart';

class UserPage extends StatefulWidget {
  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _produkList = [];
  List<Map<String, dynamic>> _filteredProdukList = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProduk();
  }

  // Fungsi untuk mengambil data produk dari database
  Future<void> _fetchProduk() async {
    try {
      final response = await _supabase
          .from('produk')
          .select()
          .order('stok', ascending: true) // Mengurutkan berdasarkan stok produk
          .limit(10); // Misal ambil hanya 10 produk pertama

      if (response == null || response.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data produk tidak ditemukan')),
        );
      } else {
        setState(() {
          _produkList = List<Map<String, dynamic>>.from(response);
          _filteredProdukList = List<Map<String, dynamic>>.from(response); // Initialize filtered list
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  // Fungsi untuk memfilter produk berdasarkan pencarian
  void _filterProduk(String query) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _filteredProdukList = _produkList
              .where((produk) => produk['nama_barang']
              .toLowerCase()
              .contains(query.toLowerCase()))
              .toList();
        });
      }
    });
  }

  // Fungsi untuk menampilkan dialog detail produk
  void _showProductDetailDialog(Map<String, dynamic> produk) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(produk['nama_barang']),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              produk['pics'] != null && produk['pics'].isNotEmpty
                  ? Image.network(produk['pics'], height: 200, width: 200, fit: BoxFit.cover)
                  : Container(
                color: Colors.grey[200],
                height: 200,
                child: Center(child: Icon(Icons.image, size: 50, color: Colors.grey)),
              ),
              SizedBox(height: 16),
              Text('Harga: Rp. ${produk['harga']}'),
              SizedBox(height: 16),
              Text('Stok: ${produk['stok']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Happy Shoppping'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: ProductSearchDelegate(
                    allProducts: _produkList,
                    filterProducts: _filterProduk,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      drawer: UserSidebar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _filteredProdukList.isEmpty
            ? Center(child: CircularProgressIndicator())
            : GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Menentukan jumlah kolom (2 kolom per baris)
            crossAxisSpacing: 10.0, // Jarak horizontal antar item
            mainAxisSpacing: 10.0, // Jarak vertikal antar item
            childAspectRatio: 2 / 3, // Rasio lebar dan tinggi item
          ),
          itemCount: _filteredProdukList.length,
          itemBuilder: (context, index) {
            final produk = _filteredProdukList[index];
            final imageUrl = produk['pics']; // Ambil URL gambar dari kolom 'pics'

            return GestureDetector(
              onTap: () {
                _showProductDetailDialog(produk); // Menampilkan dialog saat card ditekan
              },
              child: Card(
                elevation: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? Container(
                        width: double.infinity,
                        height: 100,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              return child;
                            }
                            return Center(
                              child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                      (loadingProgress.expectedTotalBytes ?? 1)
                                      : null),
                            );
                          },
                        ),
                      )
                          : Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: Icon(
                            Icons.image,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        produk['nama_barang'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('Harga: Rp. ${produk['harga']}'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ProductSearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> allProducts;
  final Function(String) filterProducts;

  ProductSearchDelegate({
    required this.allProducts,
    required this.filterProducts,
  });

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
          filterProducts(query); // Reset filter dan tampilkan semua produk
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return Center(child: Text('Tidak ada produk yang ditampilkan.'));
    }

    final filteredProducts = allProducts
        .where((produk) => produk['nama_barang']
        .toLowerCase()
        .contains(query.toLowerCase()))
        .toList();

    return filteredProducts.isEmpty
        ? Center(child: Text('Tidak ada produk yang cocok dengan pencarian Anda.'))
        : _buildProductList(filteredProducts);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Center(child: Text('Masukkan kata kunci untuk mencari produk.'));
    }

    filterProducts(query);
    final filteredProducts = allProducts
        .where((produk) => produk['nama_barang']
        .toLowerCase()
        .contains(query.toLowerCase()))
        .toList();

    return filteredProducts.isEmpty
        ? Center(child: Text('Tidak ada produk yang cocok dengan pencarian Anda.'))
        : _buildProductList(filteredProducts);
  }

  Widget _buildProductList(List<Map<String, dynamic>> filteredProducts) {
    return ListView.builder(
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final produk = filteredProducts[index];
        final imageUrl = produk['pics'];
        return ListTile(
          leading: imageUrl != null && imageUrl.isNotEmpty
              ? Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover)
              : Icon(Icons.image, size: 50),
          title: Text(produk['nama_barang']),
          subtitle: Text('Harga: Rp. ${produk['harga']}'),
          onTap: () {
            // Handle product selection
          },
        );
      },
    );
  }
}
