/// Google sign-in has expired or been revoked; sync stops until the user
/// signs in again.
class SignInNeeded implements Exception {
  @override
  String toString() => 'SignInNeeded';
}

/// Drive or Google could not be reached or answered with an error; sync
/// waits and tries again.
class DriveUnavailable implements Exception {
  DriveUnavailable([this.statusCode]);

  final int? statusCode;

  @override
  String toString() => 'DriveUnavailable: ${statusCode ?? 'no answer'}';
}
