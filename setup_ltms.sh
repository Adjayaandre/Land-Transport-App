#!/bin/bash

# ============================================================
#  Land Transport Management System - Flutter Project Setup
#  Jalankan: bash setup_ltms.sh
# ============================================================

PROJECT_NAME="land_transport_app"

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║   LTMS Flutter Project Setup                     ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# Cek apakah Flutter sudah terinstall
if ! command -v flutter &> /dev/null; then
  echo "❌ Flutter belum terinstall. Install dulu dari https://flutter.dev"
  exit 1
fi

echo "✅ Flutter ditemukan: $(flutter --version | head -1)"
echo ""

# Buat project Flutter baru
echo "📦 Membuat Flutter project: $PROJECT_NAME ..."
flutter create $PROJECT_NAME --org com.yourcompany --platforms android,ios,web
cd $PROJECT_NAME

echo ""
echo "📁 Membuat struktur folder..."

# ── assets ──────────────────────────────────────────────────
mkdir -p assets/images
mkdir -p assets/fonts
mkdir -p assets/icons

# ── lib/core ────────────────────────────────────────────────
mkdir -p lib/core/constants
mkdir -p lib/core/errors
mkdir -p lib/core/network
mkdir -p lib/core/storage
mkdir -p lib/core/sync
mkdir -p lib/core/theme
mkdir -p lib/core/utils

# ── lib/features ────────────────────────────────────────────
FEATURES=(auth dashboard trip monitoring master_data reports)
LAYERS=(data domain presentation)

for feature in "${FEATURES[@]}"; do
  for layer in "${LAYERS[@]}"; do
    mkdir -p "lib/features/$feature/$layer"
  done
done

# ── lib/shared ──────────────────────────────────────────────
mkdir -p lib/shared

# ── test ────────────────────────────────────────────────────
mkdir -p test/unit
mkdir -p test/widget
mkdir -p test/integration

echo "✅ Folder berhasil dibuat"
echo ""
echo "📄 Membuat file Dart..."

# ── Entry point ──────────────────────────────────────────────
cat > lib/main.dart << 'DART'
import 'package:flutter/material.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO: await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseKey);
  // TODO: await LocalDb.init();
  runApp(const App());
}
DART

cat > lib/app.dart << 'DART'
import 'package:flutter/material.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Land Transport App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const Scaffold(body: Center(child: Text('LTMS Ready 🚗'))),
    );
  }
}
DART

# ── core/constants ───────────────────────────────────────────
cat > lib/core/constants/app_colors.dart << 'DART'
import 'package:flutter/material.dart';

class AppColors {
  static const primary     = Color(0xFF1565C0);
  static const secondary   = Color(0xFF0288D1);
  static const success     = Color(0xFF2E7D32);
  static const warning     = Color(0xFFF57F17);
  static const danger      = Color(0xFFC62828);
  static const background  = Color(0xFFF5F5F5);
  static const cardBg      = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF212121);
  static const textMuted   = Color(0xFF757575);

  // Status trip
  static const statusPreparation = Color(0xFF9E9E9E);
  static const statusOngoing     = Color(0xFF1565C0);
  static const statusCompleted   = Color(0xFF2E7D32);
  static const statusCancelled   = Color(0xFFC62828);
}
DART

cat > lib/core/constants/app_strings.dart << 'DART'
class AppStrings {
  // Auth
  static const login          = 'Masuk';
  static const logout         = 'Keluar';
  static const email          = 'Email';
  static const password       = 'Kata Sandi';

  // Trip
  static const tripNew        = 'Perjalanan Baru';
  static const tripList       = 'Riwayat Perjalanan';
  static const tripDetail     = 'Detail Perjalanan';
  static const customerName   = 'Nama Customer';
  static const vesselName     = 'Nama Kapal (Vessel)';
  static const pickupLocation = 'Lokasi Penjemputan';
  static const destination    = 'Lokasi Tujuan';
  static const odometerStart  = 'Odometer Awal (km)';
  static const odometerEnd    = 'Odometer Akhir (km)';

