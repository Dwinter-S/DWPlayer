//
//  TSqlite.swift
//  DWPlayer
//
//  Created by dwinters on 2023/4/26.
//

import Foundation
import SQLite3

/// SQLite3
class SQLite3 {

    /// Connection
    private var db: OpaquePointer?

    /// Statement
    private var statement: OpaquePointer?

    /// データベースを開く
    /// - Parameter path: ファイルパス
    /// - Returns: 実行結果
    @discardableResult
    func open(path: String) -> Int {
        let ret = sqlite3_open_v2(path, &self.db, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX, nil)

        if ret != SQLITE_OK {
            print("error sqlite3_open_v2: code=\(ret)")
        }

        return Int(ret)
    }

    /// ステートメントを生成しないでSQLを実行
    /// - Parameter sql: SQL
    /// - Returns: 実行結果
    @discardableResult
    func exec(_ sql: String) -> Int {
        let ret = sqlite3_exec(self.db, sql, nil, nil, nil)

        if ret != SQLITE_OK {
            let msg = String(cString: sqlite3_errmsg(self.db)!)
            print("error sqlite3_exec: code=\(ret), errmsg=\(msg)")
        }

        return Int(ret)
    }

    /// ステートメントの生成
    /// - Parameter sql: SQL
    /// - Returns: 実行結果
    @discardableResult
    func prepare(_ sql: String) -> Int {
        let ret = sqlite3_prepare_v2(self.db, sql, -1, &self.statement, nil)

        if ret != SQLITE_OK {
            let msg = String(cString: sqlite3_errmsg(self.db)!)
            print("error sqlite3_prepare_v2: code=\(ret), errmsg=\(msg)")
        }

        return Int(ret)
    }


    /// 作成されたステートメントにInt型パラメーターを生成
    /// - Parameters:
    ///   - index: インデックス
    ///   - value: 値
    /// - Returns: 実行結果
    @discardableResult
    func bindInt(index: Int, value: Int) -> Int {
        let ret = sqlite3_bind_int(self.statement, Int32(index), Int32(value))

        if ret != SQLITE_OK {
            let msg = String(cString: sqlite3_errmsg(self.db)!)
            print("error sqlite3_bind_int: code=\(ret), errmsg=\(msg)")
        }

        return Int(ret)
    }

    /// 作成されたステートメントにString型(UTF-8)パラメーターを生成
    /// - Parameters:
    ///   - index: インデックス
    ///   - value: 値
    /// - Returns: 実行結果
    @discardableResult
    func bindText(index: Int, value: String) -> Int {
        let ret = sqlite3_bind_text(self.statement, Int32(index), (value as NSString).utf8String, -1, nil)

        if ret != SQLITE_OK {
            let msg = String(cString: sqlite3_errmsg(self.db)!)
            print("error sqlite3_bind_text: code=\(ret), errmsg=\(msg)")
        }

        return Int(ret)
    }

    /// ステートメントの実行（SELECTの場合は行の取得）
    /// - Returns: 実行結果
    @discardableResult
    func step() -> Int {
        let ret = sqlite3_step(self.statement)

        if ret != SQLITE_ROW && ret != SQLITE_DONE {
            let msg = String(cString: sqlite3_errmsg(self.db)!)
            print("error sqlite3_step: code=\(ret), errmsg=\(msg)")
        }

        return Int(ret)
    }

    /// ステートメントのリセット
    /// - Returns: 実行結果
    @discardableResult
    func resetStatement() -> Int {
        let ret = sqlite3_reset(self.statement)

        if ret != SQLITE_OK {
            let msg = String(cString: sqlite3_errmsg(self.db)!)
            print("error sqlite3_reset: code=\(ret), errmsg=\(msg)")
        }

        return Int(ret)
    }

    /// ステートメントの破棄
    /// - Returns: 実行結果
    @discardableResult
    func finalizeStatement() -> Int {
        let ret = sqlite3_finalize(self.statement)

        if ret != SQLITE_OK {
            let msg = String(cString: sqlite3_errmsg(self.db)!)
            print("error sqlite3_finalize: code=\(ret), errmsg=\(msg)")
        }

        return Int(ret)
    }

    /// SELECTしたステートメントからInt値を取得
    /// - Parameter index: カラムインデックス(0から)
    /// - Returns: Int値
    func columnInt(index: Int) -> Int {
        return Int(sqlite3_column_int(self.statement, Int32(index)))
    }

    /// SELECTしたステートメントからString値を取得
    /// - Parameter index: カラムインデックス(0から)
    /// - Returns: String値
    func columnText(index: Int) -> String {
        return String(cString: sqlite3_column_text(self.statement, Int32(index)))
    }

    /// データベースを閉じる
    /// - Returns: 実行結果
    @discardableResult
    func close() -> Int {
        let ret = sqlite3_close_v2(self.db)

        if ret != SQLITE_OK {
            let msg = String(cString: sqlite3_errmsg(self.db)!)
            print("error sqlite3_close_v2: code=\(ret), errmsg=\(msg)")
        }

        return Int(ret)
    }

    /// テーブル存在チェック
    /// - Parameters:
    ///   - sqlite3: SQLite3
    ///   - table: テーブル名
    func existsTable(_ tableName: String) -> Bool {
        self.prepare("SELECT COUNT(*) AS CNT FROM sqlite_master WHERE type = ? and name = ?")
        defer { self.finalizeStatement() }

        self.bindText(index: 1, value: "table")
        self.bindText(index: 2, value: tableName)

        if self.step() == SQLITE_ROW {
            if self.columnInt(index: 0) > 0 {
                return true
            }
        }

        return false
    }
}
