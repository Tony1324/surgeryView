//
//  NoneMessage.swift
//  surgeryView
//
//  Created by BreastCAD on 5/7/24.
//

import Foundation

struct NoneMessage: OpenIGTDecodable, OpenIGTEncodable{
    static func decode(_ data: Data) -> NoneMessage? {
        return NoneMessage()
    }
    
    func encode() -> Data {
        return Data()
    }
}
