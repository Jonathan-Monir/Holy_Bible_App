import 'dart:io';

class AdHelper {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      // For testing, use: 'ca-app-pub-3940256099942544/6300978111'
      // For production, use your real ad unit:
      return 'ca-app-pub-3940256099942544/6300978111';
      // return 'ca-app-pub-6977244911940337/3478822721';
    } else if (Platform.isIOS) {
      // For testing, use: 'ca-app-pub-3940256099942544/2934735716'
      // For production, use your real ad unit:
      return 'ca-app-pub-3940256099942544/6300978111';
      // return 'ca-app-pub-6977244911940337/3478822721';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}
