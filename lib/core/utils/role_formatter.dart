import '../../shared/models/user.dart';

String formatRole(UserRole role) {
  switch (role) {
    case UserRole.client:
      return 'Cliente';
    case UserRole.seller:
      return 'Vendedor';
  }
}
