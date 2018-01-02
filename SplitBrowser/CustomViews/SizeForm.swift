//
//  SizeForm.swift
//  SplitBrowser
//
//  Created by ryu on 2017/12/26.
//  Copyright © 2017年 Ryunosuke Tada. All rights reserved.
//

import Cocoa

// サイズ用整数値フォーム
class SizeForm: NumberForm {
    override func userInitProcess() {
        super.userInitProcess()

        self.minValue = 1 // サイズは 1 以上
        self.formValue = self.minValue
        self.increment = 1 // 増減幅は 1
    }
}
