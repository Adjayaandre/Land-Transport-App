// TODO: Listen ConnectivityService → ambil antrian dari SQLite → kirim ke Supabase

class SyncService {
  Future<void> syncAll() async {
    // 1. Ambil semua item dari tabel sync_queue di SQLite
    // 2. Kirim satu per satu ke Supabase
    // 3. Jika sukses: hapus dari antrian
    // 4. Jika gagal: increment retry_count
  }
}
