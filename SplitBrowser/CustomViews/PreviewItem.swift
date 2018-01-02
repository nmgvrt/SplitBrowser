//
//  PreviewItem.swift
//  SplitBrowser
//
//  Created by ryu on 2017/12/26.
//  Copyright © 2017年 Ryunosuke Tada. All rights reserved.
//

import Cocoa

class PreviewItem: NSCollectionViewItem {
    var label: String {
        get {
            return self.textField!.stringValue
        }
        set(val) {
            self.textField?.stringValue = val
        }
    }

    override var isSelected: Bool {
        didSet {
            // 選択されているとき枠線を表示
            self.view.layer?.borderWidth = self.isSelected ? 3.0 : 0.0
        }
    }

    var toolTip: String = "" {
        didSet {
            // URL が設定されているかどうかで配色を決定
            self.view.toolTip = self.toolTip
            if self.toolTip == PresetManager.defaultUrlFormValue {
                self.view.layer?.borderColor = NSColor(calibratedRed: 0.6, green: 0.6, blue: 0.6, alpha: 1.0).cgColor
                self.view.layer?.backgroundColor = NSColor(calibratedRed: 0.8, green: 0.8, blue: 0.8, alpha: 1.0).cgColor
            } else {
                self.view.layer?.borderColor = NSColor(calibratedRed: 0.0, green: 0.6, blue: 0.85, alpha: 1.0).cgColor
                self.view.layer?.backgroundColor = NSColor(calibratedRed: 0.5, green: 0.85, blue: 1.0, alpha: 1.0).cgColor
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.wantsLayer = true
    }
}
