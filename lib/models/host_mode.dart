enum HostMode {
  us,
  eu,
  custom,
}

extension HostModeX on HostMode {
  String get storageValue {
    switch (this) {
      case HostMode.us:
        return 'us';
      case HostMode.eu:
        return 'eu';
      case HostMode.custom:
        return 'custom';
    }
  }

  String get hostUrl {
    switch (this) {
      case HostMode.us:
        return 'https://us.posthog.com';
      case HostMode.eu:
        return 'https://eu.posthog.com';
      case HostMode.custom:
        return '';
    }
  }

  static HostMode fromStorage(String raw) {
    switch (raw) {
      case 'eu':
        return HostMode.eu;
      case 'custom':
        return HostMode.custom;
      case 'us':
      default:
        return HostMode.us;
    }
  }
}
