import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uas_kelompok7/admin/sidebar.dart';
import 'package:image_picker/image_picker.dart';

class ProdukPage extends StatefulWidget {
  @override
  _ProdukPageState createState() => _ProdukPageState();
}

class _ProdukPageState extends State<ProdukPage> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _produkList = [];

  @override
  void initState() {
    super.initState();
    _fetchProduk();
  }

  // Fungsi untuk mengambil data produk dari Supabase
  Future<void> _fetchProduk() async {
    try {
      final response = await _supabase.from('produk').select();
      if (response != null) {
        setState(() {
          _produkList = response as List<dynamic>;
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

  // Fungsi untuk menghapus produk berdasarkan ID
  Future<void> _deleteProduk(int id) async {
    try {
      final response = await _supabase.from('produk').delete().eq('id', id).select();
      if (response != null) {
        _fetchProduk(); // Refresh data produk setelah penghapusan
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Produk berhasil dihapus')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus produk')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kesalahan: $e')),
      );
    }
  }

  // Fungsi untuk membuka halaman tambah/edit produk
  void _openAddEditProdukPage({Map<String, dynamic>? produk}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditProdukPage(produk: produk),
      ),
    ).then((_) => _fetchProduk()); // Refresh produk setelah menambah/menyunting
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Produk"),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _openAddEditProdukPage(), // Tombol tambah produk
          ),
        ],
      ),
      drawer: Sidebar(),
      body: _produkList.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _produkList.length,
        itemBuilder: (context, index) {
          final produk = _produkList[index];
          final imageUrl = produk['pics']; // Ambil URL gambar dari kolom 'pics'
          return ListTile(
            leading: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                : Icon(Icons.image, size: 50), // Placeholder jika tidak ada gambar
            title: Text(produk['nama_barang']),
            subtitle: Text("Harga: ${produk['harga']}, Stok: ${produk['stok']}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _openAddEditProdukPage(produk: produk),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _deleteProduk(produk['id']),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Halaman untuk menambah dan mengedit produk
class AddEditProdukPage extends StatefulWidget {
  final Map<String, dynamic>? produk;

  AddEditProdukPage({this.produk});

  @override
  _AddEditProdukPageState createState() => _AddEditProdukPageState();
}

class _AddEditProdukPageState extends State<AddEditProdukPage> {
  final _supabase = Supabase.instance.client;
  final _namaBarangController = TextEditingController();
  final _stokController = TextEditingController();
  final _hargaController = TextEditingController();
  String? _imageUrl; // Untuk menyimpan URL gambar yang dipilih

  @override
  void initState() {
    super.initState();
    if (widget.produk != null) {
      _namaBarangController.text = widget.produk!['nama_barang'];
      _stokController.text = widget.produk!['stok'].toString();
      _hargaController.text = widget.produk!['harga'].toString();
      _imageUrl = widget.produk!['pics']; // Menampilkan gambar jika ada
    }
  }

  // Fungsi untuk memilih gambar
  Future<void> _pickImage(int idProduk) async {
    try {
      // Pilih gambar dari galeri menggunakan image_picker
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

      if (pickedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak ada gambar yang dipilih.')),
        );
        return;
      }

      // Baca file gambar sebagai Uint8List
      final bytes = await pickedFile.readAsBytes();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';

      // Upload gambar ke Supabase storage
      final filePath = await _supabase.storage.from('picsssss').uploadBinary(fileName, bytes);

      if (filePath == null || filePath.isEmpty) {
        throw Exception('Gagal mengunggah gambar ke storage.');
      }

      // Ambil presigned URL (kedaluwarsa dalam 3 bulan = 60 * 60 * 24 * 30 * 3 detik)
      final presignedUrl = await _supabase.storage
          .from('picsssss')
          .createSignedUrl(fileName, 60 * 60 * 24 * 30 * 3); // 3 bulan

      if (presignedUrl == null || presignedUrl.isEmpty) {
        throw Exception('Gagal membuat URL bertanda tangan.');
      }

      setState(() {
        _imageUrl = presignedUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gambar berhasil diunggah.')),
      );
    } catch (e, stacktrace) {
      print('Terjadi kesalahan: $e');
      print('Stacktrace: $stacktrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }


  // Fungsi untuk menyimpan produk
  Future<void> _saveProduk() async {
    final namaBarang = _namaBarangController.text.trim();
    final stok = int.tryParse(_stokController.text.trim());
    final harga = int.tryParse(_hargaController.text.trim());

    if (namaBarang.isEmpty || stok == null || harga == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Semua kolom wajib diisi')),
      );
      return;
    }
    try {
      if (widget.produk == null) {
        // Tambah Produk
        final response = await _supabase.from('produk').insert([
          {
            'nama_barang': namaBarang,
            'stok': stok,
            'harga': harga,
            'pics': _imageUrl, // Simpan URL gambar
          }
        ]);
        if (response != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Produk berhasil ditambahkan')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menambahkan produk')),
          );
        }
      } else {
        // Update Produk
        final response = await _supabase.from('produk').update({
          'nama_barang': namaBarang,
          'stok': stok,
          'harga': harga,
          'pics': _imageUrl,
        }).eq('id', widget.produk!['id']);
        if (response != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Produk berhasil diperbarui')),
          );
        } else {

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
      appBar: AppBar(title: Text(widget.produk == null ? 'Tambah Produk' : 'Edit Produk')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _namaBarangController,
              decoration: InputDecoration(labelText: 'Nama Barang'),
            ),
            TextField(
              controller: _stokController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Stok'),
            ),
            TextField(
              controller: _hargaController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Harga'),
            ),
            SizedBox(height: 20),
            _imageUrl != null
                ? Image.network(_imageUrl!, width: 100, height: 100)
                : Icon(Icons.image, size: 100), // Placeholder gambar
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _pickImage(widget.produk?['id'] ?? ''), // Kirim ID produk
              child: Text('Pilih Gambar'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveProduk,
              child: Text(widget.produk == null ? 'Tambah' : 'Perbarui'),
            ),
          ],
        ),
      ),
    );
  }
}
