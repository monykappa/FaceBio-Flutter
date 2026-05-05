enum ScanMode { register, verify }

extension ScanModeX on ScanMode {
  String get label => this == ScanMode.register ? 'Register' : 'Verify';
}
