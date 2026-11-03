package com.konsou.app

import android.os.Bundle
import android.webkit.WebView
import androidx.activity.OnBackPressedCallback
import androidx.activity.enableEdgeToEdge

class MainActivity : TauriActivity() {
  // Take over the hardware back button and the predictive back gesture.
  //
  // Tauri's default (WryActivity) finishes the activity whenever the webview
  // has no history to pop. Our router keeps webview history pinned to a single
  // entry on purpose — back is owned by the JS per-tab stacks in lib/navStacks
  // and hooks/useAppBack. With the default handler, canGoBack() is always false,
  // so every back press exited the app instead of closing a sheet or stepping
  // back a page. Disabling it and forwarding the press into JS fixes that.
  override val handleBackNavigation: Boolean = false

  private var webView: WebView? = null

  override fun onCreate(savedInstanceState: Bundle?) {
    enableEdgeToEdge()
    super.onCreate(savedInstanceState)

    onBackPressedDispatcher.addCallback(
      this,
      object : OnBackPressedCallback(true) {
        override fun handleOnBackPressed() {
          val wv = webView
          if (wv != null) {
            // Run the one back policy in hooks/useAppBack. It decides whether to
            // close a sheet, pop the tab stack, or arm the double-tap to exit.
            wv.evaluateJavascript("window.__konsouBack && window.__konsouBack()", null)
          } else {
            // Webview not up yet (very early boot): nothing to hand off to.
            finish()
          }
        }
      },
    )
  }

  override fun onWebViewCreate(webView: WebView) {
    this.webView = webView
  }
}
