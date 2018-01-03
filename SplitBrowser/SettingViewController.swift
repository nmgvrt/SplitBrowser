//
//  SettingViewController.swift
//  SplitBrowser
//
//  Created by ryu on 2017/12/26.
//  Copyright © 2017年 Ryunosuke Tada. All rights reserved.
//

import Cocoa

// 設定画面のコントローラ
class SettingViewController: NSViewController, NSCollectionViewDelegate, NSCollectionViewDataSource, NSTextFieldDelegate {
    @IBOutlet weak var presetPopUp: CustomPopUpButton! // プリセット選択
    @IBOutlet weak var manageButtonGroup: NSSegmentedCell! // プリセット管理ボタン(削除・複製・保存)
    @IBOutlet weak var nameForm: NSTextField! // プリセット名用フォーム
    @IBOutlet weak var rowForm: SizeForm! // 縦方向の分割数用フォーム
    @IBOutlet weak var colForm: SizeForm! // 横方向の分割数用フォーム
    @IBOutlet weak var viewCollection: NSCollectionView! // 分割画面選択用画面
    @IBOutlet weak var urlForm: NSTextField! // URL 用フォーム
    @IBOutlet weak var fileChooserButton: NSButton! // ファイル選択ボタン

    private var savedPreset: Preset! // 変更前のプリセット
    private var preset: Preset! // 変更後のプリセット
    private var userPresets: [String: Preset]! // ユーザ定義のプリセット

    private let cellHeight: Int = 50 // 分割画面選択用画面のセルの高さ
    private let xSpacing: Int = 10 // 分割画面選択用画面のセル同士の横方向の間隔
    private let ySpacing: Int = 10 // 分割画面選択用画面のセル同士の縦方向の間隔

    // プリセット管理用ボタンのインデックス
    enum manageButtonType: Int {
        case delete = 0
        case duplicate = 1
        case save = 2
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.changePreset(instance: PresetManager.loadCurrentPreset()) // 設定ファイルからプリセットを読み込み
        self.userPresets = PresetManager.loadUserPresets() // 設定ファイルからユーザ定義プリセットを読み込み

        // CollectionView の設定
        self.viewCollection.delegate = self
        self.viewCollection.dataSource = self
        self.configureCollectionView()

        // フォームの初期化
        self.rowForm.formLabel = "分割数(縦)"
        self.rowForm.maxValue = PresetManager.maxRow
        self.colForm.formLabel = "分割数(横)"
        self.colForm.maxValue = PresetManager.maxCol
        self.urlForm.delegate = self

        // プリセットの値をフォームに反映
        self.loadFormValues()
    }

    override func viewDidLayout() {
        super.viewDidLayout()

        self.fitCell() // リサイズされたときにセルの大きさを合わせる
    }

    // 現在のプリセットを設定する関数
    private func changePreset(instance: Preset) {
        self.savedPreset = instance
        self.preset = self.savedPreset.clone()
    }

    // ユーザデータを更新して画面を再読み込み
    func reloadAll() {
        self.changePreset(instance: Preset())
        self.userPresets = PresetManager.loadUserPresets()
        self.loadFormValues()
    }

    /* フォームの読み込み操作関連メソッド */

    // 選択されたセルに設定された URL をフォームに反映させる関数
    private func loadUrl() {
        var urlString = ""
        if self.viewCollection.selectionIndexPaths.count > 0 { // 選択されたセルがあるとき
            let indexPath = self.viewCollection.selectionIndexPaths.first!
            let url = self.preset.loadUrl(x: indexPath.item, y: indexPath.section) // 選択されたセルの URL を取得
            urlString = PresetManager.getDisplayUrl(instance: url)
            
            let item = viewCollection.item(at: indexPath)! as! PreviewItem
            item.toolTip = urlString // セルのツールチップを設定
        }

        self.urlForm.stringValue = urlString
    }

