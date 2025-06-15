class Account {
  final String id;
  final String email;
  final String password;
  final String name;
  final String? memberId;

  Account({required this.id, required this.email, required this.password, required this.name, this.memberId});
}
