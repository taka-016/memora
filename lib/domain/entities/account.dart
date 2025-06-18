class Account {
  final String id;
  final String name;
  final String password;
  final String email;
  final String? memberId;

  Account({required this.id, required this.name, required this.password, required this.email, this.memberId});
}
