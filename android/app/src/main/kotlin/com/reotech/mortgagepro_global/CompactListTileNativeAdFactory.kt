package com.reotech.mortgagepro_global

import android.content.Context
import android.graphics.Color
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory

class CompactListTileNativeAdFactory(private val context: Context) : NativeAdFactory {
    override fun createNativeAd(nativeAd: NativeAd, customOptions: MutableMap<String, Any>?): NativeAdView {
        val adView = LayoutInflater.from(context).inflate(R.layout.ad_compact_list_tile, null) as NativeAdView

        // Map views
        adView.headlineView = adView.findViewById(R.id.ad_headline)
        adView.bodyView = adView.findViewById(R.id.ad_body)
        adView.callToActionView = adView.findViewById(R.id.ad_call_to_action)
        adView.iconView = adView.findViewById(R.id.ad_icon)

        // Set text colors based on dark mode
        val isDark = customOptions?.get("isDark") as? Boolean ?: false
        val headlineTextView = adView.headlineView as? TextView
        val bodyTextView = adView.bodyView as? TextView

        if (isDark) {
            headlineTextView?.setTextColor(Color.parseColor("#FFFFFF"))
            bodyTextView?.setTextColor(Color.parseColor("#E2E8F0"))
        } else {
            headlineTextView?.setTextColor(Color.parseColor("#0B1D3A"))
            bodyTextView?.setTextColor(Color.parseColor("#5B6E8F"))
        }

        // Populate headline
        (adView.headlineView as TextView).text = nativeAd.headline

        // Populate body
        if (nativeAd.body == null) {
            adView.bodyView?.visibility = View.INVISIBLE
        } else {
            adView.bodyView?.visibility = View.VISIBLE
            (adView.bodyView as TextView).text = nativeAd.body
        }

        // Populate CTA
        if (nativeAd.callToAction == null) {
            adView.callToActionView?.visibility = View.INVISIBLE
        } else {
            adView.callToActionView?.visibility = View.VISIBLE
            (adView.callToActionView as Button).text = nativeAd.callToAction
        }

        // Populate icon
        if (nativeAd.icon == null) {
            adView.iconView?.visibility = View.GONE
        } else {
            (adView.iconView as ImageView).setImageDrawable(nativeAd.icon?.drawable)
            adView.iconView?.visibility = View.VISIBLE
        }

        adView.setNativeAd(nativeAd)
        return adView
    }
}
