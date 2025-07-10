import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uas_kelompok7/user/usersidebar.dart';
import 'checkoutpage.dart';

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final _supabase = Supabase.instance.client;
  String? _cartId; // ID keranjang untuk user
  List<Map<String, dynamic>> _cartItems = []; // Data item dalam keranjang

  @override
  void initState() {
    super.initState();
    _fetchCart(); // Ambil data keranjang saat halaman dimuat
  }

  Future<void> _fetchCart() async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pengguna belum login')),
        );
        return;
      }

      final cartResponse = await _supabase
          .from('cart')
          .select('id')
          .eq('id_pelanggan', userId)
          .maybeSingle();

      if (cartResponse == null) {
        final newCartResponse = await _supabase.from('cart').insert({
          'id_pelanggan': userId,
        }).select('id').single();

        _cartId = newCartResponse['id'];
      } else {
        _cartId = cartResponse['id'];
      }

      if (_cartId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Keranjang tidak ditemukan atau gagal dibuat')),
        );
        return;
      }

      final itemsResponse = await _supabase
          .from('cart_item')
          .select('id_produk, jumlah')
          .eq('id_keranjang', _cartId!);

      List<Map<String, dynamic>> productsResponse = [];
      for (var item in itemsResponse) {
        final productResponse = await _supabase
            .from('produk')
            .select('id, nama_barang, harga, pics')
            .eq('id', item['id_produk'])
            .single();
        productsResponse.add(productResponse);
      }

      final itemsWithProduct = itemsResponse.map((item) {
        final product = productsResponse.firstWhere(
              (product) => product['id'] == item['id_produk'],
          orElse: () => {},
        );
        return {
          'id_produk': item['id_produk'],
          'jumlah': item['jumlah'],
          'produk': product,
        };
      }).toList();

      setState(() {
        _cartItems = List<Map<String, dynamic>>.from(itemsWithProduct);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  Future<void> _removeFromCart(String productId) async {
    try {
      await _supabase
          .from('cart_item')
          .delete()
          .eq('id_produk', productId)
          .eq('id_keranjang', _cartId!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Produk berhasil dihapus dari keranjang')),
      );
      _fetchCart();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus produk: $e')),
      );
    }
  }

  void _showCheckoutDialog(BuildContext context, Map<String, dynamic> item) {
    final product = item['produk'];
    final totalPrice = product['harga'] * item['jumlah'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Checkout Sekarang'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Nama Produk: ${product['nama_barang']}'),
              Text('Jumlah: ${item['jumlah']}'),
              Text('Total Harga: Rp$totalPrice'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CheckoutPage(cartItems: [_formatCartItem(item)]),
                  ),
                );
              },
              child: Text('Checkout'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  Map<String, dynamic> _formatCartItem(Map<String, dynamic> cartItem) {
    final product = cartItem['produk'];
    return {
      'id_transaksi': _cartId,
      'id_produk': cartItem['id_produk'],
      'jumlah_barang': cartItem['jumlah'],
      'total_harga': product['harga'] * cartItem['jumlah'],
      'nama_barang': product['nama_barang'],
      'pics': product['pics'],
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Keranjang'),
      ),
      drawer: UserSidebar(),
      body: _cartItems.isEmpty
          ? Center(child: Text('Keranjang kosong'))
          : ListView.builder(
        itemCount: _cartItems.length,
        itemBuilder: (context, index) {
          final item = _cartItems[index];
          final product = item['produk'];
          final imageUrl = product['pics'];

          return ListTile(
            leading: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                : Icon(Icons.image, size: 50),
            title: Text(product['nama_barang']),
            subtitle: Text('Jumlah: ${item['jumlah']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Harga: Rp${product['harga'] * item['jumlah']}'),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    _removeFromCart(item['id_produk'].toString());
                  },
                ),
                IconButton(
                  icon: Icon(Icons.shopping_cart_checkout),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CheckoutPage(cartItems: [_formatCartItem(item)]),
                      ),
                    );
                  },
                ),
              ],
            ),
            onTap: () => _showCheckoutDialog(context, item),
          );
        },
      ),
    );
  }
}
