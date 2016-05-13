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
    @IBOutlet weak var userNSNumberCheckBok: NSButton!
    
    var dataTypeDict = [String : String]()
    var application: String!
        
    var author: String!
    
    let dateFormat = NSDateFormatter()
    let invalidType = ["alloc", "autorelease", "class", "columns", "conformsToProtocol", "dataSource", "dealloc", "delegate", "delete", "description", "hash", "hashCode", "id", "init", "isAutoIncremented", "isEqual", "isKindOfClass", "isMemberOfClass", "isProxy", "isSaveable", "load", "new", "performSelector", "primaryKey", "release", "respondsToSelector", "retain", "retainCount", "save", "saved", "self", "superclass", "table", "zone", "default", "var", "let", "repeat"]

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
        
        let userDefault = NSUserDefaults.standardUserDefaults()
        if let dbPath = userDefault.stringForKey("dbPath") {
            self.filePathTextField.stringValue = dbPath
        }
        
        if let author = userDefault.stringForKey("author") {
            self.authorTextField.stringValue = author
        }
        
        if let project = userDefault.stringForKey("project") {
            self.projectTextField.stringValue = project
        }
        
        userNSNumberCheckBok.state = userDefault.boolForKey("userNSNumber") ? NSOnState : NSOffState
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func browserAction(sender: AnyObject) {
        
        let fileOpenDialog = NSOpenPanel()
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
        self.author = self.authorTextField.stringValue
        self.application = self.projectTextField.stringValue.trimString()
        
        let userDefault = NSUserDefaults.standardUserDefaults()
        userDefault.setObject(self.filePathTextField.stringValue, forKey: "dbPath")
        userDefault.setObject(self.author, forKey: "author")
        userDefault.setObject(self.application, forKey: "project")
        userDefault.setBool(self.userNSNumberCheckBok.state == NSOnState, forKey: "userNSNumber")
        userDefault.synchronize()
        
        var applicationShortName = ""
        self.application.componentsSeparatedByString(" ").forEach { (str) -> () in
            if !str.isEmptyString() {
                applicationShortName.append(str.uppercaseString.characters.first!)
            }
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            
            let db = FMDatabase(path: self.filePathTextField.stringValue)
            if db.open() {
                var dataSource: NSString = self.filePathTextField.stringValue as NSString
                dataSource = dataSource.lastPathComponent
                dataSource = dataSource.stringByDeletingPathExtension
                
                self.dataSource = dataSource as String
                let resultTable = db.executeQuery("SELECT [name] FROM [sqlite_master] WHERE [type] = 'table' AND [name] NOT IN ('sqlite_sequence');", withArgumentsInArray: nil)
                
                let fileManager = NSFileManager.defaultManager()
                let dirPath = fileManager.currentDirectoryPath + "/Entities"
                
                if !fileManager.fileExistsAtPath(dirPath) {
                    do {
                        try fileManager.createDirectoryAtPath(dirPath, withIntermediateDirectories: true, attributes: nil)
                    } catch _ {
                    }
                }
                
                let parserObjectString = NSMutableString(string: "")
                let parserObjectFromDBString = NSMutableString(string: "")
                
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
                parserObjectFromDBString.appendString("\n\tfunc getClassType(tableName: String) -> PMSBaseEntity.Type {\n")
                
                parserObjectString.appendString("\n\t\tvar arr: [PMSBaseEntity]!\n")
                parserObjectFromDBString.appendString("\n\t\tlet type: PMSBaseEntity.Type\n")
                
                parserObjectString.appendString("\n\t\tswitch tableName {\n")
                parserObjectFromDBString.appendString("\n\t\tswitch tableName {\n")
                
                
                while resultTable.next() {
                    let tableName = resultTable.stringForColumn("name")
                    var fileName = applicationShortName + self.convertToNiceName(tableName)
                    let className = fileName
                    fileName += ".swift"
                    
                    parserObjectString.appendString("\t\tcase \(className).table():\n\t\t\tarr = Mapper<\(className)>().mapArray(rows)\n\n")
                    parserObjectFromDBString.appendString("\t\tcase \(className).table():\n\t\t\ttype = \(className).self\n\n")
                    
                    
                    self.addStringToLog("Creating table \(tableName) className: \(className)")
                    
                    let content : NSMutableString = NSMutableString()
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
                        let name = columnResultSet.stringForColumn("name")
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
                    
                    let parserObjectCopyString = NSMutableString(string: "")
                    parserObjectCopyString.appendString("\n\toverride func copyWithZone(zone: NSZone) -> AnyObject  {\n")
                    parserObjectCopyString.appendString("\n\t\tlet copyObject = \(className)()")
                    
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
                        
                        // Copying
                        parserObjectCopyString.appendString("\n\t\t\tcopyObject[\(className).k\(self.convertToNiceName(columnRealNames[i]))] = self[\(className).k\(self.convertToNiceName(columnRealNames[i]))]")
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
                    
                    updateStr.removeRange(updateStr.endIndex.predecessor().advancedBy(-3)...updateStr.endIndex.predecessor())
                    
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
                    content.appendString("\t\tlet sqlCommand = \"\(updateStr)\"\n\n")
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
                    content.appendString("\t\tlet debugStr = NSMutableString(string: \"================== \(className) ===================\")")
                    
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
//                    content.appendString("\trequired init?(_ map: Map) {\n\t\tsuper.init(map)\n\t}\n\n")
                    
                    content.appendString("\toverride func mapping(map: Map) {\n\n")
                    content.appendString("\t\tsuper.mapping(map)\n")
                    
                    if columnTypes.filter({
                        $0 == "NSDate"
                    }).count != 0 {
                        content.appendString("\t\tvar tempDateValue: NSDate!\n")
                    }
                    
                    for i in 0..<columnRealNames.count {
                        let realName = columnRealNames[i]
                        
                        if columnTypes[i] == "String" {  // This is hardcode because server sometime return NSNumber for String column
                            
                            content.appendString("\t\t\(columnNames[i]) = tryParserText(map[\(className).k\(self.convertToNiceName(realName))].value()) // This is hardcode because server sometime return NSNumber for String column\n")
                            
                        } else if columnTypes[i] == "NSDate" {
                            content.appendString("\t\ttempDateValue = tryParserDate(map[\(className).k\(self.convertToNiceName(realName))].value())\n")
                            
                            if columnNullable[i] {
                                content.appendString("\t\t\(columnNames[i]) = tempDateValue\n")
                            } else {
                                content.appendString("\t\tif tempDateValue != nil {\n")
                                content.appendString("\t\t\t\(columnNames[i]) = tempDateValue\n")
                                content.appendString("\t\t} else {\n\t\t\t\(columnNames[i]) = NSDate()\n\t\t}\n")
                            }
                            
                        } else {
                            content.appendString("\t\t\(columnNames[i]) <- map[\(className).k\(self.convertToNiceName(realName))]\n")
                        }
                        
                    }
                    content.appendString("\t}\n")
                    
                    parserObjectCopyString.appendString("\n\t}\n")
                    content.appendString(parserObjectCopyString as String)
                    
                    // Close of class
                    content.appendString("}")
                    
                    do {
                        try content.writeToFile(dirPath + "/\(fileName)", atomically: true, encoding: NSUTF8StringEncoding)
                    } catch _ {
                    }
                    
                }
                
                parserObjectString.appendString("\t\tdefault:\n\t\t\tprint(\"Don't have table: \\(tableName)\")\n\t\t}\n\t\treturn arr\n\t}")
                parserObjectFromDBString.appendString("\t\tdefault:\n\t\t\ttype = PMSBaseEntity.self\n\t\t}\n\t\treturn type\n\t}\n}")
                
                parserObjectString.appendString(parserObjectFromDBString as String)
                
                do {
                    try parserObjectString.writeToFile(dirPath + "/\(applicationShortName)ParserTableDataHelper.swift", atomically: true, encoding: NSUTF8StringEncoding)
                } catch _ {
                }
                
                
                let baseTemplate: String = try! String(contentsOfFile: NSBundle.mainBundle().pathForResource("BaseEntity.swift", ofType: "template")!, encoding: NSUTF8StringEncoding)
                do {
                    try baseTemplate.writeToFile(dirPath + "/PMSBaseEntity.swift", atomically: true, encoding: NSUTF8StringEncoding)
                } catch _ {
                }
                
                resultTable.close()
                startButton.enabled = true
            }
        })
    }
    
    @IBAction func clearAction(sender: AnyObject) {
        self.logTextView.string = ""
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
        let fixDataType = range == nil ? dataType : dataType.substringToIndex(range!.endIndex.predecessor())
        var mappedDataType = self.dataTypeDict[fixDataType.uppercaseString]
        
        if userNSNumberCheckBok.state == NSOnState {
            if mappedDataType == "NSDecimalNumber" {
                mappedDataType = "NSNumber"
            }
        }
        
        if mappedDataType == nil {
            mappedDataType = "AnyObject"
        }
        
        return mappedDataType!
    }
    
    
    
    
}