  // Status
  static const statusPreparation = 'Persiapan';
  static const statusOngoing     = 'Berlangsung';
  static const statusCompleted   = 'Selesai';
  static const statusCancelled   = 'Dibatalkan';

  // Offline
  static const offlineBanner  = 'Mode Offline — Data akan disinkronkan saat terhubung';
  static const syncPending    = 'data menunggu sinkronisasi';

  // Errors
  static const errorRequired  = 'Wajib diisi';
  static const errorNetwork   = 'Tidak ada koneksi internet';
  static const errorGeneral   = 'Terjadi kesalahan. Coba lagi.';
}
DART

cat > lib/core/constants/app_routes.dart << 'DART'
class AppRoutes {
  static const splash     = '/';
  static const login      = '/login';
  static const dashboard  = '/dashboard';
  static const tripList   = '/trips';
  static const tripCreate = '/trips/create';
  static const tripDetail = '/trips/:id';
  static const monitoring = '/monitoring';
  static const reports    = '/reports';

  // Master data
  static const vehicles   = '/master/vehicles';
  static const customers  = '/master/customers';
  static const vessels    = '/master/vessels';
  static const drivers    = '/master/drivers';
  static const users      = '/master/users';
}
DART

cat > lib/core/constants/enums.dart << 'DART'
enum TripStatus { preparation, ongoing, completed, cancelled }

enum TripType { incoming, outgoing }

enum UserRole { driver, admin, supervisor }

enum SyncOperation { insert, update, delete }
DART

# ── core/errors ──────────────────────────────────────────────
cat > lib/core/errors/app_exception.dart << 'DART'
class AppException implements Exception {
  final String message;
  const AppException(this.message);
  @override String toString() => message;
}

class NetworkException    extends AppException { const NetworkException([String m = 'Tidak ada koneksi internet']) : super(m); }
class AuthException       extends AppException { const AuthException([String m = 'Sesi tidak valid. Silakan login ulang.']) : super(m); }
class StorageException    extends AppException { const StorageException([String m = 'Gagal menyimpan data.']) : super(m); }
class SyncException       extends AppException { const SyncException([String m = 'Sinkronisasi gagal.']) : super(m); }
class ValidationException extends AppException { const ValidationException(String m) : super(m); }
DART

cat > lib/core/errors/failure.dart << 'DART'
abstract class Failure {
  final String message;
  const Failure(this.message);
}

class NetworkFailure    extends Failure { const NetworkFailure(super.message); }
class AuthFailure       extends Failure { const AuthFailure(super.message); }
class ServerFailure     extends Failure { const ServerFailure(super.message); }
class CacheFailure      extends Failure { const CacheFailure(super.message); }
class ValidationFailure extends Failure { const ValidationFailure(super.message); }
DART

# ── core/network ─────────────────────────────────────────────
cat > lib/core/network/connectivity_service.dart << 'DART'
// TODO: Implementasi dengan package connectivity_plus
// Stream<bool> get isConnected => ...

class ConnectivityService {
  // Mengembalikan true jika ada koneksi internet
  Future<bool> get hasConnection async => true; // replace dengan pengecekan nyata
}
DART

# ── core/storage ─────────────────────────────────────────────
cat > lib/core/storage/local_db.dart << 'DART'
// TODO: Inisialisasi sqflite
// Tabel: trips_local, passengers_local, sync_queue, cache_master

class LocalDb {
  static Future<void> init() async {
    // await openDatabase(...)
  }
}
DART

cat > lib/core/storage/secure_storage.dart << 'DART'
// TODO: Implementasi flutter_secure_storage
// Simpan: accessToken, userId, userRole

class SecureStorage {
  Future<void> saveToken(String token) async {}
  Future<String?> getToken() async => null;
  Future<void> clearAll() async {}
}
DART

