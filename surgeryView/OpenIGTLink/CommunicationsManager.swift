//
//  CommunicationsManager.swift
//  surgeryView
//
//  Created by Tony Zhang on 4/23/24.
//

import Foundation
import Network


class CommunicationsManager{
    var listener: NWListener?
    var connection: NWConnection?
    var port: NWEndpoint.Port
    var delegate: OpenIGTDelegate
    
    init(port: NWEndpoint.Port, delegate: OpenIGTDelegate) {
        self.port = port
        self.delegate = delegate
    }
    
    func startServer() {
        //NWListener is the "server" for Apple's Network framework
        listener = try? NWListener(using: .tcp, on: port)
        if let listener {
            listener.start(queue: .main)
            listener.stateUpdateHandler = { state in
                switch state{
                case .setup:
                    print("starting to listen")
                case .ready:
                    print("starting to listen")
                case .failed:
                    print("server failed")
                default:
                    break
                }
            }
            listener.newConnectionHandler = { connection in
                self.connection = connection
                connection.start(queue: .main)
                self.sendMessage(header: IGTHeader(v: 1, messageType: "STRING", deviceName: "TEST", timeStamp: UInt64(Date.now.timeIntervalSince1970), bodySize: 0, CRC: 0), content: StringMessage(str: "TESTING SEND"))
                //after finishing connection to server, immediately begin listening for messages, and recursively calling itself to receive more messages
                //here data is parsed and the OpenIGTDelegate (ModelData) is called to handle the messages
                self.receiveMessage(connection: connection)
                print("connection received")
            }
        }
    }
    
    func receiveMessage(connection: NWConnection) {
        //TCP guarentees that the data will be in order and correct, and receives data as a stream
        //practically this means that the function connection.receive can provide any number of bytes up to max
        //therefore, both receiveHeader and receiveBody recursively call themselves until the entire message is fully received
        
        func receiveHeader(_ data: Data){
            if(data.count == IGTHeader.messageSize) {
                let header = IGTHeader.decode(data)
                if let header {
                    receiveBody(Data(), header: header)
                    print(header.messageType, header.deviceName)
                }
                return
            }
            connection.receive(minimumIncompleteLength: 0, maximumLength: 58 - data.count) { content, contentContext, isComplete, error in
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
                var ext_header_data: Data = Data()
                var meta_data_data: Data = Data()
                var content_data: Data = Data()
                if(header.v >= 2){
                    let ext_header = IGTExtendedHeader.decode(data)
                    if let ext_header {
                        ext_header_data = data.subdata(in: data.startIndex + 0 ..< data.startIndex + Data.Index(ext_header.ext_header_size))
                        let content_size = Int(header.bodySize) - Int(ext_header.ext_header_size) - Int(ext_header.meta_data_size)
                        content_data = data.subdata(in: data.startIndex + Data.Index(ext_header.ext_header_size) ..< data.startIndex + content_size + Int(ext_header.ext_header_size))
                        meta_data_data = data.subdata(in: data.startIndex +  content_size + Int(ext_header.ext_header_size) ..< data.startIndex + Int(header.bodySize))
                    }
                }else{
                    content_data = data
                }
                switch header.messageType.trimmingCharacters(in: [" ", "\0"]) {
                case "POLYDATA":
                    let polyData = PolyDataMessage.decode(content_data)
                    if let polyData{
                        delegate.receivePolyDataMessage(header: header, polydata: polyData)
                    } else {
                        print("Unable to decode PolyData")
                    }
                case "TRANSFORM":
                    let transform = TransformMessage.decode(content_data)
                    if let transform{
                        delegate.receiveTransformMessage(header: header, transform: transform)
                    } else {
                        print("Unable to decode Transform")
                    }
                case "IMAGE":
                    let image = ImageMessage.decode(content_data)
                    if let image {
                        delegate.receiveImageMessage(header: header, image: image)
                    } else {
                        print("Unable to decode Image")
                    }
                case "STRING":
                    let string = StringMessage.decode(content_data)
                    if let string {
                        delegate.receiveStringMessage(header: header, string: string)
                    } else {
                        print("Unable to decode Command")
                    }
                default:
                    print("Unrecognized Message: \(header.messageType)")
                }
                receiveMessage(connection: connection)
                return
            }
            connection.receive(minimumIncompleteLength: 0, maximumLength: Int(header.bodySize) - data.count) { content, contentContext, isComplete, error in
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
    
    func sendMessage(header: IGTHeader, content: OpenIGTEncodable) {
        if let connection {
            let rawContent = content.encode()
            var _header = header
            _header.bodySize = UInt64(rawContent.count)
            let rawHeader = _header.encode()
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
        listener?.cancel()
//        connection?.cancel()
    }
}

protocol OpenIGTDecodable{
    static func decode(_ data: Data) -> (Self?)
}

protocol OpenIGTEncodable{
    func encode() -> Data
}

protocol OpenIGTDelegate{
    func receivePolyDataMessage(header: IGTHeader, polydata: PolyDataMessage)
    func receiveTransformMessage(header: IGTHeader, transform: TransformMessage)
    func receiveImageMessage(header: IGTHeader, image: ImageMessage)
    func receiveStringMessage(header: IGTHeader, string: StringMessage)

}

extension OpenIGTDelegate{
    func receivePolyDataMessage(header: IGTHeader, polydata: PolyDataMessage) {
        print("No implementation for receiving PolyData")
    }
    func receiveTransformMessage(header: IGTHeader, transform: TransformMessage) {
        print("No implementation for receiving Transform")
    }
    func receiveImageMessage(header: IGTHeader, image: ImageMessage) {
        print("No implementation for receiving Image")
    }
    func receiveStringMessage(header: IGTHeader, string: StringMessage) {
        print("No implementation for receiving String")
    }
}
