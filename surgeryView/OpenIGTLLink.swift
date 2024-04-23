//
//  OpenIGTLLink.swift
//  surgeryView
//
//  Created by BreastCAD on 4/23/24.
//

import Foundation
import Network

struct IGTHeader {
    var v: UInt16
    var messageType: String
    var deviceName: String
    var timeStamp: UInt64
    var bodySize: UInt64
    var CRC: UInt64
    
    static var messageSize = 58
    static func decode(_ data: Data) -> IGTHeader?{
        guard data.count == messageSize else {return nil}
        var offset = 0
        
        //Version Number
        let v = UInt16(bigEndian: data.withUnsafeBytes({ bufferPointer in
            bufferPointer.load(fromByteOffset: offset, as: UInt16.self)
        }))
        offset += MemoryLayout<UInt16>.size
        
        //Unpack Message Type
        let messageTypeData = data.subdata(in: offset..<offset+12)
        guard let messageType = String(data: messageTypeData, encoding: .ascii) else { return nil }
        offset += 12
        
        let deviceNameData = data.subdata(in: offset..<offset+20)
        guard let deviceName = String(data: deviceNameData, encoding: .ascii) else { return nil }
        offset += 20
        
        let timeStamp = UInt64(littleEndian: data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt64.self) })
        offset += MemoryLayout<UInt64>.size
        
        let bodySize = UInt64(littleEndian: data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt64.self) })
        offset += MemoryLayout<UInt64>.size
        
        let CRC = UInt64(littleEndian: data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt64.self) })
        
        return IGTHeader(v: v, messageType: messageType, deviceName: deviceName, timeStamp: timeStamp, bodySize: bodySize, CRC: CRC)
    }
}

class CommunicationsManager{
    var connection: NWConnection?
    var endpoint: NWEndpoint = .hostPort(host: "127.0.0.1", port: .init(rawValue: 8267)!)
    
    init(host: NWEndpoint.Host, port: NWEndpoint.Port) {
        self.endpoint = NWEndpoint.hostPort(host: host, port: port)
    }
    
    func startClient() {
        connection = NWConnection(to: endpoint, using: .tcp)
        if let connection {
            connection.start(queue: .main)
            connection.send(content: "testing".data(using: .utf8), completion: .contentProcessed({ error in
                print("something happened")
            }))
            
            func receiveM() {
                var header = Data()
                while header.count < IGTHeader.messageSize {
                    connection.receive(minimumIncompleteLength: 0, maximumLength: 58 - header.count) { content, contentContext, isComplete, error in
                        if let content {
                            header.append(content)
                        }
                    }
                }
                
                let parsedHeader = IGTHeader.decode(header)
            }
            receiveM()
        }
    }
    
    func processMessage(_ data:Data) {
        print(String(data: data, encoding: .utf8))
    }
}
