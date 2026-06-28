class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Tidak ada koneksi internet']);
}

class AuthException extends AppException {
  const AuthException(
      [super.message = 'Sesi tidak valid. Silakan login ulang.']);
}

class StorageException extends AppException {
  const StorageException([super.message = 'Gagal menyimpan data.']);
}

class SyncException extends AppException {
  const SyncException([super.message = 'Sinkronisasi gagal.']);
}

class ValidationException extends AppException {
  const ValidationException(super.message);
}
