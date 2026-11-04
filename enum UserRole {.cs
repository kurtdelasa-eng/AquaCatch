enum UserRole {
  fisherman('FISHERMAN', 'Fisherman'),
  buyer('BUYER', 'Buyer'),
  portAdmin('PORT_ADMIN', 'Port Admin'),
  superAdmin('SUPER_ADMIN', 'Super Admin');

  final String dbValue;
  final String displayName;

  const UserRole(this.dbValue, this.displayName);

  static UserRole? tryParse(String? value) {
    final normalized = value?.trim().toUpperCase().replaceAll(' ', '_');

    switch (normalized) {
      case 'FISHERMAN':
        return UserRole.fisherman;
      case 'BUYER':
        return UserRole.buyer;
      case 'PORT_ADMIN':
      case 'PORTADMIN':
      case 'ADMIN':
        return UserRole.portAdmin;
      case 'SUPER_ADMIN':
      case 'SUPERADMIN':
        return UserRole.superAdmin;
      default:
        return null;
    }
  }

  static UserRole parse(String? value) {
    return tryParse(value) ?? UserRole.fisherman;
  }
}