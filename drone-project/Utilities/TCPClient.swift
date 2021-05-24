//
//  TCPClient.swift
//  drone-project
//
//  Created by klab on 2021/01/07.
//

import Foundation

class TCPClient: NSObject, StreamDelegate {
    enum TCPError: Error {
        case connectionFailed(withIP: String, withPort: UInt32)
        case handlerUndefined(eventCode: Stream.Event)
        case unknownStreamEvent
    }
    
    var ipAddr: String
    var port: UInt16
    var onOpenCompleted: (() -> ())!
    var onHasBytesAvailable: ((_: InputStream, _: OutputStream) -> ())!
//    var onHasSpaceAvailable: ((_: Stream, _: Stream.Event) -> ())!
    var onErrorOccurred: ((_: Stream) -> ())!
    var onEndEncountered: ((_: Stream, _: Stream.Event) -> ())!
    private var readStreamRef: Unmanaged<CFReadStream>?
    private var writeStreamRef: Unmanaged<CFWriteStream>?
    private var readStream: InputStream!
    private var writeStream: OutputStream!

    init(ipAddr: String, port: UInt16) {
        self.ipAddr = ipAddr
        self.port = port
    }
    
    func connect() {
        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (self.ipAddr as CFString), UInt32(self.port), &readStreamRef, &writeStreamRef)
        self.readStream = readStreamRef!.takeRetainedValue()
        self.writeStream = writeStreamRef!.takeRetainedValue()
        self.readStream.delegate = self
        self.writeStream.delegate = self
        self.readStream.schedule(in: RunLoop.current, forMode: RunLoop.Mode.default)
        self.writeStream.schedule(in: RunLoop.current, forMode: RunLoop.Mode.default)
        self.readStream.open()
        self.writeStream.open()
    }
    
    func disconnect() {
        if self.readStream != nil {
            self.readStream.remove(from: RunLoop.current, forMode: RunLoop.Mode.default)
            self.readStream.close()
        }
        if self.writeStream != nil {
            self.writeStream.remove(from: RunLoop.current, forMode: RunLoop.Mode.default)
            self.writeStream.close()
        }
        self.readStream = nil
        self.writeStream = nil
    }
    
    func send(raw: [UInt8], length: Int) {
        writeStream.write(raw, maxLength: length)
    }
    
    func send(code: UInt32) {
        var endian = code.littleEndian
        let count = MemoryLayout<UInt32>.size
        let bytePtr = withUnsafePointer(to: &endian) {
            $0.withMemoryRebound(to: UInt8.self, capacity: count) {
                UnsafeBufferPointer(start: $0, count: count)
            }
        }
        let byteArray = Array(bytePtr)
        writeStream.write(byteArray, maxLength: count)
    }

    func send(message: String) {
        let buff = [UInt8](message.utf8)
        writeStream.write(buff, maxLength: buff.count)
    }
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        if aStream == writeStream {
            return
        }
        switch eventCode {
        case .openCompleted:
            onOpenCompleted()
        case .hasBytesAvailable:
            onHasBytesAvailable(readStream, writeStream)
        case .hasSpaceAvailable:
//            onHasSpaceAvailable(aStream, eventCode)
            return
        case .errorOccurred:
            onErrorOccurred(aStream)
        case .endEncountered:
            onEndEncountered(aStream, eventCode)
            return
        default:
            return
        }
    }

}
