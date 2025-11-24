class Announcement {
  final String id;
  final String jadwalId;
  final String title;
  final String message;
  final DateTime timestamp;

  Announcement({required this.id, required this.jadwalId, required this.title, required this.message, DateTime? timestamp}) : timestamp = timestamp ?? DateTime.now();
}