cat > lib/core/storage/cache_manager.dart << 'DART'
// TODO: Cache data master (kendaraan, customer, vessel, driver)
// agar tersedia saat offline menggunakan SharedPreferences

class CacheManager {
  Future<void> cacheVehicles(List<dynamic> data) async {}
  Future<List<dynamic>> getCachedVehicles() async => [];
}
DART

# ── core/sync ────────────────────────────────────────────────
cat > lib/core/sync/sync_queue.dart << 'DART'
class SyncQueueItem {
  final String id;
  final String operation; // insert | update | delete
  final String tableName;
  final Map<String, dynamic> payload;
  final int retryCount;
  final DateTime createdAt;

  const SyncQueueItem({
    required this.id,
    required this.operation,
    required this.tableName,
    required this.payload,
    this.retryCount = 0,
    required this.createdAt,
  });
}
DART

cat > lib/core/sync/sync_service.dart << 'DART'
// TODO: Listen ConnectivityService → ambil antrian dari SQLite → kirim ke Supabase

class SyncService {
  Future<void> syncAll() async {
    // 1. Ambil semua item dari tabel sync_queue di SQLite
    // 2. Kirim satu per satu ke Supabase
    // 3. Jika sukses: hapus dari antrian
    // 4. Jika gagal: increment retry_count
  }
}
DART

cat > lib/core/sync/conflict_resolver.dart << 'DART'
// Strategi resolusi konflik data lokal vs server
// Default: server wins (data server lebih dipercaya)

class ConflictResolver {
  Map<String, dynamic> resolve({
    required Map<String, dynamic> local,
    required Map<String, dynamic> server,
  }) {
    return server; // Server wins by default
  }
}
DART

# ── core/theme ───────────────────────────────────────────────
cat > lib/core/theme/app_theme.dart << 'DART'
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    cardTheme: CardTheme(
      color: AppColors.cardBg,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
DART

cat > lib/core/theme/app_text_styles.dart << 'DART'
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTextStyles {
  static const heading1 = TextStyle(fontSize: 24, fontWeight: FontWeight.bold,   color: AppColors.textPrimary);
  static const heading2 = TextStyle(fontSize: 20, fontWeight: FontWeight.w600,   color: AppColors.textPrimary);
  static const heading3 = TextStyle(fontSize: 16, fontWeight: FontWeight.w600,   color: AppColors.textPrimary);
  static const bodyLarge  = TextStyle(fontSize: 16, color: AppColors.textPrimary);
  static const bodySmall  = TextStyle(fontSize: 14, color: AppColors.textPrimary);
  static const label    = TextStyle(fontSize: 14, fontWeight: FontWeight.w500,   color: AppColors.textPrimary);
  static const caption  = TextStyle(fontSize: 12, color: AppColors.textMuted);
}
DART

# ── core/utils ───────────────────────────────────────────────
cat > lib/core/utils/date_formatter.dart << 'DART'
class DateFormatter {
  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2,'0')}/${date.month.toString().padLeft(2,'0')}/${date.year}';
  }

  static String formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2,'0')}:${date.minute.toString().padLeft(2,'0')}';
  }

  static String formatDateTime(DateTime date) => '${formatDate(date)} ${formatTime(date)}';
}
DART

cat > lib/core/utils/validators.dart << 'DART'
class Validators {
  static String? requiredField(String? value, [String label = 'Kolom ini']) {
    if (value == null || value.trim().isEmpty) return '$label wajib diisi';
    return null;
  }

  static String? validKilometer(String? value) {
    if (value == null || value.isEmpty) return 'Odometer wajib diisi';
    final km = double.tryParse(value);
    if (km == null || km < 0) return 'Nilai odometer tidak valid';
    return null;
  }

  static String? validEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email wajib diisi';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Format email tidak valid';
    return null;
  }
}
DART

cat > lib/core/utils/extensions.dart << 'DART'
extension StringX on String {
  String toTitleCase() => split(' ').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ');
  bool get isNotBlank => trim().isNotEmpty;
}

extension IntX on int {
  String toKmFormat() => '${toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} km';
}

