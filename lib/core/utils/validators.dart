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
