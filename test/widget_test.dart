import 'package:flutter_test/flutter_test.dart';
import 'package:land_transport_app/features/auth/domain/auth_model.dart';
import 'package:land_transport_app/features/auth/domain/auth_state.dart';

void main() {
  test('authenticated state stores the logged-in user', () {
    const user = UserModel(
      id: 'user-1',
      name: 'Test User',
      email: 'test@example.com',
      role: 'driver',
    );

    const state = AuthState.authenticated(user);

    expect(state.status, AuthStatus.authenticated);
    expect(state.isAuthenticated, isTrue);
    expect(state.user, user);
  });
}
