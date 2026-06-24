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
