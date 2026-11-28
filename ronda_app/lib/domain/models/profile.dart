/// Authenticated user identity decoupled from SDK-specific session classes.
class AuthSessionUser {
  const AuthSessionUser({
    required this.id,
    required this.email,
  });

  final String id;
  final String email;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthSessionUser && other.id == id && other.email == email;

  @override
  int get hashCode => Object.hash(id, email);
}

/// Domain entity for `profiles` (1:1 with `auth.users`).
class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.phoneWhatsapp,
    required this.createdAt,
  });

  final String id;
  final String fullName;
  final String phoneWhatsapp;
  final DateTime createdAt;

  UserProfile copyWith({
    String? fullName,
    String? phoneWhatsapp,
  }) {
    return UserProfile(
      id: id,
      fullName: fullName ?? this.fullName,
      phoneWhatsapp: phoneWhatsapp ?? this.phoneWhatsapp,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          other.id == id &&
          other.fullName == fullName &&
          other.phoneWhatsapp == phoneWhatsapp &&
          other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, fullName, phoneWhatsapp, createdAt);
}
