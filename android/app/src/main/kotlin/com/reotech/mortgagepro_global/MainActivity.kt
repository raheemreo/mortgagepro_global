package com.reotech.mortgagepro_global

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register smallListTile Custom Native Ad Factory
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "smallListTile",
            SmallListTileNativeAdFactory(context)
        )

        // Register compactListTile Custom Native Ad Factory
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "compactListTile",
            CompactListTileNativeAdFactory(context)
        )

        // Register contentAd Custom Native Ad Factory
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "contentAd",
            ContentNativeAdFactory(context)
        )

        // Register mediumCard Custom Native Ad Factory
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "mediumCard",
            MediumCardNativeAdFactory(context)
        )

        // Register lenderNativeAd Custom Native Ad Factory
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "lenderNativeAd",
            MediumCardNativeAdFactory(context)
        )

        // Register largeBanner Custom Native Ad Factory
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "largeBanner",
            LargeBannerNativeAdFactory(context)
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        super.cleanUpFlutterEngine(flutterEngine)

        // Unregister factories to prevent memory leaks
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "smallListTile")
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "compactListTile")
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "contentAd")
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "mediumCard")
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "lenderNativeAd")
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "largeBanner")
    }
}
