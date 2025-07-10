import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  String? _imageUrl;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    if (widget.produk != null) {
      _namaBarangController.text = widget.produk!['nama_barang'];
      _stokController.text = widget.produk!['stok'].toString();
      _hargaController.text = widget.produk!['harga'].toString();
      _imageUrl = widget.produk!['pics'];
    }
  }

  // Fungsi untuk memilih gambar
  Future<void> _pickImage(int idProduk) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';

        // Upload gambar ke Supabase
        final response = await _supabase.storage.from('picsssss').uploadBinary('$fileName', bytes);

        if (response != null) {
          final presignedUrl = await _supabase.storage
              .from('picsssss')
              .createSignedUrl('$fileName', 60 * 60 * 24 * 30 * 3);

          setState(() {
            _imageUrl = presignedUrl;
          });
        } else {
          throw Exception('Gagal mengunggah gambar');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak ada gambar yang dipilih.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  // Fungsi untuk mengunggah gambar
  Future<String?> _uploadImage(File imageFile) async {
    try {
      final fileName = 'produk-${DateTime.now().millisecondsSinceEpoch}.png';
      final storageResponse = await _supabase.storage.from('picsssss').upload(fileName, imageFile);

      if (storageResponse != null) {
        final publicUrl = _supabase.storage.from('picsssss').getPublicUrl(fileName);
        return publicUrl;
      } else {
        throw Exception('Gagal mengunggah gambar');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan saat mengunggah gambar: $e');
    }
  }

  // Fungsi untuk menyimpan produk
  Future<void> _saveProduk() async {
    final namaBarang = _namaBarangController.text.trim();
    final stok = int.tryParse(_stokController.text.trim());
    final harga = int.tryParse(_hargaController.text.trim());

    if (namaBarang.isEmpty || stok == null || harga == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Semua kolom wajib diisi dengan angka yang valid')),
      );
      return;
    }

    try {
      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await _uploadImage(_imageFile!);
      } else if (_imageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pilih gambar terlebih dahulu')),
        );
        return;
      } else {
        imageUrl = _imageUrl;
      }

      if (widget.produk == null) {
        final response = await _supabase.from('produk').insert([
          {
            'nama_barang': namaBarang,
            'stok': stok,
            'harga': harga,
            'pics': imageUrl,
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
        final response = await _supabase.from('produk').update({
          'nama_barang': namaBarang,
          'stok': stok,
          'harga': harga,
          'pics': imageUrl,
        }).eq('id', widget.produk!['id']);

        if (response != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Produk berhasil diperbarui')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memperbarui produk')),
          );
        }
      }
      Navigator.pop(context);
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
            _imageFile != null
                ? Image.file(_imageFile!, width: 100, height: 100)
                : (_imageUrl != null
                ? Image.network(_imageUrl!, width: 100, height: 100)
                : Icon(Icons.image, size: 100)),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                if (widget.produk != null && widget.produk!['id'] != null) {
                  int idProduk = widget.produk!['id'] as int; // memastikan idProduk bertipe int
                  _pickImage(idProduk);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Produk tidak ditemukan')),
                  );
                }
              },
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
