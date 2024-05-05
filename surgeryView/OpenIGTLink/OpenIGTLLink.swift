//
//  OpenIGTLLink.swift
//  surgeryView
//
//  Created by BreastCAD on 4/23/24.
//

import Foundation
import Network


actor CommunicationsManager{
    var connection: NWConnection?
    var endpoint: NWEndpoint
    
    init(host: NWEndpoint.Host, port: NWEndpoint.Port) {
        self.endpoint = NWEndpoint.hostPort(host: host, port: port)
    }
    
    func startClient() {
        connection = NWConnection(to: endpoint, using: .tcp)
        if let connection {
            connection.start(queue: .main)
            let message = IGTHeader(v: 2, messageType: "GET_POLYDATA", deviceName: "Client", timeStamp: 0, bodySize: 0, CRC: 0)
            let rawMessage = message.encode()
            connection.send(content: rawMessage, completion: .contentProcessed({ error in
                print("something happened")
            }))
            
            func receiveM() {

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
                            let content_data = data
                            let polyData = PolyDataMessage.decode(content_data)
                            print(polyData)
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

//                if let parsedHeader{
//                    var body = Data()
//                    while body.count < parsedHeader.bodySize {
//                        connection.receive(minimumIncompleteLength: 1, maximumLength: Int(parsedHeader.bodySize) - body.count) { content, contentContext, isComplete, error in
//                            print("receiving")
//                            if let content {
//                                body.append(content)
//                            }
//                        }
//                    }
//                    let ext_header = IGTExtendedHeader.decode(body)
//                    if let ext_header {
//                        print(ext_header)
//                    }
//                }
            }
            receiveM()
        }
    }
    
    func processMessage(_ data:Data) {
        print(String(data: data, encoding: .utf8))
    }
}
