class AppUser {
  const AppUser({
    required this.id,
    this.email,
    this.displayName,
    this.firstName,
    this.lastName,
    this.age,
    this.hometown,
    this.gender,
    this.avatarUrl,
  });

  final String id;
  final String? email;
  final String? displayName;
  final String? firstName;
  final String? lastName;
  final int? age;
  final String? hometown;
  final String? gender;
  final String? avatarUrl;
}
