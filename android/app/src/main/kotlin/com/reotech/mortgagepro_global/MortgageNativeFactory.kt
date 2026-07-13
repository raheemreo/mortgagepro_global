package com.reotech.mortgagepro_global

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MortgageNativeFactory(private val context: Context) :
    GoogleMobileAdsPlugin.NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val inflater =
            context.getSystemService(Context.LAYOUT_INFLATER_SERVICE) as LayoutInflater
        val adView =
            inflater.inflate(R.layout.native_ad_medium, null) as NativeAdView

        // Prevent AdChoices icon (auto-inserted by SDK) from being clipped
        // by any parent bounds.
        adView.clipChildren = false
        adView.clipToPadding = false

        val mediaView = adView.findViewById<com.google.android.gms.ads.nativead.MediaView>(R.id.ad_media)
        val headlineView = adView.findViewById<TextView>(R.id.ad_headline)
        val bodyView = adView.findViewById<TextView>(R.id.ad_body)
        val iconView = adView.findViewById<ImageView>(R.id.ad_icon)
        val advertiserView = adView.findViewById<TextView>(R.id.ad_advertiser)
        val ctaView = adView.findViewById<Button>(R.id.ad_cta)
        val adChoicesView = adView.findViewById<com.google.android.gms.ads.nativead.AdChoicesView>(R.id.ad_choices)

        adView.mediaView = mediaView
        adView.headlineView = headlineView
        adView.bodyView = bodyView
        adView.iconView = iconView
        adView.advertiserView = advertiserView
        adView.callToActionView = ctaView
        adView.adChoicesView = adChoicesView

        mediaView.mediaContent = nativeAd.mediaContent
        headlineView.text = nativeAd.headline

        // Optional assets: hide the view entirely if the creative
        // doesn't supply that asset, per Google native ad guidance.
        if (nativeAd.body.isNullOrEmpty()) {
            bodyView.visibility = View.GONE
        } else {
            bodyView.visibility = View.VISIBLE
            bodyView.text = nativeAd.body
        }

        if (nativeAd.icon == null) {
            iconView.visibility = View.GONE
        } else {
            iconView.visibility = View.VISIBLE
            iconView.setImageDrawable(nativeAd.icon?.drawable)
        }

        if (nativeAd.advertiser.isNullOrEmpty()) {
            advertiserView.visibility = View.GONE
        } else {
            advertiserView.visibility = View.VISIBLE
            advertiserView.text = nativeAd.advertiser
        }

        ctaView.text = nativeAd.callToAction
        // CTA is required by policy — never hide it, even if callToAction
        // is unexpectedly null.

        adView.setNativeAd(nativeAd)

        return adView
    }
}