    // 現在のプリセットの値を画面に反映させる関数
    private func loadFormValues() {
        let currentPreset: Preset = self.preset

        // プリセットからフォームの値を更新
        self.nameForm.stringValue = currentPreset.name
        self.rowForm.formValue = currentPreset.row
        self.colForm.formValue = currentPreset.col
        self.loadUrl()

        // ポップアップボタンを初期化
        let presetNames = Array(self.userPresets.mapValues { $0.name }.values)
        self.presetPopUp.initialize(withTitles: presetNames.sorted(), unsetTitle: PresetManager.unsetTitle)
        if currentPreset.temporary {
            self.presetPopUp.selectItem(at: 0)
        } else {
            self.presetPopUp.selectItem(withTitle: currentPreset.name)
        }

        self.reloadViewCollection()

        // 一時プリセットのとき「削除」ボタンを無効化
        if currentPreset.temporary {
            self.manageButtonGroup.setEnabled(false, forSegment: manageButtonType.delete.rawValue)
        } else {
            self.manageButtonGroup.setEnabled(true, forSegment: manageButtonType.delete.rawValue)
        }
    }

    /* フォームの書き込み操作関連メソッド */

    // フォームの入力値についてのエラーダイアログを表示する関数
    private class func showFormValidationErrorDialog(string: String) {
        showErrorDialog(withTitle: "入力値エラー", message: string)
    }

    // URL フォームの値をプリセットに書き込む関数 (URL チェックなし)
    private func forceStoreUrl(string: String? = nil) throws {
        let selected = viewCollection.selectionIndexPaths.first!
        // 書き込む値 (string) が与えられたときはそのまま使う
        // そうでなければ URL フォームの値を使う
        let url = string == nil ? self.urlForm.stringValue : string!
        let urlObj = URL(string: url)
        guard urlObj != nil else { // URL クラスのインスタンスが作れなかったら例外を投げる
            throw NSError(domain: "\(url) は無効な URL です", code: -1, userInfo: nil)
        }
        self.preset.setUrl(instance: urlObj!, x: selected.item, y: selected.section)
    }

    // URL フォームの値をプリセットに書き込む関数 (URL チェックあり)
    private func storeUrl() throws {
        guard self.viewCollection.selectionIndexPaths.count > 0 else {
            return // セルが選択されていないとき終了
        }

        let url = self.urlForm.stringValue
        if url.starts(with: "http:") || url.starts(with: "https:") { // URL フォームの値が http: または https: ではじまるとき
            try self.forceStoreUrl() // URL をプリセットに書き込み
        } else {
            let selected = self.viewCollection.selectionIndexPaths.first! // 選択されているセルを取得
            let currentUrl = self.preset.loadUrl(x: selected.item, y: selected.section) // 現在のセルの URL を取得
            if !(currentUrl.isFileURL && url == currentUrl.lastPathComponent) { // ローカルファイルのファイル名でなければ無効な文字列
                throw NSError(domain: "\(url) は無効な URL です", code: -1, userInfo: nil)
            }
        }
    }

    // フォームの値をプリセットに書き込む関数
    private func storeFormValues(exceptName: Bool = false) throws {
        guard let currentPreset = self.preset else {
            return
        }

        if !exceptName {
            currentPreset.name = self.nameForm.stringValue
        }
        try self.storeUrl()
    }

    // ローカルファイルの URL をプリセットに書き込む関数
    private func storeFileUrl(string: String) {
        try! self.forceStoreUrl(string: string)
        self.loadUrl()
    }

    // 与えられたキーでプリセットを保存できるかチェックして登録する関数
    private func assignPreset(key: String, overwrite: Bool = false) throws {
        if !overwrite { // 新規追加時
            // 保存上限に達したとき追加不可
            guard self.userPresets!.count < PresetManager.maxPreset else {
                throw NSError(domain: "プリセット保存上限数は \(PresetManager.maxPreset) 件です", code: -1, userInfo: nil)
            }
        }

        // すでにキーが使用されているとき追加不可
        guard self.userPresets![key] == nil && key != PresetManager.unsetTitle else {
            throw NSError(domain: "プリセット名 : \(key) はすでに使用されています", code: -1, userInfo: nil)
        }

        self.preset.name = key
    }

