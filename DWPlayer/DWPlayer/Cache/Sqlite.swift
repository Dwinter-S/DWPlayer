//
//  Sqlite.swift
//  DWPlayer
//
//  Created by dwinters on 2023/4/25.
//

import Foundation
import SQLite3

enum SQLiteError: Error {
    case OpenDatabase(message: String)
    case Prepare(message: String)
    case Step(message: String)
    case Bind(message: String)
}

class SQLiteDatabase {
    private let dbPointer: OpaquePointer?
    private init(dbPointer: OpaquePointer?) {
        self.dbPointer = dbPointer
    }
    static func open(path: String) throws -> SQLiteDatabase {
        var db: OpaquePointer?
        let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX | SQLITE_OPEN_URI
        if sqlite3_open_v2(path, &db, flags, nil) == SQLITE_OK {
            return SQLiteDatabase(dbPointer: db)
        } else {
            defer {
                if db != nil {
                    sqlite3_close(db)
                }
            }
            if let errorPointer = sqlite3_errmsg(db) {
                let message = String(cString: errorPointer)
                throw SQLiteError.OpenDatabase(message: message)
            } else {
                throw SQLiteError
                    .OpenDatabase(message: "No error message provided from sqlite.")
            }
        }
    }
    
    fileprivate var errorMessage: String {
        if let errorPointer = sqlite3_errmsg(dbPointer) {
            let errorMessage = String(cString: errorPointer)
            return errorMessage
        } else {
            return "No error message provided from sqlite."
        }
    }
    
    deinit {
        sqlite3_close(dbPointer)
    }
}

extension SQLiteDatabase {
    func prepareStatement(sql: String) throws -> OpaquePointer? {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(dbPointer, sql, -1, &statement, nil)
                == SQLITE_OK else {
            throw SQLiteError.Prepare(message: errorMessage)
        }
        return statement
    }
}

extension SQLiteDatabase {
    func createTable(table: SQLTable.Type) throws {
        // 1
        let createTableStatement = try prepareStatement(sql: table.createStatement)
        // 2
        defer {
            sqlite3_finalize(createTableStatement)
        }
        // 3
        guard sqlite3_step(createTableStatement) == SQLITE_DONE else {
            throw SQLiteError.Step(message: errorMessage)
        }
        print("\(table) table created.")
    }
}

extension SQLiteDatabase {
    func insertCachedFileInfo(info: CachedFileInfomation) throws {
        guard let cacheInfoJson = info.toJson() else { return }
        let insertSql = "INSERT OR REPLACE INTO CachedFileInfomation (URL, CacheInfo) VALUES (?, ?);"
        let insertStatement = try prepareStatement(sql: insertSql)
        defer {
            sqlite3_finalize(insertStatement)
        }
        let url = info.urlMd5 as NSString
        let cacheInfo = cacheInfoJson as NSString
        guard
            sqlite3_bind_text(insertStatement, 1, url.utf8String, -1, nil)
                == SQLITE_OK &&
                sqlite3_bind_text(insertStatement, 2, cacheInfo.utf8String, -1, nil)
                == SQLITE_OK
        else {
            throw SQLiteError.Bind(message: errorMessage)
        }
        guard sqlite3_step(insertStatement) == SQLITE_DONE else {
            throw SQLiteError.Step(message: errorMessage)
        }
        print("Successfully inserted row.")
    }
}

extension SQLiteDatabase {
    func cachedFileInfomation(url: String) -> CachedFileInfomation? {
        let querySql = "SELECT * FROM CachedFileInfomation WHERE URL = ?;"
        guard let queryStatement = try? prepareStatement(sql: querySql) else {
            return nil
        }
        defer {
            sqlite3_finalize(queryStatement)
        }
        guard sqlite3_bind_text(queryStatement, 1, (url as NSString).utf8String, -1, nil)
                == SQLITE_OK else {
            return nil
        }
        guard sqlite3_step(queryStatement) == SQLITE_ROW else {
            return nil
        }
        guard let queryResultCol1 = sqlite3_column_text(queryStatement, 1) else {
            print("Query result is nil.")
            return nil
        }
        let cacheInfo = String(cString: queryResultCol1)
        if let data = cacheInfo.data(using: .utf8) {
            do {
                let cac = try JSONDecoder().decode(CachedFileInfomation.self, from: data)
                return cac
            } catch {
                return nil
            }
        } else {
            return nil
        }
    }
    
    func deleteCachedFileInfomation(url: String) throws {
        let deleteSql = "DELETE FROM CachedFileInfomation WHERE URL = ?;"
        let deleteStatement = try prepareStatement(sql: deleteSql)
        defer {
            sqlite3_finalize(deleteStatement)
        }
        guard sqlite3_bind_text(deleteStatement, 1, (url as NSString).utf8String, -1, nil)
                == SQLITE_OK else {
            throw SQLiteError.Bind(message: errorMessage)
        }
        guard sqlite3_step(deleteStatement) == SQLITE_DONE else {
            throw SQLiteError.Step(message: errorMessage)
        }
        print("Successfully delete row url:\(url).")
    }
    
    func deleteAllCachedFileInfomation() throws {
        let deleteSql = "DELETE FROM CachedFileInfomation;"
        let deleteStatement = try prepareStatement(sql: deleteSql)
        defer {
            sqlite3_finalize(deleteStatement)
        }
        guard sqlite3_step(deleteStatement) == SQLITE_DONE else {
            throw SQLiteError.Step(message: errorMessage)
        }
        print("Successfully delete all CachedFileInfomation.")
    }
}

protocol SQLTable {
    static var createStatement: String { get }
}
