import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uas_kelompok7/loginpage.dart';

void main() async {
  await Supabase.initialize(
    url: 'https://eesafmxsqvaemzujehkp.supabase.co',  // Ganti dengan URL Supabase Anda
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVlc2FmbXhzcXZhZW16dWplaGtwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzIxMTI2MjQsImV4cCI6MjA0NzY4ODYyNH0.lOqn0EruLZUYZHIhKd36Ka9U0UkkCXUJY7VTXsZWTAs',  // Ganti dengan kunci anon yang Anda dapatkan dari Supabase
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Electronics Sales',
      home: LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}