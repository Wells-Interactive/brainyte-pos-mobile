class Validators {
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final email = value.trim();
    if (!email.contains('@')) {
      return 'Enter a valid email';
    }
    return null;
  }

  static String? required(String? value, {String label = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }
}
