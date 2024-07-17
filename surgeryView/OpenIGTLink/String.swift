//
//  String.swift
//  surgeryView
//
//  Created by BreastCAD on 7/16/24.
//

import Foundation
struct StringMessage: OpenIGTDecodable {
    var str: String
    static func decode(_ data: Data) -> StringMessage? {
        let data = DataReader(data)
        guard let encoding: UInt16 = data.readInt() else {return nil}
        guard let length: UInt16 = data.readInt() else {return nil}
        guard let string = data.readString(length: Int(length)) else {return nil}
        return StringMessage(str: string)
    }
}
