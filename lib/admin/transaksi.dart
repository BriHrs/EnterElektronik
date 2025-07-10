import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uas_kelompok7/admin/sidebar.dart';

class PesananPage extends StatefulWidget {
  @override
  _PesananPageState createState() => _PesananPageState();
}

class _PesananPageState extends State<PesananPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _pesananList = [];
  List<Map<String, dynamic>> _produkList = [];
  String? _selectedProdukId;
  int? _hargaProduk;
  final _jumlahBarangController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPesanan();
    _fetchProduk();
  }

  Future<void> _fetchPesanan() async {
    try {
      final response = await _supabase
          .from('transaksi')
          .select('id_transaksi, id_pelanggan, id_produk, jumlah_barang, total_harga, alamat,status,status_pembayaran, pelanggan(username, nomor_hp), produk(nama_barang)')
          .order('id_transaksi', ascending: false); // Opsional, untuk mengurutkan data

      setState(() {
        _pesananList = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching pesanan: $e')),
      );
    }
  }

  Future<void> _fetchProduk() async {
    try {
      final response = await _supabase.from('produk').select('id, nama_barang, harga, stok');
      setState(() {
        _produkList = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching produk: $e')));
    }
  }

  Future<void> _addPesanan(Map<String, dynamic> pesanan) async {
    try {
      final selectedProduk = _produkList.firstWhere(
              (produk) => produk['id'] == pesanan['id_produk'],
          orElse: () => {});

      if (selectedProduk.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Produk tidak ditemukan')));
        return;
      }

      if (selectedProduk['stok'] < pesanan['jumlah_barang']) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Stok tidak mencukupi')));
        return;
      }

      await _supabase.from('transaksi').insert(pesanan);

      // Update stok produk
      await _supabase.from('produk').update({
        'stok': selectedProduk['stok'] - pesanan['jumlah_barang'],
      }).eq('id', pesanan['id_produk']);

      _fetchPesanan();
      _fetchProduk();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pesanan berhasil ditambahkan')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _updatePesanan(String idTransaksi, Map<String, dynamic> updatedPesanan) async {
    try {
      // Ambil data pesanan yang ada
      final existingPesanan = await _supabase
          .from('transaksi')
          .select('id_produk, jumlah_barang')
          .eq('id_transaksi', idTransaksi)
          .single();

      final int oldJumlahBarang = existingPesanan['jumlah_barang'];
      final int newJumlahBarang = updatedPesanan['jumlah_barang'];
      final int idProduk = updatedPesanan['id_produk'];

      // Ambil data produk yang ada
      final selectedProduk = await _supabase
          .from('produk')
          .select('id, stok')
          .eq('id', idProduk)
          .single();

      int currentStok = selectedProduk['stok'];

      // Mengecek apakah stok mencukupi
      if (newJumlahBarang > oldJumlahBarang) {
        // Jika produk dalam pesanan ditambahkan
        int additionalItems = newJumlahBarang - oldJumlahBarang;

        if (additionalItems + oldJumlahBarang > currentStok ) {
          // Jika tambahan barang melebihi stok yang tersedia
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Stok produk tidak mencukupi')));
          return;
        }
        // Kurangi stok produk
        currentStok -= additionalItems;
      } else if (newJumlahBarang < oldJumlahBarang) {
        // Jika produk dalam pesanan dikurangi
        int removedItems = oldJumlahBarang - newJumlahBarang;

        // Tambahkan stok produk
        currentStok += removedItems;
      }

      // Perbarui stok produk
      await _supabase.from('produk').update({'stok': currentStok}).eq('id', idProduk);

      // Update pesanan di database
      await _supabase.from('transaksi').update(updatedPesanan).eq('id_transaksi', idTransaksi);

      // Refresh data setelah update
      await _fetchPesanan();
      await _fetchProduk();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pesanan berhasil diperbarui')));

      // Refresh halaman dengan mengganti Navigator
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => PesananPage()), // Ganti dengan halaman yang sesuai
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating pesanan: $e')));
    }
  }

  void _showUpdateForm(Map<String, dynamic> pesanan) {
    _jumlahBarangController.text = pesanan['jumlah_barang'].toString();
    _selectedProdukId = pesanan['id_produk'].toString();
    _hargaProduk = pesanan['total_harga'] ~/ pesanan['jumlah_barang']; // Hitung harga satuan

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Update Pesanan'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedProdukId,
                    items: _produkList.map((produk) {
                      return DropdownMenuItem<String>(
                        value: produk['id'].toString(),
                        child: Text('${produk['nama_barang']} (Stok: ${produk['stok']})'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedProdukId = value;
                        final selectedProduk = _produkList.firstWhere(
                              (produk) => produk['id'].toString() == _selectedProdukId,
                          orElse: () => {},
                        );
                        _hargaProduk = selectedProduk.isNotEmpty ? selectedProduk['harga'] : null;
                      });
                    },
                    decoration: InputDecoration(labelText: 'Pilih Produk'),
                  ),
                  SizedBox(height: 16),
                  // Quantity Selector with + and - buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove),
                        onPressed: () {
                          setState(() {
                            int currentQuantity = int.tryParse(_jumlahBarangController.text) ?? 1;
                            if (currentQuantity > 1) {
                              _jumlahBarangController.text = (currentQuantity - 1).toString();
                            }
                          });
                        },
                      ),
                      Container(
                        width: 60,
                        child: TextFormField(
                          controller: _jumlahBarangController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          readOnly: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Jumlah',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            int currentQuantity = int.tryParse(_jumlahBarangController.text) ?? 1;
                            _jumlahBarangController.text = (currentQuantity + 1).toString();
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Total Harga: ${_hargaProduk != null && _jumlahBarangController.text.isNotEmpty
                        ? (double.parse(_jumlahBarangController.text) * _hargaProduk!).toStringAsFixed(2)
                        : '0.00'}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    if (_selectedProdukId == null || _jumlahBarangController.text.isEmpty || _hargaProduk == null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Isi semua kolom terlebih dahulu')));
                      return;
                    }
                    try {
                      final jumlahBarang = int.parse(_jumlahBarangController.text);
                      final totalHarga = jumlahBarang * _hargaProduk!;

                      final updatedPesanan = {
                        'id_produk': int.parse(_selectedProdukId!),
                        'jumlah_barang': jumlahBarang,
                        'total_harga': totalHarga,
                      };

                      await _updatePesanan(pesanan['id_transaksi'], updatedPesanan);
                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating pesanan: $e')));
                    }
                  },
                  child: Text('Update'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(String idTransaksi, Map<String, dynamic> pesanan) {
    String? _selectedReason; // Menyimpan alasan penghapusan
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Hapus Pesanan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Apakah Anda yakin ingin menghapus pesanan ini?'),
              SizedBox(height: 16),
              // Dropdown untuk memilih alasan
              DropdownButton<String>(
                hint: Text('Pilih Alasan'),
                value: _selectedReason,
                onChanged: (value) {
                  setState(() {
                    _selectedReason = value;
                  });
                },
                items: [
                  DropdownMenuItem<String>(
                    value: 'dibatalkan',
                    child: Text('Pesanan Dibatalkan'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'selesai',
                    child: Text('Pesanan Selesai'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Menutup dialog konfirmasi
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_selectedReason == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Pilih alasan penghapusan terlebih dahulu')),
                  );
                  return;
                }

                Navigator.pop(context); // Tutup AlertDialog

                // Tampilkan loading saat proses delete
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => Center(child: CircularProgressIndicator()),
                );

                try {
                  // Jika alasan penghapusan adalah dibatalkan
                  if (_selectedReason == 'dibatalkan') {
                    final selectedProduk = await _supabase
                        .from('produk')
                        .select('id, stok')
                        .eq('id', pesanan['id_produk'])
                        .single();
                    final updatedStok = selectedProduk['stok'] + pesanan['jumlah_barang'];
                    // Update stok produk
                    await _supabase.from('produk').update({'stok': updatedStok}).eq('id', pesanan['id_produk']);

                    // Menghapus transaksi
                    await _supabase
                        .from('transaksi')
                        .delete()
                        .eq('id_transaksi', idTransaksi);

                    // Menutup dialog loading
                    Navigator.pop(context);

                    // Refresh data setelah delete berhasil
                    await _fetchPesanan();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Pesanan berhasil dihapus')),
                    );
                  } else {
                    // Jika alasan penghapusan adalah 'selesai'
                    await _supabase
                        .from('transaksi')
                        .delete()
                        .eq('id_transaksi', idTransaksi);

                    // Menutup dialog loading
                    Navigator.pop(context);

                    // Refresh data setelah delete berhasil
                    await _fetchPesanan();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Pesanan berhasil dihapus')),
                    );
                  }
                } catch (e) {
                  Navigator.pop(context); // Tutup loading dialog
                  print("Error during deletion: $e"); // Debugging
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting pesanan: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showForm() {
    _jumlahBarangController.clear();
    _hargaProduk = null;
    _selectedProdukId = null;

    final user = _supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User not logged in')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add Pesanan'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedProdukId,
                    items: _produkList.map((produk) {
                      return DropdownMenuItem<String>(
                        value: produk['id'].toString(),
                        child: Text('${produk['nama_barang']} (Stok: ${produk['stok']})'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedProdukId = value;
                        final selectedProduk = _produkList.firstWhere(
                              (produk) => produk['id'].toString() == _selectedProdukId,
                          orElse: () => {},
                        );
                        _hargaProduk = selectedProduk.isNotEmpty ? selectedProduk['harga'] : null;
                      });
                    },
                    decoration: InputDecoration(labelText: 'Pilih Produk'),
                  ),
                  TextField(
                    controller: _jumlahBarangController,
                    decoration: InputDecoration(labelText: 'Jumlah Barang'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Total Harga: ${_hargaProduk != null && _jumlahBarangController.text.isNotEmpty
                        ? (double.parse(_jumlahBarangController.text) * _hargaProduk!).toStringAsFixed(2)
                        : '0.00'}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    if (_selectedProdukId == null || _jumlahBarangController.text.isEmpty || _hargaProduk == null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Isi semua kolom terlebih dahulu')));
                      return;
                    }
                    try {
                      final jumlahBarang = int.parse(_jumlahBarangController.text);
                      final totalHarga = jumlahBarang * _hargaProduk!;

                      // Create the new pesanan object
                      final newPesanan = {
                        'id_pelanggan': user.id,
                        'id_produk': int.parse(_selectedProdukId!),
                        'jumlah_barang': jumlahBarang,
                        'total_harga': totalHarga.toInt(),
                      };
                      // Call method to add pesanan
                      await _addPesanan(newPesanan);
                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Unexpected error occurred: ${e.toString()}')),
                      );
                    }
                  },
                  child: Text('Add'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pesanan'),
      ),
      drawer: Sidebar(),
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
                      'Nama Pelanggan: ${pesanan['pelanggan']['username']}',
                      style: TextStyle(fontSize: 14),
                    ),
                    Text(
                      'Nomor Telepon: ${pesanan['pelanggan']['nomor_hp'] ?? 'Tidak tersedia'}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 1),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showUpdateForm(pesanan), // Form untuk update
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(pesanan['id_transaksi'], pesanan),
                        ),
                      ],
                    ), SizedBox(height: 8),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: Icon(Icons.add),
      ),
    );
  }
}
