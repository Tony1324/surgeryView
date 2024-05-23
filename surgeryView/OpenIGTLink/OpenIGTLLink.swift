//
//  OpenIGTLLink.swift
//  surgeryView
//
//  Created by BreastCAD on 4/23/24.
//

import Foundation
import Network


class CommunicationsManager{
    var connection: NWConnection?
    var endpoint: NWEndpoint
    var delegate: OpenIGTDelegate
    
    init(host: NWEndpoint.Host, port: NWEndpoint.Port, delegate: OpenIGTDelegate) {
        self.endpoint = NWEndpoint.hostPort(host: host, port: port)
        self.delegate = delegate
    }
    
    func startClient() {
        connection = NWConnection(to: endpoint, using: .tcp)
        if let connection {
            connection.start(queue: .main)
            //after finishing connection to server, immediately begin listening for messages, and recursively calling itself to receive more messages
            //here data is parsed and the OpenIGTDelegate (ModelData) is called to handle the messages
            func receiveM() {
                func receiveHeader(_ data: Data){
                        print("starting to receive")
                    if(data.count == IGTHeader.messageSize) {
                        let header = IGTHeader.decode(data)
                        if let header {
                            print(header)
                            receiveBody(Data(), header: header)
                        }
                        return
                    }
                    connection.receive(minimumIncompleteLength: 0, maximumLength: 58 - data.count) { content, contentContext, isComplete, error in
                        print("receiving")
                        if let content {
                            var _data = Data()
                            _data.append(data)
                            _data.append(content)
                            receiveHeader(_data)
                        }
                    }
                }

                func receiveBody(_ data: Data, header: IGTHeader) {
                    if (data.count == header.bodySize) {
                        print("all data collected")
                        var ext_header_data: Data = Data()
                        var meta_data_data: Data = Data()
                        var content_data: Data = Data()
                        if(header.v >= 2){
                            let ext_header = IGTExtendedHeader.decode(data)
                            if let ext_header {
                                print(ext_header)
                                ext_header_data = data.subdata(in: 0..<Data.Index(ext_header.ext_header_size))

                                let content_size = Int(header.bodySize) - Int(ext_header.ext_header_size) - Int(ext_header.meta_data_size)

                                content_data = data.subdata(in: Data.Index(ext_header.ext_header_size)..<content_size + Int(ext_header.ext_header_size))
                                meta_data_data = data.subdata(in: content_size + Int(ext_header.ext_header_size)..<Int(header.bodySize))
                            }
                        }else{
                            content_data = data
                        }
                        switch header.messageType.trimmingCharacters(in: [" ", "\0"]) {
                        case "POLYDATA":
                            let polyData = PolyDataMessage.decode(content_data)
                            if let polyData{
                                delegate.receivePolyDataMessage(header: header, polydata: polyData)
                            }
                            print("Unable to decode PolyData")
                        case "TRANSFORM":
                            let transform = TransformMessage.decode(content_data)
                            if let transform{
                                delegate.receiveTransformMessage(header: header, transform: transform)
                            }
                            print("Unable to decode PolyData")
                        default:
                            print("No message body")
                        }
                        print("receiving another message")
                        receiveM()
                        return
                    }
                    connection.receive(minimumIncompleteLength: 0, maximumLength: Int(header.bodySize) - data.count) { content, contentContext, isComplete, error in
                        print("receiving")
                        if let content {
                            var _data = Data()
                            _data.append(data)
                            _data.append(content)
                            receiveBody(_data, header: header)
                        }
                    }
                }
                receiveHeader(Data())
            }
            receiveM()
        }
    }
    
    func sendMessage(header: IGTHeader, content: OpenIGTEncodable) {
        if let connection {
            let rawHeader = header.encode()
            let rawContent = content.encode()
            var data = Data()
            data.append(rawHeader)
            data.append(rawContent)
            print("message sent")
            connection.send(content: data, completion: .contentProcessed({ error in
                print(error)
            }))
        }
    }
    
    func disconnect(){
        connection?.cancel()
    }
}

protocol OpenIGTDecodable{
    static func decode(_ data: Data) -> Self?
}

protocol OpenIGTEncodable{
    func encode() -> Data
}

protocol OpenIGTDelegate{
    func receivePolyDataMessage(header: IGTHeader, polydata: PolyDataMessage)
    func receiveTransformMessage(header: IGTHeader, transform: TransformMessage)
}

extension OpenIGTDelegate{
    func receivePolyDataMessage(header: IGTHeader, polydata: PolyDataMessage) {
        print("No implementation for recieving PolyData")
    }
    func receiveTransformMessage(header: IGTHeader, transform: TransformMessage) {
        print("No implementation for recieving Transform")
    }
}
