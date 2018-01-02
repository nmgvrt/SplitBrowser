//
//  Preset.swift
//  SplitBrowser
//
//  Created by ryu on 2017/12/26.
//  Copyright © 2017年 Ryunosuke Tada. All rights reserved.
//

import Foundation

let currentPresetKey: String = "currentPreset" // 現在のプリセットのキー
let userPresetsKey: String = "userPresets" // ユーザ定義プリセット(リスト)のキー

// プリセット管理用クラス
class PresetManager {
    static let maxRow: Int = 5 // 縦方向の最大分割数
    static let maxCol: Int = 5 // 横方向の最大分割数
    static let maxPreset: Int = 30 // プリセットの最大保存可能数
    static let defaultUrlFormValue: String = "http://" // 標準の URL フォームの値
    static let unsetTitle: String = "新規プリセット" // 未保存のプリセットの表示名

    // UserDefaults に現在のプリセットが設定されていない場合に標準値で設定する関数
    class func createCurrentPresetIfUnset() {
        if UserDefaults.standard.object(forKey: currentPresetKey) == nil {
            PresetManager.storeCurrentPreset(instance: Preset())
        }
    }

    // 現在のプリセットを読み込む関数
    class func loadCurrentPreset() -> Preset {
        let data = UserDefaults.standard.object(forKey: currentPresetKey) as! Data
        
        return NSKeyedUnarchiver.unarchiveObject(with: data) as! Preset
    }

    // 現在のプリセットを設定する関数
    class func storeCurrentPreset(instance: Preset) {
        let data = NSKeyedArchiver.archivedData(withRootObject: instance)
        UserDefaults.standard.set(data, forKey: currentPresetKey)
    }

    // UserDefaults にユーザ定義プリセットが設定されていない場合に設定する関数
    class func createUserPresetsDictionaryIfUnset() {
        if UserDefaults.standard.object(forKey: userPresetsKey) == nil {
            PresetManager.storeUserPresets(dictionary: [:])
        }
    }

    // ユーザ定義プリセットを読み込む関数
    class func loadUserPresets() -> [String: Preset] {
        let data = UserDefaults.standard.object(forKey: userPresetsKey) as! Data

        return NSKeyedUnarchiver.unarchiveObject(with: data) as! [String: Preset]
    }

    // ユーザ定義プリセットを設定する関数
    class func storeUserPresets(dictionary: [String: Preset]) {
        let data = NSKeyedArchiver.archivedData(withRootObject: dictionary)
        UserDefaults.standard.set(data, forKey: userPresetsKey)
    }

    // プリセット複製時のプリセット名を返す関数
    class func getCloneName(original: String) -> String {
        return "\(original)のコピー"
    }

    // ローカルファイルのコピーの保存先を返す関数
    class var localFilePoolUrl: URL {
        get {
            let home = FileManager.default.homeDirectoryForCurrentUser
            return home.appendingPathComponent("Library").appendingPathComponent("LocalFilePool")
        }
    }

    // 与えられたファイル名からコピーの保存先を返す関数
    class func getLocalFileUrl(string: String) -> URL {
        return PresetManager.localFilePoolUrl.appendingPathComponent(string)
    }

    // ローカルファイルをコピーして保存する関数
    class func storeLocalFile(fromUrl src: URL) throws {
        let fm = FileManager.default
        let pool = PresetManager.localFilePoolUrl // ローカルファイルのコピーの保存先
        if !fm.fileExists(atPath: pool.path) { // ディレクトリが存在しないとき作成
            try fm.createDirectory(at: pool, withIntermediateDirectories: true, attributes: nil)
        }
        let dst = pool.appendingPathComponent(src.lastPathComponent) // ローカルファイルのコピーの保存先
        if fm.fileExists(atPath: dst.path) { // すでにファイルが存在するとき削除
            try fm.removeItem(at: dst)
        }
        let contents = try Data(contentsOf: src) // 与えられたローカルファイルのデータを読み込み
        fm.createFile(atPath: dst.path, contents: contents, attributes: nil) // ローカルファイルのコピーを作成
    }

    // 表示用の URL を返す関数
    class func getDisplayUrl(instance: URL) -> String {
        if instance.isFileURL { // ファイルの URL のとき
            return instance.lastPathComponent // ファイル名だけを返す
        } else {
            return instance.absoluteString
        }
    }
}

// プリセットクラス
class Preset: NSObject, NSCoding {
    var name: String = "名称未設定" // プリセット名
    var row: Int = 1 // 縦方向の分割数
    var col: Int = 1 // 横方向の分割数
    var urls: [URL] = [] // 分割画面それぞれの URL
    var temporary: Bool = true // 一時的なプリセットかどうか

    override init() {
        super.init()

        // URL の初期化
        let stringUrls = Array(
            repeating: PresetManager.defaultUrlFormValue,
            count: PresetManager.maxRow * PresetManager.maxCol)
        self.urls = stringUrls.map { URL(string: $0)! }
    }

    // (x, y) の画面の URL を返す関数
    func loadUrl(x: Int, y: Int) -> URL {
        return self.urls[y * PresetManager.maxCol + x]
    }

    // (x, y) の画面の URL を設定する関数
    func setUrl(instance: URL, x: Int, y: Int) {
        self.urls[y * PresetManager.maxCol + x] = instance
    }

    // 自身の複製を返す関数
    func clone() -> Preset {
        let data = NSKeyedArchiver.archivedData(withRootObject: self)

        return NSKeyedUnarchiver.unarchiveObject(with: data) as! Preset
    }

    // シリアライズ用関数
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.name, forKey: "name")
        aCoder.encode(self.row, forKey: "row")
        aCoder.encode(self.col, forKey: "col")
        aCoder.encode(self.temporary, forKey: "temporary")

        let stringUrls: [String] = self.urls.map { $0.absoluteString }
        aCoder.encode(stringUrls, forKey: "urls")
    }

    // デシリアライズ用関数
    required init?(coder aDecoder: NSCoder) {
        self.name = aDecoder.decodeObject(forKey: "name") as! String
        self.row = aDecoder.decodeInteger(forKey: "row")
        self.col = aDecoder.decodeInteger(forKey: "col")
        self.temporary = aDecoder.decodeBool(forKey: "temporary")

        let stringUrls: [String] = aDecoder.decodeObject(forKey: "urls") as! [String]
        self.urls = stringUrls.map { URL(string: $0)! }
    }
}
