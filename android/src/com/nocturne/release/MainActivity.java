package com.nocturne.release;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.graphics.Color;
import android.os.Bundle;
import android.view.View;
import android.view.Window;
import android.webkit.ValueCallback;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

public class MainActivity extends Activity {

    private WebView web;

    @SuppressLint("SetJavaScriptEnabled")
    @Override
    protected void onCreate(Bundle state) {
        super.onCreate(state);

        Window w = getWindow();
        w.setStatusBarColor(Color.parseColor("#0D1017"));
        w.setNavigationBarColor(Color.parseColor("#06070B"));

        web = new WebView(this);
        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setDatabaseEnabled(true);
        // 보안 하드닝: file:// 교차오리진/유니버설 접근 비허용(기본 false 유지),
        //   파일·콘텐츠 접근 비활성. android_asset/android_res 는 이 설정과 무관하게 로드됨.
        s.setAllowFileAccess(false);
        s.setAllowContentAccess(false);
        s.setUseWideViewPort(true);
        s.setLoadWithOverviewMode(false);
        s.setSupportZoom(false);
        s.setBuiltInZoomControls(false);
        s.setDisplayZoomControls(false);
        // 시스템 글꼴 크기 설정이 레이아웃을 깨뜨리지 않도록 고정
        s.setTextZoom(100);

        web.setBackgroundColor(Color.parseColor("#08090D"));
        web.setOverScrollMode(View.OVER_SCROLL_NEVER);
        web.setVerticalScrollBarEnabled(false);
        web.setHorizontalScrollBarEnabled(false);
        web.setLongClickable(false);
        web.setWebViewClient(new WebViewClient());

        setContentView(web);
        web.loadUrl("file:///android_asset/index.html");
    }

    /** 하드웨어 뒤로가기: 페이지가 처리하면 앱을 유지하고, 아니면 종료. */
    @Override
    public void onBackPressed() {
        if (web == null) {
            super.onBackPressed();
            return;
        }
        web.evaluateJavascript(
            "(function(){try{return window.__onBack?window.__onBack():false}catch(e){return false}})()",
            new ValueCallback<String>() {
                @Override
                public void onReceiveValue(String value) {
                    if (!"true".equals(value)) {
                        finish();
                    }
                }
            });
    }

    @Override
    protected void onDestroy() {
        if (web != null) {
            web.destroy();
            web = null;
        }
        super.onDestroy();
    }
}
