//
//  DatabaseService.swift
//  myollama3
//
//  Created by BillyPark on 5/9/25.
//

import Foundation
import SQLite3


class DatabaseService {
    private var db: OpaquePointer?
    private let dbPath: String
    
    enum DatabaseError: Error {
        case connectionFailed
        case prepareFailed(String)
        case stepFailed(String)
        case queryFailed(String)
        case insertFailed(String)
        case dataNotFound
    }
        
    init() {

        let fileURL = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("ollama_chat.sqlite")
        
        self.dbPath = fileURL.path
        
        if openDatabase() {
            createQuestionsTable()
        }
    }
    
    private func openDatabase() -> Bool {
        if sqlite3_open(dbPath, &db) == SQLITE_OK {
            print("Database connection successful at: \(dbPath)")
            return true
        } else {
            print("Database connection failed")
            return false
        }
    }
    
    private func createQuestionsTable() {
        let createTableString = """
        CREATE TABLE IF NOT EXISTS questions(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          groupid TEXT NOT NULL,
          instruction TEXT,
          question TEXT,
          answer TEXT,
          image TEXT,
          created TEXT,
          engine TEXT,
          baseurl TEXT
        );
        """
        
        var createTableStatement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(createTableStatement) == SQLITE_DONE {
                print("questions table created or already exists")
            } else {
                print("Failed to create questions table")
            }
        } else {
            print("CREATE TABLE statement could not be prepared")
        }
        
