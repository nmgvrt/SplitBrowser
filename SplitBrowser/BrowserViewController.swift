//
//  BrowserViewController.swift
//  SplitBrowser
//
//  Created by ryu on 2017/09/25.
//  Copyright © 2017年 Ryunosuke Tada. All rights reserved.
//

import Cocoa

class BrowserViewController: NSViewController, NSCollectionViewDataSource {
    @IBOutlet weak var browserCollection: NSCollectionView!

    private var preset: Preset! // 現在のプリセット

    override func viewDidLoad() {
        super.viewDidLoad()

        PresetManager.createCurrentPresetIfUnset() // 現在のプリセットが設定されていなければ設定
        PresetManager.createUserPresetsDictionaryIfUnset() // ユーザ定義プリセットが設定されていなければ設定
        if PresetManager.loadCurrentPreset().temporary { // 一時プリセットが残っている時
            PresetManager.storeCurrentPreset(instance: Preset()) // 標準値に更新
        }

        self.browserCollection.dataSource = self

        // CollectionView の FlowLayout の初期設定
        let fl = NSCollectionViewFlowLayout()
        fl.minimumLineSpacing = 0
        fl.minimumInteritemSpacing = 0
        fl.sectionInset = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        fl.itemSize = NSSize(width: 1, height: 1)
        self.browserCollection.collectionViewLayout = fl

        self.loadContents()
    }

    override func viewDidLayout() {
        super.viewDidLayout()

        self.fit()
    }

    // 各ブラウザのサイズをウィンドウに合わせる
    private func fit() {
        guard let layout = self.browserCollection.collectionViewLayout else {
            return
        }
        
        let fl = layout as! NSCollectionViewFlowLayout
        let width = (self.view.frame.width - 2) / CGFloat(self.preset.col)
        let height = (self.view.frame.height - 2) / CGFloat(self.preset.row)
        fl.itemSize = NSSize(width: width, height: height)
    }

    // 分割画面を更新する関数
    func loadContents() {
        self.preset = PresetManager.loadCurrentPreset()
        self.fit()
        self.browserCollection.reloadData()
    }

    // 分割画面の縦方向の分割数を返す関数
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return self.preset.row
    }

    // 分割画面の横方向の分割数を返す関数
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.preset.col
    }

    // 分割画面の各セルを返す関数
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "BrowserItem"), for: indexPath)

        let browserItem = item as! BrowserItem
        browserItem.initializeView()
        browserItem.load(url: self.preset.loadUrl(x: indexPath.item, y: indexPath.section))

        return item
    }
}
