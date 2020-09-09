package extension.jsrunner;

import android.annotation.TargetApi;
import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.webkit.ConsoleMessage;
import android.webkit.JavascriptInterface;
import android.webkit.WebChromeClient;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceError;
import android.webkit.WebResourceRequest;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import java.lang.Runnable;
import java.util.ArrayList;
import org.haxe.extension.Extension;
import org.haxe.lime.HaxeObject;

public class JSRunner extends Extension {

	protected static boolean inited = false;
	protected static WebView webView;
	protected static ArrayList<HaxeObject> hxHandles;

	public static void init() {
		hxHandles = new ArrayList<HaxeObject>();
	}
	
	public static void registerJSInterface(final JSInterface jsinterface) {
		mainActivity.runOnUiThread(new Runnable() {
			public void run() {
				hxHandles.add(jsinterface.handle);
				webView.addJavascriptInterface(jsinterface, jsinterface.name);
			}
	   	});
	}

	public static void load(final String html) {
		mainActivity.runOnUiThread(new Runnable() {
			public void run() { webView.loadData(html, "text/html", "UTF-8"); }
	   	});
	}
	
	public static void execute(final String js) {
		mainActivity.runOnUiThread(new Runnable() {
			public void run() {
				if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT)
					webView.evaluateJavascript(js, null);
				else
					webView.loadUrl("javascript: " + js);
			}
	   	});
	}

    @Override
	public void onCreate(Bundle savedInstanceState) {
		trace("==========JSRUNNER==========");

        webView = new WebView(mainActivity);
		WebSettings webSettings = webView.getSettings();
		webView.addJavascriptInterface(this, "JSRunner");
        webSettings.setJavaScriptEnabled(true);
        webSettings.setDomStorageEnabled(true);
		webView.setVisibility(View.GONE);
    	webView.setWebViewClient(
			new WebViewClient() {
				@Override
				public void onPageFinished(WebView view, String url) {
					super.onPageFinished(view, url);
					if (!inited) {
						inited = true;
						for (int i = 0; i < hxHandles.size(); i++)
							hxHandles.get(i).call0("onJSRunnerLoaded");
					}
				}

				@Override
				@TargetApi(Build.VERSION_CODES.M)
				public void onReceivedError(WebView view, WebResourceRequest request, WebResourceError error) {
					super.onReceivedError(view, request, error);
					handleConnectionError(view, error.getErrorCode(), error.getDescription().toString(), request.getUrl());
				}

				@Override
				@SuppressWarnings("deprecation")
				public void onReceivedError(WebView view, int errorCode, String description, String failingUrl) {
					super.onReceivedError(view, errorCode, description, failingUrl);
					handleConnectionError(view, errorCode, description, Uri.parse(failingUrl));
				}

				private void handleConnectionError(WebView view, int errorCode, String description, final Uri uri) {
					error("ERROR " + errorCode + ", " + uri.getHost() + ":" +  description);
				}
			}
		);
		webView.setWebChromeClient(
			new WebChromeClient() {
				@Override
				@TargetApi(Build.VERSION_CODES.ICE_CREAM_SANDWICH)
				public boolean onConsoleMessage(ConsoleMessage consoleMessage) {
					handleConsoleMessage(consoleMessage.message(), consoleMessage.lineNumber(), consoleMessage.sourceId());
					return super.onConsoleMessage(consoleMessage);
				}

				@Override
				@SuppressWarnings("deprecation")
				public void onConsoleMessage(String message, int lineNumber, String sourceId) {
					super.onConsoleMessage(message, lineNumber, sourceId);
					handleConsoleMessage(message, lineNumber, sourceId);
				}

				private void handleConsoleMessage(String message, int lineNumber, String sourceId) {
					error(message);
				}
			}
		);
	}

	@JavascriptInterface public void error(String message) { Log.e("jsrunner", message); }
	@JavascriptInterface public void trace(String message) { Log.i("jsrunner", message); }
	
}