        sqlite3_finalize(createTableStatement)
    }
    
    func saveQuestion(groupId: String, instruction: String?, question: String, answer: String, image: String? = nil, engine: String, baseUrl: String? = nil) throws {
        let insertStatementString = """
        INSERT INTO questions (groupid, instruction, question, answer, image, created, engine, baseurl)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?);
        """
        
        var insertStatement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {

            let dateFormatter = ISO8601DateFormatter()
            let currentDate = dateFormatter.string(from: Date())
            
            sqlite3_bind_text(insertStatement, 1, (groupId as NSString).utf8String, -1, nil)
            
            if let instruction = instruction {
                sqlite3_bind_text(insertStatement, 2, (instruction as NSString).utf8String, -1, nil)
            } else {
                sqlite3_bind_null(insertStatement, 2)
            }
            
            sqlite3_bind_text(insertStatement, 3, (question as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 4, (answer as NSString).utf8String, -1, nil)
            
            if let image = image {
                sqlite3_bind_text(insertStatement, 5, (image as NSString).utf8String, -1, nil)
            } else {
                sqlite3_bind_null(insertStatement, 5)
            }
            
            sqlite3_bind_text(insertStatement, 6, (currentDate as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 7, (engine as NSString).utf8String, -1, nil)
            
            if let baseUrl = baseUrl {
                sqlite3_bind_text(insertStatement, 8, (baseUrl as NSString).utf8String, -1, nil)
            } else {
                sqlite3_bind_null(insertStatement, 8)
            }
            
            if sqlite3_step(insertStatement) == SQLITE_DONE {
                print("Successfully inserted row")
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                throw DatabaseError.insertFailed(errorMessage)
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.prepareFailed(errorMessage)
        }
        
        sqlite3_finalize(insertStatement)
    }
    
    func getQuestionsForGroup(groupId: String) throws -> [(question: String, answer: String, created: String, engine: String?, baseUrl: String?, image: String?)] {
        let queryStatementString = """
        SELECT question, answer, created, engine, baseurl, image FROM questions 
        WHERE groupid = ? 
        ORDER BY created ASC;
        """
        
        var queryStatement: OpaquePointer?
        var results: [(question: String, answer: String, created: String, engine: String?, baseUrl: String?, image: String?)] = []
        
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(queryStatement, 1, (groupId as NSString).utf8String, -1, nil)
            
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let question = String(cString: sqlite3_column_text(queryStatement, 0))
                let answer = String(cString: sqlite3_column_text(queryStatement, 1))
                let created = String(cString: sqlite3_column_text(queryStatement, 2))
                
                var engine: String? = nil
                var baseUrl: String? = nil
                var imageBase64: String? = nil
                
                if sqlite3_column_type(queryStatement, 3) != SQLITE_NULL {
                    engine = String(cString: sqlite3_column_text(queryStatement, 3))
                }
                
                if sqlite3_column_type(queryStatement, 4) != SQLITE_NULL {
                    baseUrl = String(cString: sqlite3_column_text(queryStatement, 4))
                }
                
                if sqlite3_column_type(queryStatement, 5) != SQLITE_NULL {
                    imageBase64 = String(cString: sqlite3_column_text(queryStatement, 5))
                }
                
                results.append((question: question, answer: answer, created: created, engine: engine, baseUrl: baseUrl, image: imageBase64))
            }
            
            if results.isEmpty {
                throw DatabaseError.dataNotFound
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed(errorMessage)
        }
        
        sqlite3_finalize(queryStatement)
        return results
    }
    
    func getAllGroups() throws -> [(groupId: String, lastCreated: String, baseUrl: String?)] {
        let queryStatementString = """
        SELECT groupid, MAX(created) as last_created, baseurl FROM questions 
        GROUP BY groupid 
        ORDER BY last_created DESC;
        """
        
        var queryStatement: OpaquePointer?
        var results: [(groupId: String, lastCreated: String, baseUrl: String?)] = []
        
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let groupId = String(cString: sqlite3_column_text(queryStatement, 0))
                let lastCreated = String(cString: sqlite3_column_text(queryStatement, 1))
                
                var baseUrl: String? = nil
                if sqlite3_column_type(queryStatement, 2) != SQLITE_NULL {
                    baseUrl = String(cString: sqlite3_column_text(queryStatement, 2))
                }
                
                results.append((groupId: groupId, lastCreated: lastCreated, baseUrl: baseUrl))
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed(errorMessage)
        }
        
        sqlite3_finalize(queryStatement)
        return results
    }
    
    func deleteGroup(groupId: String) throws {
        let deleteStatementString = "DELETE FROM questions WHERE groupid = ?;"
        
        var deleteStatement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, deleteStatementString, -1, &deleteStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(deleteStatement, 1, (groupId as NSString).utf8String, -1, nil)
            
            if sqlite3_step(deleteStatement) == SQLITE_DONE {
                print("Successfully deleted group")
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                throw DatabaseError.queryFailed(errorMessage)
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.prepareFailed(errorMessage)
        }
        
        sqlite3_finalize(deleteStatement)
    }
    
    func deleteQuestion(groupId: String, created: String) throws {
        let deleteStatementString = "DELETE FROM questions WHERE groupid = ? AND created = ?;"
        
        var deleteStatement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, deleteStatementString, -1, &deleteStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(deleteStatement, 1, (groupId as NSString).utf8String, -1, nil)
            sqlite3_bind_text(deleteStatement, 2, (created as NSString).utf8String, -1, nil)
            
            if sqlite3_step(deleteStatement) == SQLITE_DONE {
                print("Successfully deleted question")
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                throw DatabaseError.queryFailed(errorMessage)
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.prepareFailed(errorMessage)
        }
        
        sqlite3_finalize(deleteStatement)
    }
    
    func deleteAllData() throws {
        let deleteStatementString = "DELETE FROM questions;"
        
        var deleteStatement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, deleteStatementString, -1, &deleteStatement, nil) == SQLITE_OK {
            if sqlite3_step(deleteStatement) == SQLITE_DONE {
                print("Successfully deleted all data")
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                throw DatabaseError.queryFailed(errorMessage)
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.prepareFailed(errorMessage)
        }
        
        sqlite3_finalize(deleteStatement)
    }
    
    deinit {
        sqlite3_close(db)
    }
} 