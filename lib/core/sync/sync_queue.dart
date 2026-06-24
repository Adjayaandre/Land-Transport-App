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
