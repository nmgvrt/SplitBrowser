//
//  AppDelegate.swift
//  SplitBrowser
//
//  Created by ryu on 2017/09/25.
//  Copyright © 2017年 Ryunosuke Tada. All rights reserved.
//

import Cocoa

let mainVCClassName = "SplitBrowser.BrowserViewController"

func showErrorDialog(withTitle title: String, message: String) {
    let alert = NSAlert()
    alert.alertStyle = NSAlert.Style.critical
    alert.messageText = title
    alert.informativeText = message
    alert.runModal()
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    // すべてのユーザデータを消去
    @IBAction func resetAllData(_ sender: NSMenuItem) {
        PresetManager.storeCurrentPreset(instance: Preset())
        PresetManager.storeUserPresets(dictionary: [:])

        if let vc = NSApplication.shared.mainWindow?.contentViewController {
            if vc.className == mainVCClassName {
                (vc as! BrowserViewController).loadContents()
            } else {
                (vc as! SettingViewController).reloadAll()
            }
        }
    }

    // すべてのブラウザを更新する関数
    @IBAction func reloadAll(_ sender: NSMenuItem) {
        if let vc = NSApplication.shared.mainWindow?.contentViewController {
            if vc.className == mainVCClassName { // メイン画面のとき
                let collection = (vc as! BrowserViewController).browserCollection.visibleItems() // すべてのブラウザを取得
                collection.forEach { ($0 as! BrowserItem).webView.reload() }
            } else {
                showErrorDialog(withTitle: "エラー", message: "メイン画面以外では実行できません")
            }
        }

    }
}
