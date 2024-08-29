//
//  String.swift
//  surgeryView
//
//  Created by BreastCAD on 7/16/24.
//

import Foundation

//see https://github.com/openigtlink/OpenIGTLink/blob/master/Documents/Protocol/string.md for protocol
struct StringMessage: OpenIGTDecodable, OpenIGTEncodable {
    var str: String
    static func decode(_ data: Data) -> StringMessage? {
        let data = DataReader(data)
        guard let encoding: UInt16 = data.readInt() else {return nil}
        guard let length: UInt16 = data.readInt() else {return nil}
        guard let string = data.readString(length: Int(length)) else {return nil}
        return StringMessage(str: string)
    }
    func encode() -> Data {
        var data = Data()
        withUnsafeBytes(of: UInt16(3)) { pointer in
            data.append(contentsOf: pointer)
        }
        
        withUnsafeBytes(of: UInt16(str.lengthOfBytes(using: .ascii))) { ptr in
            data.append(contentsOf: ptr)
        }
        data.append(contentsOf: str.data(using: .ascii)!)
        
        return data
    }
}
