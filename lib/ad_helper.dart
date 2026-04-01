import 'dart:io';

class AdHelper {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      // TEST ID — replace with real ID before release
      return 'ca-app-pub-3940256099942544/6300978111';
      // PRODUCTION: return 'ca-app-pub-6977244911940337/3478822721';
      // TEST: return 'ca-app-pub-3940256099942544/6300978111';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
      // PRODUCTION: return 'ca-app-pub-6977244911940337/3478822721';
      // TEST: return 'ca-app-pub-3940256099942544/2934735716';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get appOpenAdUnitId {
    if (Platform.isAndroid) {
      // TEST ID — replace with real ID before release
      return 'ca-app-pub-3940256099942544/9257395921';
      // PRODUCTION: return 'ca-app-pub-6977244911940337/2689818766';
      // TEST: return 'ca-app-pub-3940256099942544/9257395921';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/5575463023';
      // PRODUCTION: return 'ca-app-pub-6977244911940337/2689818766';
      // TEST: return 'ca-app-pub-3940256099942544/5575463023';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}