    // フォームの値から新しいプリセットを登録する関数
    private func storeUserPresets(duplicate: Bool = false) throws {
        try self.storeFormValues(exceptName: true) // フォームの値をプリセットに書き込み

        let key = self.nameForm.stringValue // 現在のキー (プリセット名)
        if self.preset.temporary || duplicate { // 現在のプリセットが一時的なもののとき または 複製時
            try self.assignPreset(key: key) // キーが利用可能かどうかの確認
            if duplicate { // 複製時は現在のプリセットの複製を作成
                let data = NSKeyedArchiver.archivedData(withRootObject: self.preset!)
                self.preset = NSKeyedUnarchiver.unarchiveObject(with: data) as! Preset
            }
            self.preset!.temporary = false // 一時的なプリセットから永続的なプリセットへ変更
        } else { // 上書き保存時
            let previousKey = self.savedPreset.name // 変更前のキー (プリセット名)
            if previousKey != key { // プリセット名が変更されたとき
                try self.assignPreset(key: key, overwrite: true) // 新しいキーで保存できないとき例外発生
                self.userPresets.removeValue(forKey: previousKey) // ユーザ定義プリセットから変更前のキーを削除
            }
        }

        self.savedPreset = self.preset.clone() // 現在のプリセットを保存
        self.userPresets![key] = self.savedPreset // 現在のプリセットを現在のキーで登録
        PresetManager.storeUserPresets(dictionary: self.userPresets!) // ユーザ定義プリセットを設定ファイルへ書き込み
        self.loadFormValues() // フォームを更新
    }

    /* CollectionView 用メソッド */

    // CollectionView のセルの大きさを設定する関数
    private func fitCell() {
        let fl = self.viewCollection.collectionViewLayout as! NSCollectionViewFlowLayout
        let xPadding: Int = self.xSpacing * (self.preset.col + 1) // 横方向の余白の合計
        let containerWidth: Int = Int(self.viewCollection.frame.size.width) - xPadding // 横方向のコンテンツの幅
        let width: Int = (containerWidth / self.preset.col) // セル 1 つあたりの幅
        fl.itemSize = NSSize(width: width, height: self.cellHeight)
    }

