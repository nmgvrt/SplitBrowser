//
//  NumberForm.swift
//  SplitBrowser
//
//  Created by ryu on 2017/12/26.
//  Copyright © 2017年 Ryunosuke Tada. All rights reserved.
//

import Cocoa

// 整数値用フォーム (ステッパ付)
class NumberForm: AbstractCustomView {
    override var xibName: String { return "NumberForm" } // NumberForm.xib を読み込む

    @IBOutlet weak var label: NSTextField! // ラベル
    @IBOutlet weak var form: NSTextField! // テキストフィールド
    @IBOutlet weak var stepper: NSStepper! // ステッパ
    @IBOutlet var dataModel: NumberFormModel! // データモデル

    // ラベルの値
    var formLabel: String {
        get {
            return self.label.stringValue
        }
        set(val) {
            self.label.stringValue = val
        }
    }

    // フォームの値
    var formValue: Int {
        get {
            return self.dataModel.formValue
        }
        set(val) {
            self.dataModel.setValue(val, forKey: "formValue")
        }
    }

    // ステッパの増減幅
    var increment: Int {
        get {
            return Int(self.stepper.increment)
        }
        set(val) {
            self.stepper.increment = Double(val)
        }
    }

    // 入力値の最小値
    var minValue: Int {
        get {
            return Int(self.stepper.minValue)
        }
        // テキストフィールドのフォーマッタとステッパの両方に設定
        set(val) {
            self.stepper.minValue = Double(val)
            let formatter = self.form.formatter! as! NumberFormatter
            formatter.minimum = NSNumber(value: val)
        }
    }

    // 入力値の最大値
    var maxValue: Int {
        get {
            return Int(self.stepper.maxValue)
        }
        // テキストフィールドのフォーマッタとステッパの両方に設定
        set(val) {
            self.stepper.maxValue = Double(val)
            let formatter = self.form.formatter! as! NumberFormatter
            formatter.maximum = NSNumber(value: val)
        }
    }

    // 初期化
    override func userInitProcess() {
        super.userInitProcess()

        // 整数に限定
        let formatter = self.form.formatter! as! NumberFormatter
        formatter.allowsFloats = false
    }
}