extension DateTimeX on DateTime {
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
}
DART

cat > lib/core/utils/image_helper.dart << 'DART'
// TODO: Implementasi compress gambar dengan flutter_image_compress
// dan konversi ke base64 untuk penyimpanan lokal saat offline

class ImageHelper {
  static Future<List<int>?> compressImage(String imagePath) async => null;
  static String toBase64(List<int> bytes) => '';
}
DART

cat > lib/core/utils/pdf_generator.dart << 'DART'
// TODO: Implementasi dengan package 'pdf' dan 'printing'
// Generate laporan perjalanan dengan header perusahaan, tabel trip, tanda tangan

class PdfGenerator {
  static Future<List<int>> generateTripReport(List<dynamic> trips) async => [];
}
DART

cat > lib/core/utils/excel_generator.dart << 'DART'
// TODO: Implementasi dengan package 'excel'
// Sheet: Summary, Detail Trip, Statistik Kendaraan, Statistik Driver

class ExcelGenerator {
  static Future<List<int>> generateReport(Map<String, dynamic> data) async => [];
}
DART

# ── features: auth ───────────────────────────────────────────
cat > lib/features/auth/domain/auth_model.dart << 'DART'
class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // driver | admin | supervisor
  final String? avatarUrl;

  const UserModel({required this.id, required this.name, required this.email, required this.role, this.avatarUrl});

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'], name: json['name'], email: json['email'], role: json['role'], avatarUrl: json['avatar_url'],
  );
}
DART

cat > lib/features/auth/data/auth_repository.dart     << 'DART'
// TODO: Login via Supabase Auth, simpan token ke SecureStorage
class AuthRepository {
  Future<void> login(String email, String password) async {}
  Future<void> logout() async {}
}
DART

cat > lib/features/auth/domain/auth_provider.dart     << 'DART'
// TODO: Riverpod StateNotifier untuk state: loading | authenticated | unauthenticated | error
DART

cat > lib/features/auth/presentation/login_screen.dart << 'DART'
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Login Screen')));
}
DART

cat > lib/features/auth/presentation/splash_screen.dart << 'DART'
import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}
DART

# ── features: dashboard ──────────────────────────────────────
cat > lib/features/dashboard/domain/dashboard_model.dart << 'DART'
class DashboardSummary {
  final int tripOngoing;
  final int tripCompleted;
  final int vehiclesInUse;
  final List<String> recentActivities;

  const DashboardSummary({required this.tripOngoing, required this.tripCompleted, required this.vehiclesInUse, required this.recentActivities});
}
DART

cat > lib/features/dashboard/data/dashboard_repository.dart << 'DART'
// TODO: Query Supabase untuk count trip, kendaraan aktif, aktivitas terbaru
class DashboardRepository {}
DART

cat > lib/features/dashboard/domain/dashboard_provider.dart << 'DART'
// TODO: Riverpod provider dengan auto-refresh 60 detik
DART

cat > lib/features/dashboard/presentation/dashboard_screen.dart << 'DART'
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(appBar: null, body: Center(child: Text('Dashboard')));
}
DART

cat > lib/features/dashboard/presentation/stat_card.dart << 'DART'
import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const StatCard({super.key, required this.label, required this.count, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [Icon(icon, color: color, size: 32), Text('$count', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)), Text(label)],
        ),
      ),
    );
  }
}
DART

# ── features: trip ───────────────────────────────────────────
TRIP_FILES=(
  "lib/features/trip/domain/trip_model.dart"
  "lib/features/trip/data/trip_repository.dart"
  "lib/features/trip/data/trip_local_datasource.dart"
  "lib/features/trip/data/trip_remote_datasource.dart"
  "lib/features/trip/domain/trip_provider.dart"
  "lib/features/trip/domain/trip_list_provider.dart"
  "lib/features/trip/presentation/trip_list_screen.dart"
  "lib/features/trip/presentation/trip_form_screen.dart"
  "lib/features/trip/presentation/trip_detail_screen.dart"
  "lib/features/trip/presentation/trip_form_step1.dart"
  "lib/features/trip/presentation/trip_form_step2.dart"
  "lib/features/trip/presentation/trip_form_step3.dart"
  "lib/features/trip/presentation/trip_form_step4.dart"
  "lib/features/trip/presentation/trip_form_step5.dart"
)
for f in "${TRIP_FILES[@]}"; do
  echo "// TODO: Implementasi $(basename $f .dart)" > "$f"