    // CollectionView の FlowLayout を設定する関数
    private func configureCollectionView() {
        let fl = NSCollectionViewFlowLayout()
        fl.sectionInset = NSEdgeInsets(
            top: CGFloat(self.ySpacing / 2), left: CGFloat(self.xSpacing),
            bottom: CGFloat(self.ySpacing / 2), right: CGFloat(self.xSpacing))

        fl.minimumInteritemSpacing = CGFloat(self.xSpacing)
        fl.minimumLineSpacing = CGFloat(self.ySpacing)
        self.viewCollection.collectionViewLayout = fl
        self.fitCell()
    }
    // 分割画面選択用画面が何行あるかを返す関数
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return self.preset.row
    }

    // 分割画面選択用画面が何列あるかを返す関数
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.preset.col
    }

    // それぞれのセルを返す関数
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PreviewItem"), for: indexPath)

        // ラベルに画面番号, ツールチップに URL を設定
        let previewItem = item as! PreviewItem
        previewItem.label = String(indexPath.section * self.preset.col + indexPath.item + 1)
        let url = self.preset.loadUrl(x: indexPath.item, y: indexPath.section)
        previewItem.toolTip = PresetManager.getDisplayUrl(instance: url)

        return item
    }

    // 分割画面選択用画面を再描画する関数
    private func reloadViewCollection() {
        self.fitCell()
        self.viewCollection.reloadData()
    }

    // セルが選択されたときに呼ばれる関数
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        self.urlForm.isEnabled = true
        self.fileChooserButton.isEnabled = true

        self.loadUrl()
    }

    // セルが選択解除されたときに呼ばれる関数
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
        self.urlForm.isEnabled = false
        self.fileChooserButton.isEnabled = false

        self.loadUrl()
    }

    /* ユーザアクション関連のメソッド */

    // プリセットの選択時に呼ばれる関数
    @IBAction func selectedPreset(_ sender: NSPopUpButton) {
        if sender.indexOfSelectedItem == 0 { // 最初のプリセットが選ばれた時
            self.changePreset(instance: Preset()) // 標準値を読み込み
        } else {
            let selectedPreset = self.userPresets[sender.titleOfSelectedItem!] // ユーザ定義プリセットから選択されたプリセットを読み込み
            assert(selectedPreset != nil)
            self.changePreset(instance: selectedPreset!)
        }

        self.loadFormValues()
    }
    
    // URL フォームの編集完了時に呼ばれる関数
    override func controlTextDidEndEditing(_ obj: Notification) {
        do {
            try self.storeUrl()
            self.loadUrl()
        } catch let err {
            SettingViewController.showFormValidationErrorDialog(string: err.localizedDescription)
        }
    }

    // 分割数変更ボタンのクリック時に呼ばれる関数
    @IBAction func clickedChangeSizeButton(_ sender: NSButton) {
        self.preset.row = self.rowForm.formValue
        self.preset.col = self.colForm.formValue
        self.loadFormValues()
    }

    // プリセット管理ボタンのクリック時に呼ばれる関数
    @IBAction func clickedManageButtonGroup(_ sender: NSSegmentedControl) {
        let buttonType = manageButtonType(rawValue: sender.selectedSegment)!
        switch buttonType {
        case .delete:
            self.userPresets.removeValue(forKey: self.preset.name) // ユーザ定義プリセットから現在のプリセットを削除
            PresetManager.storeUserPresets(dictionary: self.userPresets) // 設定ファイルを更新
            self.changePreset(instance: Preset()) // 標準値を読み込み
            break
        case .duplicate:
            var cloneName = self.preset.name // 複製名
            while true { // 使われていない名前が見つかるまで繰り返し
                cloneName = PresetManager.getCloneName(original: cloneName)
                if self.userPresets![cloneName] == nil {
                    break
                }
            }

            self.nameForm.stringValue = cloneName // プリセット名を更新
            do {
                try self.storeUserPresets(duplicate: true) // 現在のプリセットを保存
            } catch let err {
                SettingViewController.showFormValidationErrorDialog(string: err.localizedDescription)
                return
            }
            break
        case .save:
            do {
                try self.storeUserPresets() // 現在のプリセットを保存
            } catch let err {
                SettingViewController.showFormValidationErrorDialog(string: err.localizedDescription)
                return
            }
            break
        }

        self.loadFormValues() // フォームの更新
    }

    // ファイル選択ボタンのクリック時に呼ばれる関数
    @IBAction func clickedFileChooserButton(_ sender: NSButton) {
        // ファイル選択ダイアログの生成
        let dialog = NSOpenPanel()
        dialog.canChooseDirectories = false
        dialog.allowsMultipleSelection = false

        let response = dialog.runModal()
        if response == NSApplication.ModalResponse.OK {
            let selectedUrl = dialog.url! // 選択されたファイルのパス
            do {
                try PresetManager.storeLocalFile(fromUrl: selectedUrl) // 選択されたファイルのコピーをアクセス可能な領域に作成
            } catch let err {
                showErrorDialog(withTitle: "一時ファイル作成時エラー", message: err.localizedDescription)
                return
            }
            let localUrl = PresetManager.getLocalFileUrl(string: selectedUrl.lastPathComponent) // ローカルファイルのコピーのパスを取得
            self.storeFileUrl(string: localUrl.absoluteString) // プリセットにローカルファイルのコピーのパスを書き込み
        }
    }

    // キャンセルボタンのクリック時に呼ばれる関数
    @IBAction func clickedCancel(_ sender: NSButton) {
        self.view.window!.close()
    }
    // OK ボタンのクリック時に呼ばれる関数
    @IBAction func clickedOk(_ sender: NSButton) {
        // 一時的にプリセットの変更を保持する
        do {
            // 現在の状態をプリセットに書き込む
            try self.storeFormValues(exceptName: !self.preset.temporary) // 現在の状態をプリセットに書き込む
        } catch let err {
            SettingViewController.showFormValidationErrorDialog(string: err.localizedDescription)
            return
        }
        PresetManager.storeCurrentPreset(instance: self.preset)

        self.view.window!.close()

        // 分割ブラウザの画面を更新
        if let mainWindow = NSApplication.shared.mainWindow {
            if let viewController = mainWindow.contentViewController {
                let browserViewController = viewController as! BrowserViewController
                browserViewController.loadContents()
            }
        }
    }
}
