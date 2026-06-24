import 'package:flutter/material.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO: await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseKey);
  // TODO: await LocalDb.init();
  runApp(const App());
}
