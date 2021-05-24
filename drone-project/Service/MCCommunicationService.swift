//
//  MCCommunicationService.swift
//  drone-project
//
//  Created by zhang on 2021/03/31.
//

import Foundation

protocol MCStreamer {
    func MCStreaming(_ imageData: Data)
}

protocol MCUser {
    func MCConnected()
    func MCDisconnected()
}

enum MCCode : UInt32 {
    case REC_START = 10000
    case REC_STOP = 10001
    case REC_SAVE = 10002
    case STREAM_START = 10003
    case STREAM_STOP = 10004
    case STREAM_SWITCH = 10005
    
    case EXIT = 0
    case OK = 200
    case OK_TO_EXIT = 201
    case BAD_REQUEST = 400
    case INTERNAL_SERVER_ERROR = 500
}

class MCCommunicationService {

    static let shared = MCCommunicationService()
    
    var controlConnected = false
    var streamConnected = false
    var streaming = false
    var recording = false
    var imageData = Data()
    var streamerDelegate : MCStreamer?
    var userDelegate : MCUser?
    private var controlClient = TCPClient(ipAddr: "", port: 0)
    private var streamClient = TCPClient(ipAddr: "", port: 0)
    private let respLen = 4
    private var respBuffer = Data()
    private let imageMetaLen = 4
    private var imageMetaBuffer = Data()
    private var imageLen : UInt32 = 0
    private var imageBuffer = Data()

    private init() {}
    
    func setupControlClient() {
        self.controlClient.onOpenCompleted = {() -> () in
            LogCenterService.default.add("ControlClient: Connected.")
            self.controlConnected = true
            if self.streamConnected {
                self.userDelegate?.MCConnected()
            }
        }
        self.controlClient.onErrorOccurred = {(_ stream: Stream) -> () in
            LogCenterService.default.add("ControlClient: \(stream.streamError!.localizedDescription)")
            self.controlClient.disconnect()
            self.userDelegate?.MCDisconnected()
        }
        self.controlClient.onEndEncountered = {(_: Stream, _: Stream.Event) -> () in
        }
        self.controlClient.onHasBytesAvailable = {(_ inputStream: InputStream, _ outputStream: OutputStream) -> () in
            let bufferSize = 1024
            var buffer = [UInt8](repeating: 0, count: bufferSize)
            while inputStream.hasBytesAvailable {
                let nRead = inputStream.read(&buffer, maxLength: bufferSize)
                var nProcess = 0
                while nProcess < nRead {
                    if nRead - nProcess >= self.respLen - self.respBuffer.count {
                        // Enough for one response.
                        let nProcessCur = self.respLen - self.respBuffer.count
                        self.respBuffer.append(contentsOf: buffer[nProcess ..< nProcess + nProcessCur])
                        nProcess += nProcessCur
                        let respCode = UInt32(littleEndian: self.respBuffer.withUnsafeBytes {
                            $0.load(as: UInt32.self)
                        })
                        LogCenterService.default.add("Server: \(respCode)")
                        self.respBuffer.removeAll()
                        if MCCode(rawValue: respCode) == MCCode.OK_TO_EXIT {
                            self.controlClient.disconnect()
                            self.streamClient.disconnect()
                            self.userDelegate?.MCDisconnected()
                        }
                    } else {
                        // Not enough for one response.
                        self.respBuffer.append(contentsOf: buffer[nProcess ..< nRead])
                        nProcess = nRead
                    }
                }
            }
        }
    }
    
