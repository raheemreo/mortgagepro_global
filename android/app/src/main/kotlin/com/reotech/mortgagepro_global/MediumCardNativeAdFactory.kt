package com.reotech.mortgagepro_global

import android.content.Context
import android.graphics.Color
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.RatingBar
import android.widget.TextView
import com.google.android.gms.ads.nativead.AdChoicesView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory

class MediumCardNativeAdFactory(private val context: Context) : NativeAdFactory {
    override fun createNativeAd(nativeAd: NativeAd, customOptions: MutableMap<String, Any>?): NativeAdView {
        val adView = LayoutInflater.from(context).inflate(R.layout.ad_medium_card, null) as NativeAdView

        // ── Register all asset views with the NativeAdView ─────────────────
        adView.headlineView     = adView.findViewById(R.id.ad_headline)
        adView.bodyView         = adView.findViewById(R.id.ad_body)
        adView.callToActionView = adView.findViewById(R.id.ad_call_to_action)
        adView.iconView         = adView.findViewById(R.id.ad_icon)
        adView.mediaView        = adView.findViewById(R.id.ad_media)
        adView.advertiserView   = adView.findViewById(R.id.ad_advertiser)
        adView.starRatingView   = adView.findViewById(R.id.ad_stars)
        adView.storeView        = adView.findViewById(R.id.ad_store)
        // AdChoicesView: registering gives precise top-right placement control.
        // Without this the SDK auto-picks a corner, risking content overlap.
        adView.adChoicesView    = adView.findViewById(R.id.ad_choices)

        // ── Dark / light mode colours ──────────────────────────────────────
        val isDark = customOptions?.get("isDark") as? Boolean ?: false
        val headlineColor = if (isDark) Color.parseColor("#FFFFFF") else Color.parseColor("#0B1D3A")
        val bodyColor     = if (isDark) Color.parseColor("#E2E8F0") else Color.parseColor("#5B6E8F")

        (adView.headlineView as? TextView)?.setTextColor(headlineColor)
        (adView.bodyView     as? TextView)?.setTextColor(bodyColor)
        (adView.storeView    as? TextView)?.setTextColor(bodyColor)

        // ── Headline (required) ────────────────────────────────────────────
        (adView.headlineView as TextView).text = nativeAd.headline

        // ── Body ──────────────────────────────────────────────────────────
        val body = nativeAd.body
        if (body.isNullOrEmpty()) {
            adView.bodyView?.visibility = View.INVISIBLE
        } else {
            adView.bodyView?.visibility = View.VISIBLE
            (adView.bodyView as TextView).text = body
        }

        // ── Advertiser name ────────────────────────────────────────────────
        val advertiser = nativeAd.advertiser
        val advertiserView = adView.advertiserView as? TextView
        if (!advertiser.isNullOrEmpty()) {
            advertiserView?.text = advertiser
            advertiserView?.visibility = View.VISIBLE
        } else {
            advertiserView?.visibility = View.GONE
        }

        // ── CTA ───────────────────────────────────────────────────────────
        val cta = nativeAd.callToAction
        if (cta.isNullOrEmpty()) {
            adView.callToActionView?.visibility = View.INVISIBLE
        } else {
            adView.callToActionView?.visibility = View.VISIBLE
            (adView.callToActionView as Button).text = cta
        }

        // ── Icon ──────────────────────────────────────────────────────────
        val icon = nativeAd.icon
        if (icon == null) {
            adView.iconView?.visibility = View.GONE
        } else {
            (adView.iconView as ImageView).setImageDrawable(icon.drawable)
            adView.iconView?.visibility = View.VISIBLE
        }

        // ── Media ─────────────────────────────────────────────────────────
        val mediaView = adView.mediaView as? MediaView
        val mediaContent = nativeAd.mediaContent
        if (mediaView != null && mediaContent != null) {
            mediaView.mediaContent = mediaContent
        }

        // ── Star rating (app-install ads) ──────────────────────────────────
        val starsContainer = adView.findViewById<LinearLayout>(R.id.ad_stars_container)
        val starRating = nativeAd.starRating
        if (starRating != null && starRating > 0.0) {
            (adView.starRatingView as? RatingBar)?.rating = starRating.toFloat()
            starsContainer?.visibility = View.VISIBLE
        } else {
            starsContainer?.visibility = View.GONE
        }

        // ── Store / price (app-install ads) ───────────────────────────────
        val store = nativeAd.store
        val price = nativeAd.price
        val storeView = adView.storeView as? TextView
        val storeLabel = when {
            !store.isNullOrEmpty() && !price.isNullOrEmpty() -> "$store · $price"
            !store.isNullOrEmpty() -> store
            !price.isNullOrEmpty() -> price
            else -> null
        }
        if (storeLabel != null) {
            storeView?.text = storeLabel
            storeView?.visibility = View.VISIBLE
        } else {
            storeView?.visibility = View.GONE
        }

        adView.setNativeAd(nativeAd)
        return adView
    }
}
