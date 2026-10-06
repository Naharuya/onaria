class GoogleAuthConfig {
  const GoogleAuthConfig._();

  static const clientId =
      '324052011360-m2jtgh7q9p5h609q5n30145qrujb2a69.apps.googleusercontent.com';
  static const serverClientId =
      '324052011360-3na7748d81s4s692d1o38iruni2lmrqg.apps.googleusercontent.com';

  static bool get enabled => clientId.isNotEmpty && serverClientId.isNotEmpty;
}
