//
//  IGTHeader.swift
//  surgeryView
//
//  Created by Tony Zhang on 5/4/24.
//

import Foundation

//see https://github.com/openigtlink/OpenIGTLink/blob/master/Documents/Protocol/header.md for protocol
struct IGTHeader: OpenIGTDecodable, OpenIGTEncodable{
    var v: UInt16
    var messageType: String
    var deviceName: String
    var timeStamp: UInt64
    var bodySize: UInt64
    var CRC: UInt64

    static var messageSize = 58
    static func decode(_ data: Data) -> IGTHeader?{
        guard data.count == messageSize else {return nil}
        var data = DataReader(data)

        guard let v: UInt16 = data.readInt() else {return nil}

        guard let messageType = data.readString(length:12) else {return nil}

        guard let deviceName = data.readString(length:20) else {return nil}
        
        guard let timeStamp: UInt64 = data.readInt() else {return nil}

        guard let bodySize: UInt64 = data.readInt() else {return nil}

        guard let CRC: UInt64 = data.readInt() else {return nil}

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
        return data
    }
    
    static func create(messageType: String, name: String) -> IGTHeader {
        return IGTHeader(v: 1, messageType: messageType, deviceName: name, timeStamp: UInt64(Date.now.timeIntervalSince1970), bodySize: 0, CRC: 0)
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
        let data = DataReader(data)

        guard let ext_header_size: UInt16 = data.readInt() else {return nil}
        
        guard let meta_data_size: UInt16 = data.readInt() else {return nil}

        guard let msg_id: UInt32 = data.readInt() else {return nil}

        return IGTExtendedHeader(ext_header_size: ext_header_size, meta_data_size: meta_data_size, msg_id: msg_id)
    }
}
