//
//  IGTHeader.swift
//  surgeryView
//
//  Created by Tony Zhang on 5/4/24.
//

import Foundation

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
        print(data.map { String(format: "%02x", $0) }.joined(separator: " "))

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

        let timeStamp = (data.subdata(in: offset..<offset+MemoryLayout<UInt64>.size).withUnsafeBytes { $0.pointee } as UInt64).bigEndian
        offset += MemoryLayout<UInt64>.size

        let bodySize = (data.subdata(in: offset..<offset+MemoryLayout<UInt64>.size).withUnsafeBytes { $0.pointee } as UInt64).bigEndian
        offset += MemoryLayout<UInt64>.size

        let CRC = (data.subdata(in: offset..<offset+MemoryLayout<UInt64>.size).withUnsafeBytes { $0.pointee } as UInt64).bigEndian

        return IGTHeader(v: v, messageType: messageType, deviceName: deviceName, timeStamp: timeStamp, bodySize: bodySize, CRC: CRC)
    }
    func encode() -> Data{
        var data = Data()
        withUnsafeBytes(of: v.bigEndian) { data.append(contentsOf: $0 )}
        data.append(messageType.padding(toLength: 12, withPad: "\0", startingAt: 0).data(using: .ascii) ?? Data())
        data.append(deviceName.padding(toLength: 20, withPad: "\0", startingAt: 0).data(using: .ascii) ?? Data())
        withUnsafeBytes(of: timeStamp.bigEndian) { data.append(contentsOf: $0 )}
        withUnsafeBytes(of: bodySize.bigEndian) { data.append(contentsOf: $0 )}
        withUnsafeBytes(of: CRC.bigEndian) { data.append(contentsOf: $0 )}
        print(data.map { String(format: "%02x", $0) }.joined(separator: " "))
        return data
    }
}

struct IGTExtendedHeader {
    var ext_header_size: UInt16
    var meta_data_size: UInt16
    var msg_id: UInt32
    static var minMessageSize = 8
    func encode() -> Data{
        var data = Data()
        withUnsafeBytes(of: ext_header_size) {data.append(contentsOf: $0)}
        withUnsafeBytes(of: meta_data_size) {data.append(contentsOf: $0)}
        withUnsafeBytes(of: msg_id) {data.append(contentsOf: $0)}
        return data
    }

    static func decode(_ data: Data) -> IGTExtendedHeader?{
        guard data.count >= minMessageSize else {return nil}
        var offset = 0

        print(data.map { String(format: "%02x", $0) }.joined(separator: " "))


        let ext_header_size = (data.subdata(in: offset..<offset+MemoryLayout<UInt64>.size).withUnsafeBytes { $0.pointee } as UInt16).bigEndian
        offset += MemoryLayout<UInt16>.size

        let meta_data_size = (data.subdata(in: offset..<offset+MemoryLayout<UInt64>.size).withUnsafeBytes { $0.pointee } as UInt16).bigEndian
        offset += MemoryLayout<UInt16>.size

        let msg_id = (data.subdata(in: offset..<offset+MemoryLayout<UInt64>.size).withUnsafeBytes { $0.pointee } as UInt32).bigEndian

        return IGTExtendedHeader(ext_header_size: ext_header_size, meta_data_size: meta_data_size, msg_id: msg_id)
    }
}