done

cat > lib/features/trip/domain/trip_model.dart << 'DART'
class TripModel {
  final String? id;
  final String customerId;
  final String vesselId;
  final String vehicleId;
  final String driverId;
  final String pickupLocation;
  final String destination;
  final String tripType;       // incoming | outgoing
  final DateTime tripDate;
  final DateTime pickupTime;
  final DateTime? arrivalTime;
  final String status;         // preparation | ongoing | completed | cancelled
  final double odometerStart;
  final double? odometerEnd;
  final List<String> passengers;
  final String? photoOdometerBefore;
  final String? photoOdometerAfter;
  final String? signatureImageUrl;
  final bool isSynced;

  const TripModel({
    this.id, required this.customerId, required this.vesselId, required this.vehicleId,
    required this.driverId, required this.pickupLocation, required this.destination,
    required this.tripType, required this.tripDate, required this.pickupTime,
    this.arrivalTime, required this.status, required this.odometerStart,
    this.odometerEnd, required this.passengers, this.photoOdometerBefore,
    this.photoOdometerAfter, this.signatureImageUrl, this.isSynced = false,
  });
}
DART

# ── features: monitoring ─────────────────────────────────────
echo "// TODO: Monitoring screen - list trip aktif realtime" > lib/features/monitoring/presentation/monitoring_screen.dart
echo "// TODO: Trip status card widget" > lib/features/monitoring/presentation/trip_status_card.dart
echo "// TODO: Monitoring repository" > lib/features/monitoring/data/monitoring_repository.dart

# ── features: master_data ────────────────────────────────────
MASTER_FILES=(vehicle customer vessel driver)
for entity in "${MASTER_FILES[@]}"; do
  echo "// TODO: ${entity^} model" > "lib/features/master_data/domain/${entity}_model.dart"
done
echo "// TODO: Master data CRUD repository" > lib/features/master_data/data/master_repository.dart
echo "// TODO: Master data providers" > lib/features/master_data/domain/master_provider.dart
for screen in vehicle customer vessel user_management; do
  echo "// TODO: ${screen^} screen" > "lib/features/master_data/presentation/${screen}_screen.dart"
done

# ── features: reports ────────────────────────────────────────
echo "// TODO: Report model: summary, vehicle stats, driver stats, customer stats" > lib/features/reports/domain/report_model.dart
echo "// TODO: Report repository - query agregasi Supabase" > lib/features/reports/data/report_repository.dart
echo "// TODO: Report provider dengan filter periode" > lib/features/reports/domain/report_provider.dart
echo "// TODO: Report screen dengan chart dan export PDF/Excel" > lib/features/reports/presentation/report_screen.dart
echo "// TODO: Chart widgets: BarChart, LineChart, PieChart" > lib/features/reports/presentation/report_chart.dart

# ── shared widgets ───────────────────────────────────────────
cat > lib/shared/app_button.dart << 'DART'
import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color;

  const AppButton({super.key, required this.label, this.onPressed, this.isLoading = false, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: color != null ? ElevatedButton.styleFrom(backgroundColor: color) : null,
        child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(label),
      ),
    );
  }
}
DART

