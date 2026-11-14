/// Kategori catatan. Nilai [name] disimpan di kolom `category` database.
enum RecordCategory {
  observasi('Observasi'),
  lingkungan('Lingkungan'),
  infrastruktur('Infrastruktur'),
  lainnya('Lainnya');

  const RecordCategory(this.label);
  final String label;

  static RecordCategory fromValue(String? value) => RecordCategory.values.firstWhere(
        (c) => c.name == value,
        orElse: () => RecordCategory.lainnya,
      );
}
