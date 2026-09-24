class AuthLoginResult {
  final String token;
  final String quickLoginCredential;
  final bool firstGuestLogin;

  const AuthLoginResult({
    required this.token,
    required this.quickLoginCredential,
    this.firstGuestLogin = false,
  });
}
