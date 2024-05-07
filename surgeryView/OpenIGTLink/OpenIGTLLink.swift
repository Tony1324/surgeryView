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
//            let message = IGTHeader(v: 2, messageType: "GET_POLYDATA", deviceName: "Client", timeStamp: 0, bodySize: 0, CRC: 0)
//            sendMessage(header: message, content: NoneMessage())
            
            func receiveM() async {

                func recieveHeader(_ data: Data){
    //                    print("starting to receive")
                    if(data.count == IGTHeader.messageSize) {
                        let header = IGTHeader.decode(data)
                        if let header {
                            print(header)
                            recieveBody(Data(), header: header)
                        }
                    }
                    connection.receive(minimumIncompleteLength: 0, maximumLength: 58 - data.count) { content, contentContext, isComplete, error in
                        print("receiving")
                        if let content {
                            var _data = Data()
                            _data.append(data)
                            _data.append(content)
                            recieveHeader(_data)
                        }
                    }
                }

                func recieveBody(_ data: Data, header: IGTHeader) {
                    if (data.count == header.bodySize) {
                        print("all data collected")
                        if(header.v >= 2){
                            let ext_header = IGTExtendedHeader.decode(data)
                            if let ext_header {
                                print(ext_header)
                                let ext_header_data = data.subdata(in: 0..<Data.Index(ext_header.ext_header_size))

                                let content_size = Int(header.bodySize) - Int(ext_header.ext_header_size) - Int(ext_header.meta_data_size)

                                let content_data = data.subdata(in: Data.Index(ext_header.ext_header_size)..<content_size + Int(ext_header.ext_header_size))
                                let meta_data_data = data.subdata(in: content_size + Int(ext_header.ext_header_size)..<Int(header.bodySize))
                            }
                        } else
                        {
                            switch header.messageType.trimmingCharacters(in: [" ", "\0"]) {
                            case "POLYDATA":
                                let content_data = data
                                let polyData = PolyDataMessage.decode(content_data)
                                if let polyData{
                                    return delegate.receivePolyDataMessage(header: header, polydata: polyData)
                                }
                                print("Unable to decode PolyData")
                            case "TRANSFORM":
                                let content_data = data
                                let transform = TransformMessage.decode(content_data)
                                if let transform{
                                    return delegate.receiveTransformMessage(header: header, transform: transform)
                                }
                                print("Unable to decode PolyData")
                            default:
                                print("No message body")
                            }
                            
                        }

                    }
                    connection.receive(minimumIncompleteLength: 0, maximumLength: Int(header.bodySize) - data.count) { content, contentContext, isComplete, error in
                        print("receiving")
                        if let content {
                            var _data = Data()
                            _data.append(data)
                            _data.append(content)
                            recieveBody(_data, header: header)
                        }
                    }
                }
                recieveHeader(Data())
            }
            Task{
                await receiveM()
            }
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
