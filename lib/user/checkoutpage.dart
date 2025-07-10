import 'package:flutter/material.dart';
import 'package:uas_kelompok7/user/pesanan.dart';
import 'package:uas_kelompok7/user/userhomepage.dart';
import 'usersidebar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  CheckoutPage({required this.cartItems});

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String _selectedPaymentMethod = 'COD'; // Default payment method

  @override
  Widget build(BuildContext context) {
    // Ambil ID Transaksi dari item pertama dalam cartItems
    final idTransaksi = widget.cartItems.isNotEmpty ? widget.cartItems[0]['id_transaksi'] : null;

    if (idTransaksi == null) {
      return Scaffold(
        body: Center(
          child: Text('ID transaksi tidak ditemukan.'),
        ),
      );
    }

    return _buildCheckoutPage(context, idTransaksi!);
  }

  Widget _buildCheckoutPage(BuildContext context, String idTransaksi) {
    double taxRate = 0.02; // Pajak 2%
    double ongkirate = 0.01; // Ongkir 1%

    double subtotal = 0;
    double ongkir = 0;
    double tax = 0;
    double totalAmount = 0;

    // Menghitung nilai subtotal, ongkir, pajak dan totalAmount
    for (var item in widget.cartItems) {
      var productPrice = item['total_harga'] ?? 0.0;
      subtotal += productPrice;
      ongkir += productPrice * ongkirate;
      tax += productPrice * taxRate;
    }

    totalAmount = subtotal + ongkir + tax;

    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout'),
      ),
      drawer: UserSidebar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rincian Belanja',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 20),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: widget.cartItems.length,
              itemBuilder: (context, index) {
                final item = widget.cartItems[index];
                var productName = item['nama_barang'] ?? 'Produk tidak ditemukan';
                var productPrice = item['total_harga'] ?? 0.0;
                var productImage = item['pics'] ?? '';
                var productQuantity = item['jumlah_barang'] ?? 0;

                return ListTile(
                  leading: productImage.isNotEmpty
                      ? Image.network(
                    productImage,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  )
                      : Icon(Icons.image, size: 50),
                  title: Text(productName),
                  subtitle: Text('Jumlah: $productQuantity'),
                  trailing: Text('Rp${productPrice.toStringAsFixed(0)}'),
                );
              },
            ),
            Divider(thickness: 1),
            SizedBox(height: 10),
            _buildSummaryRow('Subtotal:', 'Rp${subtotal.toStringAsFixed(0)}'),
            _buildSummaryRow('Ongkir(1%):', 'Rp${ongkir.toStringAsFixed(0)}'),
            _buildSummaryRow('Pajak (2%):', 'Rp${tax.toStringAsFixed(0)}'),
            SizedBox(height: 10),
            Divider(thickness: 1),
            _buildSummaryRow(
              'Total Harga:',
              'Rp${totalAmount.toStringAsFixed(0)}',
              isBold: true,
            ),
            SizedBox(height: 20),
            Text(
              'Pilih Metode Pembayaran',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            _buildPaymentOptions(),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  _showConfirmationDialog(context, idTransaksi, totalAmount);
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: Text('Selesaikan Pembayaran'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildPaymentOptions() {
    return Column(
      children: [
        RadioListTile<String>(
          title: Text('COD'),
          value: 'COD',
          groupValue: _selectedPaymentMethod,
          onChanged: (value) {
            setState(() {
              _selectedPaymentMethod = value!;
            });
          },
        ),
        RadioListTile<String>(
          title: Text('PayPal'),
          value: 'PayPal',
          groupValue: _selectedPaymentMethod,
          onChanged: (value) {
            setState(() {
              _selectedPaymentMethod = value!;
            });
          },
        ),
        RadioListTile<String>(
          title: Text('PayLater'),
          value: 'PayLater',
          groupValue: _selectedPaymentMethod,
          onChanged: (value) {
            setState(() {
              _selectedPaymentMethod = value!;
            });
          },
        ),
        RadioListTile<String>(
          title: Text('BCA'),
          value: 'BCA',
          groupValue: _selectedPaymentMethod,
          onChanged: (value) {
            setState(() {
              _selectedPaymentMethod = value!;
            });
          },
        ),
      ],
    );
  }

  void _showConfirmationDialog(BuildContext context, String idTransaksi, double totalAmount) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Konfirmasi Pembayaran'),
          content: Text(
              'Apakah Anda yakin ingin menyelesaikan pembayaran dengan metode $_selectedPaymentMethod?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _fetchAndUpdateTransaction(idTransaksi, totalAmount);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => UserPesananPage()),
                );
              },
              child: Text('Ya, Lanjutkan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchAndUpdateTransaction(String idTransaksi, double subtotal) async {
    final supabase = Supabase.instance.client;

    try {
      // Update status pembayaran dan total harga transaksi
      final updatedTransaction = {
        'status_pembayaran': 'dibayar',
        'total_harga': subtotal,
      };

      // Perbarui transaksi
      final updateResponse = await supabase
          .from('transaksi')
          .update(updatedTransaction)
          .eq('id_transaksi', idTransaksi)
          .select();  // Memastikan kita mendapatkan hasil

      // Memeriksa apakah update berhasil
      if (updateResponse != null && updateResponse.isNotEmpty) {
        print('Transaksi berhasil diperbarui');

        // Mengurangi stok produk berdasarkan jumlah barang dalam cartItems
        for (var item in widget.cartItems) {
          final idProduk = item['id_produk'];
          double jumlahBarang = item['jumlah_barang'];

          // Mendapatkan stok produk saat ini
          final productResponse = await supabase
              .from('produk')
              .select('stok')
              .eq('id', idProduk);

          if (productResponse != null && productResponse.isNotEmpty) {
            var product = productResponse.first;

            if (product != null) {
              double currentStock = product['stok'];

              // Pastikan stok cukup sebelum mengurangi
              if (currentStock >= jumlahBarang) {
                double newStock = currentStock - jumlahBarang;

                // Update stok produk
                final updateStockResponse = await supabase
                    .from('produk')
                    .update({'stok': newStock})
                    .eq('id', idProduk)
                    .select(); // Memastikan update stok berhasil

                if (updateStockResponse != null && updateStockResponse.isNotEmpty) {
                  print('Stok produk berhasil diperbarui untuk produk ID: $idProduk');
                } else {
                  print('Gagal memperbarui stok produk, response: $updateStockResponse');
                }
              } else {
                print('Stok produk tidak mencukupi untuk produk ID: $idProduk');
              }
            } else {
              print('Produk tidak ditemukan untuk ID: $idProduk');
            }
          } else {
            print('Gagal mendapatkan data produk, response: $productResponse');
          }
        }
      } else {
        print('Gagal memperbarui transaksi, response: $updateResponse');
      }
    } catch (e) {
      print('Error fetching or updating transaction: $e');
    }
  }
}

