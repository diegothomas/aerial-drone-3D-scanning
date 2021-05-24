//
//  LogCenter.swift
//  dscan
//
//  Created by zhang on 2021/03/18.
//

import UIKit

protocol LogCenterListener {
    func logCenterContentDidChange()
}

open class LogCenterService: NSObject {

    var printLogWhenAdd = true
    var logs = [LogEntry]()
    var listeners = NSMutableArray()
    var listenersLock = NSLock()
    var logLock = NSLock()
    
    var timeStampFormatter : DateFormatter = {
        var timeStampFormatter = DateFormatter()
        
        timeStampFormatter.dateStyle = .medium
        timeStampFormatter.timeStyle = .medium
        timeStampFormatter.locale = NSLocale.current
        
        return timeStampFormatter
    }()
    
    var diskLogFileDirectory : String = {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        let logDirectory = "\(documentsDirectory)/DebugLogs"
        let fileManager = FileManager.default
        var isDirectory = ObjCBool(false)

        let fileExists = fileManager.fileExists(atPath: logDirectory, isDirectory: &isDirectory)
        
        if fileExists == false || isDirectory.boolValue == false {
            
            do {
                try fileManager.createDirectory(atPath: logDirectory, withIntermediateDirectories: true, attributes: nil);

                var resourceValues = URLResourceValues()
                resourceValues.isExcludedFromBackup = true
                let fileURL = URL(fileURLWithPath: logDirectory)
//                try fileURL.setResourceValues(resourceValues)
            } catch {
                NSLog("Error creating logDirectory: \(logDirectory)")
            }
        }
        
        return logDirectory
    }()
    
    var diskLogFileName : String = {
        let logFileFormatter = DateFormatter()
        logFileFormatter.dateFormat = "yyy-MM-dd_HH:mm:ssZ"

        let uniqueName = "logFile_\(logFileFormatter.string(from: Date()))"
        return uniqueName
    }()
    
    var diskLogFilePath : String {
        get {
            return "\(self.diskLogFileDirectory)/\(self.diskLogFileName)"
        }
    }
    
    var diskLogSaveTimer : Timer!
    
    static let `default` : LogCenterService = {
        let defaultInstance = LogCenterService()
        
        return defaultInstance
    }()
    
    override init() {
        super.init()

        if #available(iOS 10.0, *) {
            self.diskLogSaveTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [unowned self] (timer) in
                self.saveLogToDisk()
            }
        } else {
            self.diskLogSaveTimer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(saveLog), userInfo: nil, repeats: true)
        }
    }
    
    @objc func saveLog() {
        self.saveLogToDisk()
    }
    
    func saveLogToDisk() {
        
    }
    
    func add(_ logEntry: String) {
        let newEntry = LogEntry()
        newEntry.message = logEntry
        
        if self.printLogWhenAdd {
            NSLog(logEntry)
        }
        
        self.logLock.lock()
        self.logs.append(newEntry)
        self.logLock.unlock()
        
        self.notifyListeners()
    }
    
    func fullLog() -> String {
        if self.logs.count == 0 {
            return ""
        }
        var fullLog = ""
        
        self.logLock.lock()
        for index in 0..<self.logs.count {
            let logEntry = self.logs[index]
            let timeStamp = self.timeStampFormatter.string(from: logEntry.timestamp)
            fullLog.append("\(timeStamp) - \(logEntry.message)\n")
        }
        self.logLock.unlock()
        
        return fullLog
    }
    
    // MARK: - Log listeners
    
    func add(listener: LogCenterListener) {
        self.listenersLock.lock()
        self.listeners.add(listener)
        self.listenersLock.unlock()
    }
    
    func remove(listener: LogCenterListener) {
        self.listenersLock.lock()
        self.listeners.remove(listener)
        self.listenersLock.unlock()
    }
    
    func notifyListeners() {
        for listener in self.listeners as NSArray as! [LogCenterListener] {
            listener.logCenterContentDidChange()
        }
    }
}
