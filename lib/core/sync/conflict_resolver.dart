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
