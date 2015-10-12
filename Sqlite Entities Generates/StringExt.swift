//
//  StringExt.swift
//  PMS
//
//  Created by Nguyen Thanh Hung on 8/11/15.
//  Copyright (c) 2015 Nguyen Thanh Hung. All rights reserved.
//

import Cocoa

extension Character {
    func isEmoji() -> Bool {
        return Character(UnicodeScalar(0x1d000)) <= self && self <= Character(UnicodeScalar(0x1f77f))
            || Character(UnicodeScalar(0x2100)) <= self && self <= Character(UnicodeScalar(0x26ff))
    }
}

extension String {
    
    // MARK: - Localized
    var localized : String {
        return NSLocalizedString(self, tableName: nil, bundle: NSBundle.mainBundle(), value: "", comment: "");
    }
    
    static func localized(key : String) -> String {
        return key.localized
    }
    
    // MARK: - Validate String
    // MARK: - trimString
    func trimString() -> String {
        return self.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    }
    // MARK: - isEmptyString
    func isEmptyString() -> Bool{
        if self.trimString().isEmpty {
            return true
        }
        return false
    }
    
    func stringByRemovingEmoji() -> String {
//        return String(filter(self, {(c: Character) in !c.isEmoji()}))
        
        let nStr = String(self.characters.filter { (char: Character) -> Bool in
                !char.isEmoji()
            })
        
        return nStr
    }
    
    
    // MARK: - String path component helper
    var lastPathComponent: String {
        
        get {
            return (self as NSString).lastPathComponent
        }
    }
    var pathExtension: String {
        
        get {
            
            return (self as NSString).pathExtension
        }
    }
    var stringByDeletingLastPathComponent: String {
        
        get {
            
            return (self as NSString).stringByDeletingLastPathComponent
        }
    }
    var stringByDeletingPathExtension: String {
        
        get {
            
            return (self as NSString).stringByDeletingPathExtension
        }
    }
    var pathComponents: [String] {
        
        get {
            
            return (self as NSString).pathComponents
        }
    }
    
    func stringByAppendingPathComponent(path: String) -> String {
        
        let nsSt = self as NSString
        
        return nsSt.stringByAppendingPathComponent(path)
    }
    
    func stringByAppendingPathExtension(ext: String) -> String? {
        
        let nsSt = self as NSString
        
        return nsSt.stringByAppendingPathExtension(ext)
    }
}
