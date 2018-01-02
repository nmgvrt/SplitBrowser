//
//  BrowserItem.swift
//  SplitBrowser
//
//  Created by ryu on 2017/12/26.
//  Copyright © 2017年 Ryunosuke Tada. All rights reserved.
//

import Cocoa
import WebKit

class BrowserItem: NSCollectionViewItem, WKNavigationDelegate {
    @IBOutlet weak var statusBar: NSView!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var webView: WKWebView!

    private var label: String {
        get {
            return self.textField!.stringValue
        }
        set(val) {
            self.textField!.stringValue = val
        }
    }

    // 各部品の外観の初期化
    func initializeView() {
        self.textField!.cell?.lineBreakMode = .byTruncatingTail
        self.statusBar.wantsLayer = true
        self.statusBar.layer?.backgroundColor = NSColor(calibratedRed: 0, green: 0, blue: 0, alpha: 0.7).cgColor
        self.webView.navigationDelegate = self
        self.progressIndicator.usesThreadedAnimation = false
    }

    // URL からのコンテンツの読み込み
    func load(url: URL) {
        if url.isFileURL {
            self.webView!.loadFileURL(url, allowingReadAccessTo: url)
        } else {
            self.webView?.load(URLRequest(url: url))
        }
    }

    // 外観の設定 (読み込み中)
    private func startLoading(withMessage message: String) {
        self.label = message
        self.statusBar?.isHidden = false
        self.webView!.isHidden = false
        self.progressIndicator?.startAnimation(nil)
    }

    // 外観の設定 (エラー発生)
    private func showError(withMessage message: String) {
        self.startLoading(withMessage: message)
        self.progressIndicator?.stopAnimation(nil)
        self.webView!.isHidden = true
    }

    // 外観の設定 (読み込み完了)
    private func stopLoading() {
        self.statusBar?.isHidden = true
        self.progressIndicator?.stopAnimation(nil)
    }

    // 読み込み開始時に呼ばれる関数
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.startLoading(withMessage: webView.url!.absoluteString)
    }

    // リダイレクト時に呼ばれる関数
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        self.label = webView.url!.absoluteString
    }

    // 読み込み失敗時に呼ばれる関数
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.showError(withMessage: error.localizedDescription)
    }

    // 読み込み失敗時に呼ばれる関数
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        self.showError(withMessage: error.localizedDescription)
    }

    // 読み込み完了時に呼ばれる関数
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.stopLoading()
    }
}
