import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  // 전면 광고 단위 ID
  static String get _interstitialAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-9029590341474152/1976770844' // Android 실제 ID
      : 'ca-app-pub-3940256099942544/4411468910'; // iOS 테스트 ID

  // 화면 전환 카운터 및 광고 쿨다운
  static int _screenTransitionCount = 0;
  static const int _adShowInterval = 5; // 5회 전환마다 광고
  static DateTime? _lastAdShownTime;
  static const Duration _adCooldown = Duration(minutes: 2); // 2분 쿨다운

  // AdMob 초기화
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
    loadInterstitialAd(); // 앱 시작 시 광고 미리 로드
  }

  // 화면 전환 시 호출
  static void onScreenTransition() {
    _screenTransitionCount++;

    if (_shouldShowAd()) {
      showInterstitialAd();
      _screenTransitionCount = 0;
    }
  }

  // 광고 표시 조건 확인
  static bool _shouldShowAd() {
    // 5회 전환 미만이면 표시 안 함
    if (_screenTransitionCount < _adShowInterval) {
      return false;
    }

    // 마지막 광고 후 2분이 지나지 않았으면 표시 안 함
    if (_lastAdShownTime != null) {
      final elapsed = DateTime.now().difference(_lastAdShownTime!);
      if (elapsed < _adCooldown) {
        return false;
      }
    }

    // 광고가 준비되지 않았으면 표시 안 함
    if (!_isInterstitialAdReady) {
      return false;
    }

    return true;
  }

  // 전면 광고
  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialAdReady = false;

  static void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
        },
        onAdFailedToLoad: (error) {
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  static void showInterstitialAd() {
    if (_isInterstitialAdReady && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          _lastAdShownTime = DateTime.now(); // 광고 표시 시간 기록
        },
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _isInterstitialAdReady = false;
          loadInterstitialAd(); // 다음 광고 미리 로드
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _isInterstitialAdReady = false;
          loadInterstitialAd();
        },
      );
      _interstitialAd!.show();
    }
  }

  // 광고 정리
  static void dispose() {
    _interstitialAd?.dispose();
  }
}
