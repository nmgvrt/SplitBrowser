//
//  CustomPopUpButton.swift
//  SplitBrowser
//
//  Created by ryu on 2017/12/26.
//  Copyright © 2017年 Ryunosuke Tada. All rights reserved.
//

import Cocoa

// 動的に要素を変化させる PopUpButton
class CustomPopUpButton: NSPopUpButton {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.pullsDown = false
    }

    override init(frame buttonFrame: NSRect, pullsDown flag: Bool) {
        super.init(frame: buttonFrame, pullsDown: false)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // "未選択" を表すアイテムを追加する関数
    // string : 未選択を表す文字列
    //
    // # メニューのすべてのアイテムを削除してから追加
    private func setUnsetTitle(string: String) {
        guard let menu = self.menu else {
            print("menu is nil")
            return
        }
        menu.removeAllItems()

        let unsetTitle = NSMenuItem(title: string, action: nil, keyEquivalent: "")
        menu.addItem(unsetTitle)
        menu.addItem(NSMenuItem.separator())
    }

    func initialize(withTitles titles: [String], unsetTitle: String) {
        self.setUnsetTitle(string: unsetTitle)
        self.addItems(withTitles: titles)
    }
}
