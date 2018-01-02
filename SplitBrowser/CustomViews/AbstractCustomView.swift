//
//  AbstractCustomView.swift
//  SplitBrowser
//
//  Created by ryu on 2017/12/26.
//  Copyright © 2017年 Ryunosuke Tada. All rights reserved.
//

import Cocoa

// xib で定義した自作ビューを使うための抽象的クラス
@IBDesignable class AbstractCustomView: NSView {
    var xibName: String { return "change me!" } // 読み込む xib ファイルの名前

    // xibName で nib を読み込む関数
    private func loadFromNib(withFrame frame: NSRect? = nil) {
        var topLevelObjects: NSArray?
        if Bundle(for: type(of: self)).loadNibNamed(NSNib.Name(rawValue: self.xibName), owner: self, topLevelObjects: &topLevelObjects) {
            if let view = topLevelObjects!.first(where: {$0 is NSView}) as? NSView {
                view.frame = frame != nil ? frame! : self.bounds
                self.addSubview(view)
            } else {
                fatalError("Invalid xibName : \(self.xibName) (TopLevelObjects is nil)")
            }
        } else {
            fatalError("Invalid xibName : \(self.xibName)")
        }
    }

    // ユーザによる初期化のためのフック
    internal func userInitProcess() {
    }

    /* 初期化関連のメソッド */

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.loadFromNib(withFrame: frameRect)
        self.userInitProcess()
    }

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        self.loadFromNib()
        self.userInitProcess()
    }

    override func prepareForInterfaceBuilder() {
        self.loadFromNib()
        self.userInitProcess()
    }
}
