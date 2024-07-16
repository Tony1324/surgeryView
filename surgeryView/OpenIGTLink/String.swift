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
        guard let string = data.readString(length: data.data.count) else {return nil}
        return StringMessage(str: string.filter{$0.isLetter})
    }
}
