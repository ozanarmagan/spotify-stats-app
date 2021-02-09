import 'package:firebase_admob/firebase_admob.dart';

class AdvertService {
  static final AdvertService _instance = AdvertService._internal();
  factory AdvertService() => _instance;
  MobileAdTargetingInfo _targetingInfo;
  AdvertService._internal() {
    _targetingInfo = MobileAdTargetingInfo();
  }
  showBanner() {
    BannerAd banner = BannerAd(
        adUnitId: BannerAd.testAdUnitId,
        size: AdSize.smartBanner,
        targetingInfo: _targetingInfo);
    banner
      ..load()
      ..show();
    banner.dispose();
  }

  showIntersitial() {
    InterstitialAd intersitialAd = InterstitialAd(
        adUnitId: "ca-app-pub-3892086718461979/4420436059",
        targetingInfo: _targetingInfo);
    intersitialAd
      ..load()
      ..show();
    intersitialAd.dispose();
  }
}