cat > lib/shared/status_badge.dart << 'DART'
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge(this.status, {super.key});

  Color get _color => switch (status) {
    'ongoing'     => AppColors.statusOngoing,
    'completed'   => AppColors.statusCompleted,
    'cancelled'   => AppColors.statusCancelled,
    _             => AppColors.statusPreparation,
  };

  String get _label => switch (status) {
    'ongoing'     => 'Berlangsung',
    'completed'   => 'Selesai',
    'cancelled'   => 'Dibatalkan',
    _             => 'Persiapan',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: _color.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: _color)),
      child: Text(_label, style: TextStyle(color: _color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
DART

cat > lib/shared/offline_banner.dart << 'DART'
import 'package:flutter/material.dart';

class OfflineBanner extends StatelessWidget {
  final int pendingCount;
  const OfflineBanner({super.key, this.pendingCount = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF57F17),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(children: [
        const Icon(Icons.wifi_off, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(
          pendingCount > 0 ? 'Mode Offline — $pendingCount data menunggu sinkronisasi' : 'Mode Offline',
          style: const TextStyle(color: Colors.white, fontSize: 13),
        )),
      ]),
    );
  }
}
DART

cat > lib/shared/empty_state.dart << 'DART'
import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  const EmptyState({super.key, required this.message, this.icon = Icons.inbox_outlined});

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 64, color: Colors.grey[400]),
      const SizedBox(height: 16),
      Text(message, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
    ]));
  }
}
DART

SHARED_STUBS=(
  "app_text_field.dart"
  "app_dropdown.dart"
  "app_date_picker.dart"
  "loading_overlay.dart"
  "signature_pad.dart"
  "odometer_photo_picker.dart"
  "multi_step_indicator.dart"
  "confirm_dialog.dart"
  "sync_status_indicator.dart"
)
for f in "${SHARED_STUBS[@]}"; do
  echo "// TODO: Implementasi widget $(basename $f .dart | tr '_' ' ')" > "lib/shared/$f"
done

# ── .env ─────────────────────────────────────────────────────
cat > .env.example << 'ENV'
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
APP_ENV=development
ENV

cat > .env << 'ENV'
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
APP_ENV=development
ENV

# ── .gitignore (tambah .env) ─────────────────────────────────
echo "" >> .gitignore
echo "# Environment variables" >> .gitignore
echo ".env" >> .gitignore

# ── pubspec.yaml: tambah dependencies ────────────────────────
cat > pubspec.yaml << 'YAML'
name: land_transport_management
description: Land Transport Management System - Digitalisasi pencatatan transportasi darat.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # State management
  flutter_riverpod: ^2.4.9
  riverpod_annotation: ^2.3.3

  # Navigation
  go_router: ^13.2.0

  # Backend (Supabase)
  supabase_flutter: ^2.3.2

  # Local database (offline)
  sqflite: ^2.3.2
  path: ^1.8.3

  # Secure storage
  flutter_secure_storage: ^9.0.0

  # Shared preferences (cache)
  shared_preferences: ^2.2.2

  # Connectivity
  connectivity_plus: ^5.0.2

  # Kamera & foto
  image_picker: ^1.0.7
  flutter_image_compress: ^2.1.0

  # Digital signature
  signature: ^5.4.1

  # PDF & Excel export
  pdf: ^3.10.7
  printing: ^5.11.1
  excel: ^4.0.2

  # HTTP client
  dio: ^5.4.1

  # Utils
  intl: ^0.19.0
  uuid: ^4.3.3
  equatable: ^2.0.5

  # Icons
  cupertino_icons: ^1.0.6

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  build_runner: ^2.4.8
  riverpod_generator: ^2.3.9

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
    - .env
YAML

echo ""
echo "⬇️  Menginstall dependencies..."
flutter pub get

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║  ✅ Setup selesai!                               ║"
echo "╠══════════════════════════════════════════════════╣"
echo "║                                                  ║"
echo "║  Langkah selanjutnya:                            ║"
echo "║  1. Buka folder: cd land_transport_management    ║"
echo "║  2. Isi .env dengan kredensial Supabase kamu     ║"
echo "║  3. Buka di VS Code: code .                      ║"
echo "║  4. Jalankan: flutter run                        ║"
echo "║                                                  ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