    func setupStreamClient() {
        self.streamClient.onOpenCompleted = {() -> () in
            LogCenterService.default.add("StreamClient: Connected.")
            self.streamConnected = true
            if self.controlConnected {
                self.userDelegate?.MCConnected()
            }
        }
        self.streamClient.onErrorOccurred = {(_ stream: Stream) -> () in
            LogCenterService.default.add("StreamClient: \(stream.streamError!.localizedDescription)")
        }
        self.streamClient.onEndEncountered = {(_: Stream, _: Stream.Event) -> () in
        }
        self.streamClient.onHasBytesAvailable = {(_ inputStream: InputStream, _ outputStream: OutputStream) -> () in
            let bufferSize = 1024
            var buffer = [UInt8](repeating: 0, count: bufferSize)
            while inputStream.hasBytesAvailable {
                let nRead = inputStream.read(&buffer, maxLength: bufferSize)
                var nProcess = 0
                if !self.streaming {
                    continue
                }
                while nProcess < nRead {
                    if self.imageMetaBuffer.count < self.imageMetaLen {
                        // Meta have not been processed.
                        if nRead - nProcess >= self.imageMetaLen - self.imageMetaBuffer.count {
                            // Rest buffer is bigger or equal than meta length.
                            let nProcessCur = self.imageMetaLen - self.imageMetaBuffer.count
                            self.imageMetaBuffer.append(contentsOf: Array(buffer[nProcess ..< nProcess + nProcessCur]))
                            self.imageLen = UInt32(littleEndian: self.imageMetaBuffer.withUnsafeBytes {
                                $0.load(as: UInt32.self)
                            })
                            nProcess += nProcessCur
                        } else {
                            // Not enough buffer to read meta.
                            self.imageMetaBuffer.append(contentsOf: Array(buffer[nProcess ..< nRead]))
                            nProcess = nRead
                        }
                    } else {
                        // Meta have been processed. Reading the image.
                        if nRead - nProcess < Int(self.imageLen) - self.imageBuffer.count {
                            // Rest buffer is smaller than rest unread image. Read all buffer to the image.
                            self.imageBuffer.append(contentsOf: Array(buffer[nProcess ..< nRead]))
                            nProcess = nRead
                        } else {
                            // Rest buffer is greater or equal than rest unread image.
                            let nProcessCur = Int(self.imageLen) - self.imageBuffer.count
                            self.imageBuffer.append(contentsOf: Array(buffer[nProcess ..< nProcess + nProcessCur]))
                            nProcess += nProcessCur
                            self.imageData.removeAll()
                            self.imageData.append(self.imageBuffer)
                            self.imageBuffer.removeAll()
                            self.imageMetaBuffer.removeAll()
                            self.imageLen = 0
                            self.streamerDelegate?.MCStreaming(self.imageData)
                        }
                    }
                }
            }
        }
    }
    
    func toggleStreaming(assign: Bool? = nil) {
        var judge = !self.streaming
        if assign != nil {
            judge = assign!
        }
        if judge {
            self.startStreaming()
        } else {
            self.closeStreaming()
        }
    }
    
    private func closeStreaming() {
        if !self.controlConnected {
            LogCenterService.default.add("[WARNING]Attempt to stream before connecting, abort.")
            return
        }
        self.streaming = false
        self.controlClient.send(code: MCCode.STREAM_STOP.rawValue)
        self.controlClient.send(code: 0)
        self.imageBuffer.removeAll()
        self.imageMetaBuffer.removeAll()
        self.imageLen = 0
    }

    private func startStreaming() {
        if !self.controlConnected {
            LogCenterService.default.add("[WARNING]Attempt to stream before connecting, abort.")
            return
        }
        self.streaming = true
        self.controlClient.send(code: MCCode.STREAM_START.rawValue)
        self.controlClient.send(code: 0)
    }
    
    func startRec() {
        if !self.controlConnected {
            LogCenterService.default.add("[WARNING]Attempt to record before connecting, abort.")
            return
        }
        self.recording = true
        self.controlClient.send(code: MCCode.REC_START.rawValue)
        self.controlClient.send(code: 0)
    }
    
    func stopRec() {
        if !self.controlConnected {
            LogCenterService.default.add("[WARNING]Attempt to record before connecting, abort.")
            return
        }
        self.recording = false
        self.controlClient.send(code: MCCode.REC_STOP.rawValue)
        self.controlClient.send(code: 0)
        self.controlClient.send(code: MCCode.REC_SAVE.rawValue)
        self.controlClient.send(code: 0)
    }
    
    func switchStreamingCamera(_ index: Int) {
        self.controlClient.send(code: MCCode.STREAM_SWITCH.rawValue)
        self.controlClient.send(code: 4)
        self.controlClient.send(code: UInt32(index))
    }

    func connect() {
        let pref = Preferences.load()
        self.controlClient = TCPClient(ipAddr: pref.serverIPAddr, port: UInt16(pref.serverPort) ?? 0)
        self.streamClient = TCPClient(ipAddr: pref.serverIPAddr, port: UInt16(pref.serverStreamPort) ?? 0)
        self.controlClient.disconnect()
        self.streamClient.disconnect()
        self.setupControlClient()
        self.setupStreamClient()
        self.controlClient.connect()
        self.streamClient.connect()
    }
    
    func disconnect() {
        self.controlClient.send(code: MCCode.EXIT.rawValue)
        self.controlClient.send(code: 0)
    }
}
