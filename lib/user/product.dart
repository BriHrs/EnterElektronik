import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uas_kelompok7/user/usersidebar.dart';
import 'checkoutpage.dart';

class ProdukUserPage extends StatefulWidget {
  @override
  _ProdukPageState createState() => _ProdukPageState();
}

class _ProdukPageState extends State<ProdukUserPage> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _produkList = [];
  List<Map<String, dynamic>> cartItems = [];
  String? _cartId; // ID keranjang untuk user
  String? _idPelanggan; // ID pelanggan dari tabel pelanggan

  @override
  void initState() {
    super.initState();
    _fetchUserAndCartData(); // Ambil data pelanggan dan keranjang saat halaman dimuat
    _fetchProduk();
  }

  Future<void> _fetchUserAndCartData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pengguna belum login')),
        );
        return;
      }

      final pelangganResponse = await _supabase
          .from('pelanggan')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (pelangganResponse == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data pelanggan tidak ditemukan')),
        );
      } else {
        _idPelanggan = pelangganResponse['id'];

        final cartResponse = await _supabase
            .from('cart')
            .select('id')
            .eq('id_pelanggan', _idPelanggan!)
            .maybeSingle();

        if (cartResponse == null) {
          final newCartResponse = await _supabase.from('cart').insert({
            'id_pelanggan': _idPelanggan,
          }).select('id').single();

          _cartId = newCartResponse['id'] as String?;
        } else {
          _cartId = cartResponse['id'] as String?;
        }

        if (_cartId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ID keranjang tidak tersedia')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kesalahan: $e')),
      );
    }
  }

  Future<void> _fetchProduk() async {
    try {
      final response = await _supabase.from('produk').select();
      if (response != null) {
        setState(() {
          _produkList = response.where((produk) => produk['stok'] > 0).toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data produk tidak ditemukan')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kesalahan: $e')),
      );
    }
  }

  Future<void> _showCheckoutDialog(int idProduk) async {
    TextEditingController addressController = TextEditingController();
    int jumlahBarang = 1;  // Menginisialisasi jumlah barang yang dibeli
    TextEditingController controller = TextEditingController(text: jumlahBarang.toString());

    // Mengambil data produk berdasarkan idProduk
    final response = await _supabase
        .from('produk')
        .select()
        .eq('id', idProduk)
        .single()
        .maybeSingle();

    if (response == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Produk tidak ditemukan')),
      );
      return;
    }

    // Mendapatkan data produk yang ditemukan
    var produkData = response;
    int stok = produkData['stok'];  // Ambil stok produk

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Konfirmasi Checkout'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Input alamat pengiriman
              Text('Masukkan alamat pengiriman:'),
              TextField(
                controller: addressController,
                decoration: InputDecoration(hintText: 'Alamat'),
              ),
              SizedBox(height: 10),

              // Menampilkan detail produk
              Text('Produk yang akan dibeli:'),
              Text("${produkData['nama_barang']} - Rp${produkData['harga']}"),

              SizedBox(height: 20),

              // Quantity selector dengan tombol + dan - dengan pembatasan stok
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.remove),
                    onPressed: () {
                      if (jumlahBarang > 1) {
                        setState(() {
                          jumlahBarang--;
                          controller.text = jumlahBarang.toString();
                        });
                      }
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(hintText: 'Jumlah'),
                      onChanged: (value) {
                        int parsedValue = int.tryParse(value) ?? 1;
                        setState(() {
                          jumlahBarang = parsedValue > stok ? stok : parsedValue;
                          controller.text = jumlahBarang.toString();
                        });
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      // Hanya memungkinkan penambahan jika jumlahBarang < stok
                      if (jumlahBarang < stok) {
                        setState(() {
                          jumlahBarang++;
                          controller.text = jumlahBarang.toString();
                        });
                      }
                    },
                  ),
                ],
              ),
              // Menampilkan stok produk yang tersedia
              SizedBox(height: 10),
              Text('Stok tersedia: $stok'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (addressController.text.isNotEmpty) {
                  // Kirim idProduk, jumlahBarang, dan alamat ke fungsi checkout
                  _checkout(idProduk, jumlahBarang, addressController.text);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Alamat tidak boleh kosong')),
                  );
                }
              },
              child: Text('Lanjutkan'),
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
        title: Text("Produk"),
      ),
      drawer: UserSidebar(),
      body: _produkList.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _produkList.length,
        itemBuilder: (context, index) {
          final produk = _produkList[index];
          final imageUrl = produk['pics'];
          final stok = produk['stok'];
          return ListTile(
            leading: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                : Icon(Icons.image, size: 50),
            title: Text(produk['nama_barang']),
            subtitle: Text("Harga: ${produk['harga']}, Stok: $stok"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tombol Keranjang
                IconButton(
                  icon: Icon(Icons.shopping_cart),
                  onPressed: () {
                    _showAddToCartDialog(produk['id'], stok);
                  },
                ),
                // Tombol Checkout
                IconButton(
                  icon: Icon(Icons.payment),
                  onPressed: () => _showCheckoutDialog(produk['id']),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddToCartDialog(int idProduk, int stok) async {
    int jumlah = 1;
    TextEditingController controller = TextEditingController(text: jumlah.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Masukkan ke Keranjang'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Masukkan jumlah produk:'),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.remove),
                    onPressed: () {
                      if (jumlah > 1) {
                        setState(() {
                          jumlah--;
                          controller.text = jumlah.toString();
                        });
                      }
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(hintText: 'Jumlah'),
                      onChanged: (value) {
                        int parsedValue = int.tryParse(value) ?? 1;
                        setState(() {
                          jumlah = parsedValue > stok ? stok : parsedValue;
                          controller.text = jumlah.toString();
                        });
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      if (jumlah < stok) {
                        setState(() {
                          jumlah++;
                          controller.text = jumlah.toString();
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _addToCart(idProduk, jumlah);
              },
              child: Text('Tambahkan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addToCart(int idProduk, int jumlah) async {
    if (_cartId == null) {
      await _fetchUserAndCartData();
      if (_cartId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ID keranjang masih tidak tersedia')),
        );
        return;
      }
    }

    try {
      final existingItemResponse = await _supabase
          .from('cart_item')
          .select('id, jumlah')
          .eq('id_produk', idProduk)
          .eq('id_keranjang', _cartId!)
          .maybeSingle();

      if (existingItemResponse != null) {
        // Jika item sudah ada, update jumlahnya
        await _supabase
            .from('cart_item')
            .update({'jumlah': existingItemResponse['jumlah'] + jumlah})
            .eq('id', existingItemResponse['id']);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Jumlah produk dalam keranjang diperbarui')),
        );
      } else {
        // Jika item belum ada, tambahkan ke cart_item
        await _supabase.from('cart_item').insert({
          'id_produk': idProduk,
          'jumlah': jumlah,
          'id_keranjang': _cartId,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Produk berhasil ditambahkan ke keranjang')),
        );
      }


      // Mendapatkan data produk
      final produkResponse = await _supabase.from('produk').select().eq('id', idProduk).single();

      // Menambahkan item ke cartItems
      setState(() {
        cartItems.add({
          'id': idProduk,
          'nama_barang': produkResponse['nama_barang'],
          'harga': produkResponse['harga'],
          'jumlah': jumlah,
        });
      });
      print(cartItems);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kesalahan: $e')),
      );
    }
  }

  Future<void> _checkout(int idProduk, int jumlah_barang, String alamat) async {
    try {
      // Mendapatkan informasi produk dari database
      var produk = await _supabase
          .from('produk')
          .select()
          .eq('id', idProduk)
          .single();

      double totalHarga = produk['harga'] * jumlah_barang;  // Total harga produk

      // Memasukkan data transaksi
      final transaksiResponse = await _supabase
          .from('transaksi')
          .insert({
        'id_pelanggan': _idPelanggan, // Pastikan _idPelanggan sudah terisi
        'id_produk': idProduk,
        'total_harga': totalHarga,
        'jumlah_barang': jumlah_barang,
        'alamat': alamat,
        'status': 'belum selesai',
        'status_pembayaran': 'belum dibayar'
      }).select('id_transaksi').single();

      final idTransaksi = transaksiResponse['id_transaksi'];
      print(idTransaksi);

      // Menambahkan produk ke cartItems
      setState(() {
        cartItems.add({
          'id_produk': idProduk,
          'nama_barang': produk['nama_barang'],  // Pastikan nama produk sesuai dengan yang ada di database
          'jumlah_barang': jumlah_barang,
          'harga': produk['harga'],
          'total_harga': totalHarga,
          'pics': produk['pics'],
          'id_transaksi': idTransaksi
        });
      });
      print(cartItems);
      // Menampilkan pesan sukses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transaksi berhasil')),
      );

      // Arahkan ke halaman checkout dengan cartItems yang sudah terisi
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CheckoutPage(cartItems: cartItems),  // Kirim cartItems ke halaman checkout
        ),
      );
    } catch (e) {
      // Tangani error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kesalahan saat memproses checkout: $e')),
      );
    }
  }
}
