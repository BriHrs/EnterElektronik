import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uas_kelompok7/user/usersidebar.dart';
import 'checkoutpage.dart';

class UserPesananPage extends StatefulWidget {
  @override
  _PesananPageState createState() => _PesananPageState();
}

class _PesananPageState extends State<UserPesananPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _pesananList = [];
  List<Map<String, dynamic>> cartItems = [];  // Menyimpan item keranjang dalam list Map

  @override
  void initState() {
    super.initState();
    _fetchPesanan();
  }

  Future<void> _fetchPesanan() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User not logged in')));
        return;
      }

      final response = await _supabase
          .from('transaksi')
          .select('id_transaksi, id_pelanggan, id_produk, jumlah_barang, total_harga, alamat, status_pembayaran, status, pelanggan(username, nomor_hp), produk(nama_barang,pics)')
          .eq('id_pelanggan', user.id)
          .order('id_transaksi', ascending: false);

      setState(() {
        _pesananList = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching pesanan: $e')));
    }
  }

  Future<void> _updateStatusPesanan(String idTransaksi, String status) async {
    if (status == 'selesai') {
      // Pembaruan status pembayaran jika perlu (misalnya, menandai sebagai dibayar atau selesai)
      final updatePaymentResponse = await _supabase
          .from('transaksi')
          .update({'status': 'selesai'}) // Update status pembayaran menjadi 'dibayar'
          .eq('id_transaksi', idTransaksi);

      if (updatePaymentResponse.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating payment status: ${updatePaymentResponse.error!.message}')));
      } else {
        print('Status pembayaran berhasil diperbarui ke: dibayar');
      }
    }
    // Memanggil _fetchPesanan dan memastikan halaman ter-refresh
    await _fetchPesanan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pesanan'),
      ),
      drawer: UserSidebar(),
      body: ListView.builder(
        itemCount: _pesananList.length,
        itemBuilder: (context, index) {
          final pesanan = _pesananList[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Harga: Rp.${pesanan['total_harga']}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Nama Barang: ${pesanan['produk']['nama_barang']}',
                      style: TextStyle(fontSize: 14),
                    ),
                    Text(
                      'Jumlah Barang: ${pesanan['jumlah_barang']}',
                      style: TextStyle(fontSize: 14),
                    ),
                    Text(
                      'Nomor Telepon: ${pesanan['pelanggan']['nomor_hp'] ?? 'Tidak tersedia'}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: pesanan['status_pembayaran'] == 'dibayar' ? Colors.green : Colors.red,
                              width: 2,
                            ),
                          ),
                          onPressed: pesanan['status_pembayaran'] == 'belum dibayar'
                              ? () {
                            // Menambahkan pesanan ke cartItems dan arahkan ke checkout
                            cartItems.add({
                              'id_transaksi': pesanan['id_transaksi'],
                              'id_produk': pesanan['id_produk'],
                              'jumlah_barang': pesanan['jumlah_barang'],
                              'total_harga': pesanan['total_harga'],
                              'nama_barang': pesanan['produk']['nama_barang'],
                              'pics': pesanan['produk']['pics'],
                            });
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => CheckoutPage(cartItems: cartItems)),
                            );
                          }
                              : null, // Tombol tidak bisa ditekan jika sudah dibayar
                          child: Text(
                            'Status Pembayaran: ${pesanan['status_pembayaran']}',
                            style: TextStyle(
                              color: pesanan['status_pembayaran'] == 'dibayar' ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: pesanan['status'] == 'selesai' ? Colors.green : Colors.red,
                              width: 2,
                            ),
                          ),
                          onPressed: pesanan['status'] == 'selesai' ? null : () {
                            _showStatusDialog(pesanan['id_transaksi'], pesanan['status'],pesanan['status_pembayaran']);
                          },
                          child: Text(
                            'Status: ${pesanan['status']}',
                            style: TextStyle(
                              color: pesanan['status'] == 'selesai' ? Colors.green : Colors.red,
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Menampilkan dialog konfirmasi untuk menyelesaikan atau membatalkan pesanan
  void _showStatusDialog(String idTransaksi, String currentStatus, String statusPembayaran) {
    if (statusPembayaran == 'belum dibayar') {
      // Tampilkan dialog jika pembayaran belum dilakukan
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Pembayaran Belum Selesai'),
            content: Text('Anda harus menyelesaikan pembayaran terlebih dahulu untuk melanjutkan.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserPesananPage()),
                ),
                child: Text('OK'),
              ),
            ],
          );
        },
      );
      return; // Keluar dari fungsi jika pembayaran belum dilakukan
    }

    // Dialog untuk konfirmasi status pesanan
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Konfirmasi Status Pesanan'),
          content: Text(
              'Apakah Anda yakin ingin ${currentStatus == 'selesai' ? 'membatalkan' : 'menyelesaikan'} pesanan ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                String newStatus = currentStatus == 'selesai' ? 'dibatalkan' : 'selesai';
                _updateStatusPesanan(idTransaksi, newStatus);
                _fetchPesanan();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserPesananPage()),
                );
              },
              child: Text(currentStatus == 'selesai' ? 'Batalkan Pesanan' : 'Selesaikan Pesanan'),
            ),
          ],
        );
      },
    );
  }

}
