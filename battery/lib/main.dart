import 'dart:async';
import 'dart:io';
import 'package:admob_flutter/admob_flutter.dart';
import 'package:android_power_manager/android_power_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:screen/screen.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:toast/toast.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Admob.initialize();
  runApp(MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      debugShowCheckedModeBanner: false,
      home: AnaEkran()));
}

class AnaEkran extends StatefulWidget {
  @override
  _AnaEkranState createState() => _AnaEkranState();
}

class _AnaEkranState extends State<AnaEkran> {
  GlobalKey<ScaffoldState> scaffoldState = GlobalKey();
  AdmobBannerSize bannerSize;
  AdmobInterstitial interstitialAd;
  @override
  double parlaklik;
  Battery pil = Battery();
  String deger;
  int kontrol = 0;
  BatteryState pilState;
  StreamSubscription<BatteryState> pilStateSubscription;
  String _isIgnoringBatteryOptimizations = 'Unknown';
  double pDegeri = 0.1;

  Future<void> initPlatformState() async {
    if (!mounted) return;
    String isIgnoringBatteryOptimizations = await _checkBatteryOptimizations();
    setState(() {
      _isIgnoringBatteryOptimizations = isIgnoringBatteryOptimizations;
    });
  }

  Future<String> _checkBatteryOptimizations() async {
    String isIgnoringBatteryOptimizations;
    try {
      isIgnoringBatteryOptimizations =
          '${await AndroidPowerManager.isIgnoringBatteryOptimizations}';
    } on PlatformException {
      isIgnoringBatteryOptimizations = 'Failed to get platform version.';
    }
    return isIgnoringBatteryOptimizations;
  }

  @override
  void initState() {
    bannerSize = AdmobBannerSize.BANNER;
    interstitialAd = AdmobInterstitial(
      adUnitId: getInterstitialAdUnitId(),
      listener: (AdmobAdEvent event, Map<String, dynamic> args) {
        if (event == AdmobAdEvent.closed) interstitialAd.load();
        handleEvent(event, args, 'Interstitial');
      },
    );
    super.initState();
    parlaklik;
    getBrightness();
    pilStateSubscription = pil.onBatteryStateChanged.listen(
      (BatteryState state) {
        setState(
          () {
            pilState = state;
          },
        );
      },
    );
    interstitialAd.load();
  }

  void handleEvent(
      AdmobAdEvent event, Map<String, dynamic> args, String adType) {
    switch (event) {
      case AdmobAdEvent.loaded:
        showSnackBar('New Admob $adType Ad loaded!');
        break;
      case AdmobAdEvent.opened:
        showSnackBar('Admob $adType Ad opened!');
        break;
      case AdmobAdEvent.closed:
        showSnackBar('Admob $adType Ad closed!');
        break;
      case AdmobAdEvent.failedToLoad:
        showSnackBar('Admob $adType failed to load. :(');
        break;
      case AdmobAdEvent.rewarded:
        showDialog(
          context: scaffoldState.currentContext,
          builder: (BuildContext context) {
            return WillPopScope(
              child: AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('Reward callback fired. Thanks Andrew!'),
                    Text('Type: ${args['type']}'),
                    Text('Amount: ${args['amount']}'),
                  ],
                ),
              ),
              onWillPop: () async {
                scaffoldState.currentState.hideCurrentSnackBar();
                return true;
              },
            );
          },
        );
        break;
      default:
    }
  }

  void showSnackBar(String content) {
    scaffoldState.currentState.showSnackBar(
      SnackBar(
        content: Text(content),
        duration: Duration(milliseconds: 1500),
      ),
    );
  }

  void getBrightness() async {
    double value = await Screen.brightness;
    setState(() {
      parlaklik = double.parse(value.toStringAsFixed(1));
    });
  }

  verikaydet(parlaklik) async {
    double pDegeri = 0.1;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble("Parlaklik", pDegeri);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: <Widget>[
      Image.asset(
        "assets/images/ana.png",
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        fit: BoxFit.fill,
      ),
      Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: <Widget>[
            Center(
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.05,
                  ),
                  Container(
                    height: MediaQuery.of(context).size.height * 0.37,
                    width: MediaQuery.of(context).size.width * 1,
                    child: FlareActor(
                      "assets/images/batterys.flr",
                      alignment: Alignment.center,
                      fit: BoxFit.contain,
                      animation: '$deger',
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.3,
                  ),
                  SizedBox(
                    height: 100,
                    width: 300,
                    child: FloatingActionButton(
                      child: Image.asset("assets/images/buton.png"),
                      onPressed: () async {
                        final int pilYuzde = await pil.batteryLevel;
                        setState(() {
                          deger = 'Untitled';
                          parlaklik = pDegeri;
                        });
                        Screen.setBrightness(parlaklik);
                        bool success = await AndroidPowerManager
                            .requestIgnoreBatteryOptimizations();
                        if (success) {
                          String isIgnoringBatteryOptimizations =
                              await _checkBatteryOptimizations();
                          setState(() {
                            _isIgnoringBatteryOptimizations =
                                isIgnoringBatteryOptimizations;
                          });
                        }
                        if (kontrol == 0) {
                          DefaultCacheManager().emptyCache();
                          imageCache.clear();
                          DisableBatteryOptimization.showEnableAutoStartSettings(
                              "Enable Auto Start",
                              "Follow the steps and enable the auto start of this app");
                          bool isAutoStartEnabled =
                              await DisableBatteryOptimization
                                  .isAutoStartEnabled;
                          Toast.show(
                              'Optimize Edildi.\nPil: $pilYuzde%' +
                                  '\n$pilState\n' +
                                  "Parlaklık " +
                                  (parlaklik * 100).toStringAsFixed(1) +
                                  "%",
                              context,
                              gravity: Toast.CENTER,
                              duration: 5,
                              backgroundRadius: 20);
                          kontrol = 1;
                        } else {
                          Toast.show(
                              "Zaten optimize edildi.\nPil: $pilYuzde% \n$pilState\n" +
                                  "Parlaklık " +
                                  (parlaklik * 100).toStringAsFixed(1) +
                                  "%",
                              context,
                              gravity: Toast.CENTER,
                              duration: 10,
                              backgroundRadius: 20);
                        }
                        if (await interstitialAd.isLoaded) {
                          interstitialAd.show();
                        } else {
                          showSnackBar('Interstitial ad is still loading...');
                        }
                      },
                    ),
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  AdmobBanner(
                    adUnitId: getBannerAdUnitId(),
                    adSize: bannerSize,
                    listener: (AdmobAdEvent event, Map<String, dynamic> args) {
                      handleEvent(event, args, 'Banner');
                    },
                    onBannerCreated: (AdmobBannerController controller) {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  @override
  void dispose() {
    super.dispose();
    if (pilStateSubscription != null) {
      pilStateSubscription.cancel();
    }
  }

  String getInterstitialAdUnitId() {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712';
    }
    return null;
  }

  String getBannerAdUnitId() {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111';
    }
    return null;
  }
}
