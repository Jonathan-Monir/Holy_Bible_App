// lib/app_open_ad_manager.dart
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_helper.dart';

class AppOpenAdManager {
  AppOpenAd? _appOpenAd;
  bool _isAdLoaded = false;
  bool _isShowingAd = false;

  void loadAd() {
    print('🔵 AppOpenAd: loadAd() called');
    AppOpenAd.load(
      adUnitId: AdHelper.appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          print('✅ AppOpenAd: loaded successfully');
          _appOpenAd = ad;
          _isAdLoaded = true;
        },
        onAdFailedToLoad: (error) {
          print('❌ AppOpenAd: failed to load: $error');
          _isAdLoaded = false;
        },
      ),
    );
  }

  void showAdIfAvailable() {
    print('🟡 AppOpenAd: showAdIfAvailable() called');
    print('🟡 AppOpenAd: _isAdLoaded=$_isAdLoaded, _isShowingAd=$_isShowingAd, _appOpenAd=$_appOpenAd');

    if (!_isAdLoaded || _appOpenAd == null) {
      print('🟡 AppOpenAd: Ad not ready, loading a new one...');
      loadAd();
      return;
    }

    if (_isShowingAd) {
      print('🟡 AppOpenAd: Already showing an ad, skipping');
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        print('✅ AppOpenAd: showing fullscreen');
        _isShowingAd = true;
      },
      onAdDismissedFullScreenContent: (ad) {
        print('✅ AppOpenAd: dismissed, loading next...');
        _isShowingAd = false;
        _isAdLoaded = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('❌ AppOpenAd: failed to show: $error');
        _isShowingAd = false;
        _isAdLoaded = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd();
      },
    );

    print('✅ AppOpenAd: calling show()');
    _appOpenAd!.show();
  }
}

class AppLifecycleReactor {
  final AppOpenAdManager appOpenAdManager;

  AppLifecycleReactor({required this.appOpenAdManager});

  void listenToAppStateChanges() {
    print('🔵 AppLifecycleReactor: started listening');
    AppStateEventNotifier.startListening();
    AppStateEventNotifier.appStateStream.forEach((state) {
      print('🔵 AppLifecycleReactor: state changed to $state');
      if (state == AppState.foreground) {
        print('🔵 AppLifecycleReactor: foreground detected, showing ad...');
        appOpenAdManager.showAdIfAvailable();
      }
    });
  }
}
