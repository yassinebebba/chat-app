class UserModel {
  final int id;
  final String phoneNumber;
  final String accessToken;
  final bool isAuthenticated;

  UserModel(this.id, this.phoneNumber, this.accessToken, this.isAuthenticated);
  factory UserModel.fromMap(Map<String, Object?> obj) {
    return UserModel(obj['id'] as int, obj['phone_number'] as String, obj['access_token'] as String, obj['is_authenticated'] == 1);
  }
}
