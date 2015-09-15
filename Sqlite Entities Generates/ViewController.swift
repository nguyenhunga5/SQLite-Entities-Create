//
//  ViewController.swift
//  Sqlite Entities Generates
//
//  Created by Nguyen Thanh Hung on 8/24/15.
//  Copyright (c) 2015 Nguyen Thanh Hung. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    static let dataType = "BIGINT:NSNumber|BIT:NSNumber|BOOL:NSNumber|BOOLEAN:NSNumber|INT:NSNumber|INT2:NSNumber|INT8:NSNumber|INTEGER:NSNumber|MEDIUMINT:NSNumber|SMALLINT:NSNumber|TINYINT:NSNumber|DECIMAL:NSDecimalNumber|DOUBLE:NSDecimalNumber|DOUBLE PRECISION:NSDecimalNumber|FLOAT:NSDecimalNumber|NUMERIC:NSDecimalNumber|REAL:NSDecimalNumber|CHAR:String|CHARACTER:String|CLOB:String|NATIONAL VARYING CHARACTER:String|NATIVE CHARACTER:String|NCHAR:String|NVARCHAR:String|TEXT:String|VARCHAR:String|VARIANT:String|VARYING CHARACTER:String|BINARY:NSData|BLOB:NSData|VARBINARY:NSData|NULL:NSNull|DATE:NSDate|DATETIME:NSDate|TIME:NSDate|TIMESTAMP:NSDate|MEDIUMTEXT:String".componentsSeparatedByString("|")
    
    
    @IBOutlet weak var authorTextField: NSTextField!
    @IBOutlet weak var projectTextField: NSTextField!
    
    var dataTypeDict = [String : String]()
    var application: String {
        return projectTextField.stringValue
    }
        
    var author: String {
        return authorTextField.stringValue
    }
    
    let dateFormat = NSDateFormatter()
    let invalidType = ["alloc", "autorelease", "class", "columns", "conformsToProtocol", "dataSource", "dealloc", "delegate", "delete", "description", "hash", "hashCode", "id", "init", "isAutoIncremented", "isEqual", "isKindOfClass", "isMemberOfClass", "isProxy", "isSaveable", "load", "new", "performSelector", "primaryKey", "release", "respondsToSelector", "retain", "retainCount", "save", "saved", "self", "superclass", "table", "zone", "default", "var", "let"]

    var dataSource : String!
    
    
    var createDate : String {
        dateFormat.dateFormat = "MM/dd/yyyy"
        return dateFormat.stringFromDate(NSDate())
    }
    
    var createYear : String {
        dateFormat.dateFormat = "yyyy"
        return dateFormat.stringFromDate(NSDate())
    }
    
    @IBOutlet var logTextView: NSTextView!
    @IBOutlet weak var filePathTextField: NSTextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        logTextView.string = ""
        var dataType : [String]
        for str in ViewController.dataType {
            dataType = str.componentsSeparatedByString(":")
            dataTypeDict[dataType[0]] = dataType[1]
        }
        
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func browserAction(sender: AnyObject) {
        
        var fileOpenDialog = NSOpenPanel()
        fileOpenDialog.allowsMultipleSelection = false
        fileOpenDialog.canChooseDirectories = false
        fileOpenDialog.canChooseFiles = true
        
        if fileOpenDialog.runModal() == NSFileHandlingPanelOKButton {
            filePathTextField.stringValue = fileOpenDialog.URL!.relativePath!
        }
    }
    
    func addStringToLog(string : String) {
        if NSThread.currentThread().isMainThread {
            logTextView.string = logTextView.string! + "\n" + string
        } else {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.logTextView.string = self.logTextView.string! + "\n" + string
            })
        }
    }
    
    @IBAction func startAction(sender: AnyObject) {
        let startButton = sender as! NSButton
        startButton.enabled = false
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            
            var db = FMDatabase(path: self.filePathTextField.stringValue)
            if db.open() {
                self.dataSource = self.filePathTextField.stringValue.lastPathComponent.stringByDeletingPathExtension
                let resultTable = db.executeQuery("SELECT [name] FROM [sqlite_master] WHERE [type] = 'table' AND [name] NOT IN ('sqlite_sequence');", withArgumentsInArray: nil)
                
                let fileManager = NSFileManager.defaultManager()
                let dirPath = fileManager.currentDirectoryPath + "/Entities"
                
                if !fileManager.fileExistsAtPath(dirPath) {
                    fileManager.createDirectoryAtPath(dirPath, withIntermediateDirectories: true, attributes: nil, error: nil)
                }
                
                let parserObjectString = NSMutableString(string: "")
                
                parserObjectString.appendString("//\n")
                parserObjectString.appendString("// PMSParserTableDataHelper\n")
                parserObjectString.appendString("// \(self.application)\n")
                parserObjectString.appendString("//\n")
                parserObjectString.appendString("// Created by \(self.author) on \(self.createDate)\n")
                parserObjectString.appendString("// SQLite Entities Create: NguyenHungA5 \n")
                parserObjectString.appendString("// Copyright \(self.createYear) \(self.author). All rights reserved.\n")
                
                parserObjectString.appendString("//\n")
                
                // Import
                parserObjectString.appendString("import UIKit\n")
                parserObjectString.appendString("import ObjectMapper\n")
                parserObjectString.appendString("import Alamofire\n")
                parserObjectString.appendString("import AlamofireObjectMapper\n\n")
                
                parserObjectString.appendString("class PMSParserTableDataHelper : PMSBaseEntity {\n")
                
                parserObjectString.appendString("\tfunc parserDataToTableArray(tableName: String, rows: [NSDictionary]) -> [PMSBaseEntity] {\n")
                parserObjectString.appendString("\n\t\tvar arr: [PMSBaseEntity]!\n")
                parserObjectString.appendString("\n\t\tswitch tableName {\n")
                
                while resultTable.next() {
                    let tableName = resultTable.stringForColumn("name")
                    var fileName = self.application + self.convertToNiceName(tableName)
                    let className = fileName
                    fileName += ".swift"
                    
                    parserObjectString.appendString("\t\tcase \(className).table():\n\t\t\tarr = Mapper<\(className)>().mapArray(rows)\n\n")
                    
                    
                    self.addStringToLog("Creating table \(tableName) className: \(className)")
                    
                    var content : NSMutableString = NSMutableString()
                    content.appendString("//\n")
                    content.appendString("// \(fileName)\n")
                    content.appendString("// \(self.application)\n")
                    content.appendString("//\n")
                    content.appendString("// Created by \(self.author) on \(self.createDate)\n")
                    content.appendString("// Copyright \(self.createYear) \(self.author). All rights reserved.\n")
                    
                    content.appendString("//\n")
                    
                    // Import
                    content.appendString("import UIKit\n")
                    content.appendString("import ObjectMapper\n")
                    content.appendString("import Alamofire\n")
                    content.appendString("import AlamofireObjectMapper\n\n")
                    
                    // Class Description
                    content.appendString("/*!\n")
                    content.appendString(" @class \(className)\n")
                    content.appendString(" @discussion This class represents a record in the \"\(tableName)\" table.\n")
                    content.appendString(" @updated \(self.createDate)\n")
                    content.appendString(" */\n")
                    
                    content.appendString("class \(className) : PMSBaseEntity {\n")
                    
                    // Query Columns
                    let columnResultSet = db.executeQuery("PRAGMA table_info(`\(tableName)`);", withArgumentsInArray: nil)
                    var haveAUTOINCREMENTED = false
                    var PKCOUNT = 0
                    
                    var insertStr = "INSERT INTO `\(tableName)`("
                    var updateStr = "UPDATE `\(tableName)` SET "
                    var columnNames = [String]()
                    var columnRealNames = [String]()
                    var columnTypes = [String]()
                    var columnNullable = [Bool]()
                    var columnNotNull = [String]()
                    var primaryKey = [String]()
                    var columnDefaultValue = [AnyObject]()
                    
                    while columnResultSet.next() {
                        var name = columnResultSet.stringForColumn("name")
                        columnRealNames.append(name)
                        insertStr += " `\(name)`,"
                        columnNames.append(self.checkInvalidName(name))
                        columnTypes.append(self.mappingData(columnResultSet.stringForColumn("type")))
                        
                        // Check us notnull
                        if columnResultSet.intForColumn("notnull") == 1 {
                            columnNullable.append(false)
                            columnNotNull.append(self.checkInvalidName(name))
                        } else {
                            columnNullable.append(true)
                        }
                        
                        // Default value
                        columnDefaultValue.append(columnResultSet.objectForColumnName("dflt_value"))
                       
                        
                        // Check primary key
                        if columnResultSet.intForColumn("pk") == 1 {
                            primaryKey.append(name)
                        }
                    }
                    
                    columnResultSet.close()
                    
                    insertStr.removeAtIndex(insertStr.endIndex.predecessor())
                    insertStr += ") VALUES("
                    
                    var VALUES=""
                    var UPDATEVALUES=""
                    
                    // Create Key for Class
                    content.appendString("\n\t// MARK: - Define Key\n")
                    for i in 0..<columnRealNames.count {
                        let realName = columnRealNames[i]
                        content.appendString("\tstatic let k\(self.convertToNiceName(realName)) = \"\(realName)\"\n")
                        let checkIsPrimariKey = primaryKey.filter{ $0 == realName }
                        if checkIsPrimariKey.count == 0 {
                            updateStr += " `" + realName + "` = ?,"
                        }
                    }
                    
                    updateStr.removeAtIndex(updateStr.endIndex.predecessor())
                    
                    var subscriptGetStr = "switch key {\n"
                    var subscriptSetStr = "if newValue == nil || newValue.isKindOfClass(NSNull.classForCoder()) {\n\t\t\t\treturn\n\t\t\t}\n\t\t\tswitch key {\n"
                    
                    // Create Properties
                    let numberFormatter = NSNumberFormatter()
                    content.appendString("\n\t// MARK: - Properties\n")
                    for i in 0..<columnNames.count {
                        let name = columnNames[i]
                        let defaultValue = columnDefaultValue[i]
                        var  realDefaultValue: String
                        var numberFromString: NSNumber!
                        
                        if defaultValue.isKindOfClass(NSNull.classForCoder()) {
                            realDefaultValue = "nil"
                        } else {
                            numberFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
                            numberFromString = numberFormatter.numberFromString(defaultValue as! String)
                            if columnTypes[i] == "NSDecimalNumber" {
                                
                                if numberFromString != nil {
                                    realDefaultValue = "NSDecimalNumber(double: \(numberFromString.doubleValue))"
                                } else {
                                    realDefaultValue = "NSDecimalNumber(double: 0.0)"
                                }
                                
                            } else if columnTypes[i] == "NSNumber" {
                                
                                if numberFromString != nil {
                                    realDefaultValue = "NSNumber(integer: \(numberFromString.integerValue))"
                                } else {
                                    realDefaultValue = "NSNumber(integer: 0)"
                                }
                                
                            } else if columnTypes[i] == "NSDate" {
                                if defaultValue.description == "CURRENT_TIMESTAMP" {
                                    realDefaultValue = "NSDate()"
                                } else {
                                    // TODO: Need add format
                                    realDefaultValue = "nil"
                                }
                            } else if columnTypes[i] == "String" {
                                if defaultValue as! String == "NULL" {
                                    realDefaultValue = "nil"
                                } else {
                                    realDefaultValue = "\"\(defaultValue as! String)\""
                                }
                            } else {
                                realDefaultValue = "nil"
                            }
                            
                        }
                        
                        if columnNullable[i] {
                            
                            content.appendString("\tvar \(name): \(columnTypes[i])!")
                            
                            if !defaultValue.isKindOfClass(NSNull.classForCoder()) {
                                content.appendString(" = \(realDefaultValue)")
                            }
                            
                        } else {
                            
                            if realDefaultValue != "nil" {
                                
                                content.appendString("\tlazy var \(name) = \(realDefaultValue)")
                                
                            } else {
                                content.appendString("\tlazy var \(name) = \(columnTypes[i])(")
                                
                                if columnTypes[i] == "NSDecimalNumber" {
                                    content.appendString("double: 0.0")
                                } else if columnTypes[i] == "NSNumber" {
                                    content.appendString("integer: 0")
                                }
                                
                                content.appendString(")")
                            }
                            
                        }
                        
                        content.appendString("\n")
                        let checkIsPrimariKey = primaryKey.filter{ $0 == columnRealNames[i] }
                        if checkIsPrimariKey.count == 0 {
                            UPDATEVALUES += " " + name + ","
                        }
                        
                        insertStr += " ?,"
                        VALUES += " \(name),"
                        
                        // subscript
                        subscriptGetStr += "\n\t\t\tcase \(className).k\(self.convertToNiceName(columnRealNames[i])) :\n\t\t\t\treturn self.\(name)"
                        subscriptSetStr += "\n\t\t\tcase \(className).k\(self.convertToNiceName(columnRealNames[i])) :\n\t\t\t\tself.\(name) = newValue as! \(columnTypes[i])"
                    }
                    
                    subscriptGetStr += "\n\t\t\tdefault:\n\t\t\t\treturn super[key]\n\t\t\t}"
                    subscriptSetStr += "\n\t\t\tdefault:\n\t\t\t\tsuper[key] = newValue\n\t\t\t}"
                    
                    
                    insertStr.removeAtIndex(insertStr.endIndex.predecessor())
                    insertStr += ");"
                    VALUES.removeAtIndex(VALUES.endIndex.predecessor())
                    
                    updateStr += " WHERE "
                    UPDATEVALUES.removeAtIndex(UPDATEVALUES.endIndex.predecessor())
                    
                    // Create datasource method
                    content.appendString("\n\n\toverride class func dataSource() -> String {\n\t\treturn \"\(self.dataSource)\"\n\t}\n")
                    
                    // Create return TableName
                    content.appendString("\n\n\toverride class func table() -> String {\n\t\treturn \"\(tableName)\"\n\t}\n")
                    
                    // Create return Primary Key method
                    content.appendString("\n\n\toverride class func primaryKey() -> [String]? {\n")
                    content.appendString("\t\tvar cols = [String]()\n")
                    for pk in primaryKey {
                        content.appendString("\t\tcols.append(\"\(pk)\")")
                        
                        // For Update
                        updateStr += " `\(pk)` = ? AND"
                        
                        UPDATEVALUES += ", "
                        for i in 0..<columnRealNames.count {
                            if pk == columnRealNames[i] {
                                UPDATEVALUES += columnNames[i]
                                break
                            }
                        }
                    }
                    
                    // Remove AND in last string
                    
                    updateStr.removeRange(advance(updateStr.endIndex.predecessor(), -3)...updateStr.endIndex.predecessor())
                    
                    content.appendString("\n\t\treturn cols\n")
                    content.appendString("\t}\n")
                    
                    var valueArray: [String]
                    // Generates insert, update, delete
                    content.appendString("\n\t// MARK: - Database Support\n")
                    content.appendString("\n\toverride class func getObjects(columns: [String]!, conditions : [PMSQueryCondition]?, orderBy: String? = nil, ascending: Bool = true, db : FMDatabase) ->[PMSBaseEntity]? {\n\t\treturn super.getObjects(columns, conditions: conditions, orderBy: orderBy, ascending: ascending, db: db)\n\t}\n\n")
                    content.appendString("\toverride func insertToDB(db : FMDatabase) -> Bool {")
                    content.appendString("\n")
                    content.appendString("\t\tlet sqlCommand = \"\(insertStr)\"\n\n")
                    content.appendString("\t\tvar args = [AnyObject]()\n")
                    
                    valueArray = VALUES.componentsSeparatedByString(",")
                    var rightNameOfColumn: String
                    for nameOfColumn in valueArray {
                        rightNameOfColumn = nameOfColumn.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                        if columnNotNull.filter({ rightNameOfColumn == $0 }).count > 0 {
                            content.appendString("\t\targs.append(\(rightNameOfColumn))\n")
                        } else {
                            /* content.appendString("\t\tif \(rightNameOfColumn) != nil {\n")
                            content.appendString("\t\t\targs.append(\(rightNameOfColumn))\n")
                            content.appendString("\t\t} else {\n")
                            content.appendString("\t\t\targs.append(NSNull())\n")
                            content.appendString("\t\t}\n") */
                            
                            content.appendString("\t\targs.append(self.checkNil(\(rightNameOfColumn)))\n")
                        }
                    }
                    
                    
                    content.appendString("\t\tlet result = db.executeUpdate(sqlCommand, withArgumentsInArray: args)\n")
                    content.appendString("\t\treturn result\n\t}\n")
                    
                    // Update method
                    content.appendString("\n\toverride func updateToDB(db : FMDatabase) -> Bool {\n")
                    content.appendString("\t\tvar sqlCommand = \"\(updateStr)\"\n\n")
                    content.appendString("\t\tvar args = [AnyObject]()\n")
                    
                    valueArray = UPDATEVALUES.componentsSeparatedByString(",")
                    for nameOfColumn in valueArray {
                        rightNameOfColumn = nameOfColumn.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                        if columnNotNull.filter({ rightNameOfColumn == $0 }).count > 0 {
                            content.appendString("\t\targs.append(\(rightNameOfColumn))\n")
                        } else {
                            /* content.appendString("\t\tif \(rightNameOfColumn) != nil {\n")
                            content.appendString("\t\t\targs.append(\(rightNameOfColumn))\n")
                            content.appendString("\t\t} else {\n")
                            content.appendString("\t\t\targs.append(NSNull())\n")
                            content.appendString("\t\t}\n") */
                            
                            content.appendString("\t\targs.append(self.checkNil(\(rightNameOfColumn)))\n")
                        }
                    }
                    
                    content.appendString("\t\tlet result = db.executeUpdate(sqlCommand, withArgumentsInArray: args)\n")
                    content.appendString("\t\treturn result\n\t}\n")
                    
                    
                    // Debug
                    content.appendString("\n\t// MARK: - Debug\n")
                    content.appendString("\toverride func debugQuickLookObject() -> AnyObject  {\n")
                    content.appendString("\t\tvar debugStr = NSMutableString(string: \"================== \(className) ===================\")")
                    
                    for name in columnNames {
                        content.appendString("\n\t\tdebugStr.appendString(\"\\n\\t\(name) : \\(\(name))\")")
                    }
                    
                    content.appendString("\n\t\t debugStr.appendString(\"\\n======================================\")")
                    
                    content.appendString("\n\t\treturn debugStr\n")
                    content.appendString("\t}\n")
                    
                    
                    // Subscript
                    content.appendString("\n\t// MARK: - Subscript\n")
                    content.appendString("\toverride subscript(key : String) -> AnyObject! {\n\n")
                    content.appendString("\t\tget {\n")
                    content.appendString("\t\t\t\(subscriptGetStr)\n\t\t}\n")
                    content.appendString("\t\tset {\n")
                    content.appendString("\t\t\t\(subscriptSetStr)\n\t\t}\n")
                    content.appendString("\t}\n\n")
                    
                    // Mapping
                    content.appendString("\n\t// MARK: - Mapping\n")
                    content.appendString("\toverride class func newInstance(map: Map) -> Mappable? {\n\n")
                    content.appendString("\t\treturn \(className)()\n")
                    content.appendString("\t}\n")
                    
                    content.appendString("\toverride func mapping(map: Map) {\n\n")
                    content.appendString("\t\tsuper.mapping(map)\n")
//                    content.appendString("\t\tvar tempValue: AnyObject?\n")
                    for i in 0..<columnRealNames.count {
                        let realName = columnRealNames[i]
                        
                        /* if columnNullable[i] { */
                            content.appendString("\t\t\(columnNames[i]) <- map[\(className).k\(self.convertToNiceName(columnRealNames[i]))]\n")
                        /* } else {
                            var stringInitValue = columnTypes[i] + "("
                            if columnTypes[i] == "NSDecimalNumber" {
                                stringInitValue += "double: 0.0"
                            } else if columnTypes[i] == "NSNumber" {
                                stringInitValue += "integer: 0"
                            }
                            
                            stringInitValue += ")"
                            
                            content.appendString("\n\t\ttempValue <- map[\(className).k\(self.convertToNiceName(columnRealNames[i]))]\n")
                            content.appendString("\t\tif tempValue == nil {\n")
                            
                            content.appendString("\t\t\t\(columnNames[i]) = \(stringInitValue)\n")
                            
                            content.appendString("\t\t} else {\n")
                            content.appendString("\t\t\t\(columnNames[i]) = tempValue as! \(columnTypes[i])\n")
                            
                            content.appendString("\t\t}\n\n")
                        } */
                        
                    }
                    content.appendString("\t}\n")
                    
                    
                    // Close of class
                    content.appendString("}")
                    
                    content.writeToFile(dirPath + "/\(fileName)", atomically: true, encoding: NSUTF8StringEncoding, error: nil)
                    
                }
                
                parserObjectString.appendString("\t\tdefault:\n\t\t\tprintln(\"Don't have table: \\(tableName)\")\n\t\t}\n\t\treturn arr\n\t}\n}")
                parserObjectString.writeToFile(dirPath + "/\(self.application)ParserTableDataHelper.swift", atomically: true, encoding: NSUTF8StringEncoding, error: nil)
                
                
                let baseTemplate: String = String(contentsOfFile: NSBundle.mainBundle().pathForResource("BaseEntity.swift", ofType: "template")!, encoding: NSUTF8StringEncoding, error: nil)!
                baseTemplate.writeToFile(dirPath + "/PMSBaseEntity.swift", atomically: true, encoding: NSUTF8StringEncoding, error: nil)
                
                resultTable.close()
                startButton.enabled = true
            }
        })
    }
    
    @IBAction func clearAction(sender: AnyObject) {
        
    }
    
    func checkInvalidName(name : String) -> String {
        var niceName = invalidType.filter{
            $0 == name
        }
        
        if niceName.count == 0 {
            niceName.append(name)
        } else {
            niceName[0] = name.uppercaseString
        }
        
        return niceName[0]
    }
    
    func convertToNiceName(name : String) -> String {
        var niceName = ""
        for subOfName in name.componentsSeparatedByString("_") {
            niceName += subOfName.capitalizedString
        }
        
        return niceName
    }

    func mappingData(dataType : String) -> String {
        
        let range = dataType.rangeOfString("(", options: NSStringCompareOptions.CaseInsensitiveSearch, range: Range<String.Index>(start: dataType.startIndex, end: dataType.endIndex), locale: nil)
        var fixDataType = range == nil ? dataType : dataType.substringToIndex(range!.endIndex.predecessor())
        var mappedDataType = self.dataTypeDict[fixDataType.uppercaseString]
        
        if mappedDataType == nil {
            mappedDataType = "AnyObject"
        }
        
        return mappedDataType!
    }
    
    
    
    
}

