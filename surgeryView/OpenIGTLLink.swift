//
//  OpenIGTLLink.swift
//  surgeryView
//
//  Created by BreastCAD on 4/23/24.
//

import Foundation
import Network
import RealityKit

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
        
        let timeStamp = data.subdata(in: offset..<offset+MemoryLayout<UInt64>.size).withUnsafeBytes { $0.pointee } as UInt64
        offset += MemoryLayout<UInt64>.size
        
        let bodySize = data.subdata(in: offset..<offset+MemoryLayout<UInt64>.size).withUnsafeBytes { $0.pointee } as UInt64
        offset += MemoryLayout<UInt64>.size
        
        let CRC = data.subdata(in: offset..<offset+MemoryLayout<UInt64>.size).withUnsafeBytes { $0.pointee } as UInt64

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
}

struct PolyData {
    var npoints: UInt32
    var nvertices: UInt32
    var size_vertices: UInt32
    var nlines: UInt32
    var npolygons: UInt32
    var size_polygons: UInt32
    var ntriangle_strips: UInt32
    var size_triangle_strips: UInt32
    var nattributes: UInt32
    var points: [SIMD3<Float>]
    struct STRUCT_ARRAY {
        var structs: [POINT_INDICES]
    }
    struct POINT_INDICES {
        var nindices: UInt32
        var indices: [UInt32]
    }
    var vertices: STRUCT_ARRAY
    var lines: STRUCT_ARRAY
    var polygons: STRUCT_ARRAY
    var triangle_strips: STRUCT_ARRAY
//    var attribute_header: [(UInt16, UInt32)]
//    var attribute_names: [String]
//    var attribute_data: [[Float]]
    
    static func decode(_ data: Data) -> PolyData? {
        var offset = 0
        
        let npoints = UInt32(bigEndian: data.withUnsafeBytes{$0.load(fromByteOffset: offset, as: UInt32.self)})
        offset += MemoryLayout<UInt32>.size
        
        let nvertices = UInt32(bigEndian: data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) })
        offset += MemoryLayout<UInt32>.size

        let size_vertices = UInt32(bigEndian: data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) })
        offset += MemoryLayout<UInt32>.size

        let nlines = UInt32(bigEndian: data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) })
        offset += MemoryLayout<UInt32>.size

        let npolygons = UInt32(bigEndian: data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) })
        offset += MemoryLayout<UInt32>.size

        let size_polygons = UInt32(bigEndian: data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) })
        offset += MemoryLayout<UInt32>.size
        
        let ntriangle_strips = UInt32(bigEndian: data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) })
        offset += MemoryLayout<UInt32>.size

        let size_triangle_strips = UInt32(bigEndian: data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) })
        offset += MemoryLayout<UInt32>.size

        let nattributes = UInt32(bigEndian: data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) })
        offset += MemoryLayout<UInt32>.size

        var points: [SIMD3<Float>] = []

        for _ in 0..<Int(npoints) {
            let x = Float32(bitPattern: UInt32(bigEndian: data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) }))
            offset += MemoryLayout<UInt32>.size

            let y = Float32(bitPattern: UInt32(bigEndian: data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) }))
            offset += MemoryLayout<UInt32>.size

            let z = Float32(bitPattern: UInt32(bigEndian: data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) }))
            offset += MemoryLayout<UInt32>.size

            points.append(SIMD3(x: x as Float, y: y as Float, z: z as Float))
        }

        // Extracting vertices
        let vertices = extractStructArray(&offset, data, nvertices)

        // Extracting lines
        let lines = extractStructArray(&offset, data, nlines)

        // Extracting polygons
        let polygons = extractStructArray(&offset, data, npolygons)

        // Extracting triangle_strips
        let triangle_strips = extractStructArray(&offset, data, ntriangle_strips)

        func extractStructArray(_ offset: inout Int, _ data: Data, _ count: UInt32) -> STRUCT_ARRAY {
            var structs: [POINT_INDICES] = []
            for _ in 0..<Int(count) {
                let nindices = UInt32(bigEndian: data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) })
                offset += MemoryLayout<UInt32>.size

                var indices: [UInt32] = []
                for _ in 0..<Int(nindices) {
                    let index = UInt32(bigEndian: data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) })
                    offset += MemoryLayout<UInt32>.size
                    indices.append(index)
                }

                structs.append(POINT_INDICES(nindices: nindices, indices: indices))
            }

            return STRUCT_ARRAY(structs: structs)
        }

        return PolyData(npoints: npoints, nvertices: nvertices, size_vertices: size_vertices, nlines: nlines, npolygons: npolygons, size_polygons: size_polygons, ntriangle_strips: ntriangle_strips, size_triangle_strips: size_triangle_strips, nattributes: nattributes, points: points, vertices: vertices, lines: lines, polygons: polygons, triangle_strips: triangle_strips)
    }
}

struct TransformMessage {
    var transform: simd_float4x4
    
    func encode() -> Data{
        var data = Data()
        withUnsafeBytes(of: transform.columns.0.x) { data.append(contentsOf: $0 )}
        withUnsafeBytes(of: transform.columns.0.y) { data.append(contentsOf: $0 )}
        withUnsafeBytes(of: transform.columns.0.z) { data.append(contentsOf: $0 )}
        withUnsafeBytes(of: transform.columns.0.w) { data.append(contentsOf: $0 )}
        
        withUnsafeBytes(of: transform.columns.1.x) { data.append(contentsOf: $0 )}
        withUnsafeBytes(of: transform.columns.1.y) { data.append(contentsOf: $0 )}
        withUnsafeBytes(of: transform.columns.1.z) { data.append(contentsOf: $0 )}
        withUnsafeBytes(of: transform.columns.1.w) { data.append(contentsOf: $0 )}
        
        withUnsafeBytes(of: transform.columns.2.x) { data.append(contentsOf: $0 )}
        withUnsafeBytes(of: transform.columns.2.y) { data.append(contentsOf: $0 )}
        withUnsafeBytes(of: transform.columns.2.z) { data.append(contentsOf: $0 )}
        withUnsafeBytes(of: transform.columns.2.w) { data.append(contentsOf: $0 )}
        
        withUnsafeBytes(of: transform.columns.3.x) { data.append(contentsOf: $0 )}
        withUnsafeBytes(of: transform.columns.3.y) { data.append(contentsOf: $0 )}
        withUnsafeBytes(of: transform.columns.3.z) { data.append(contentsOf: $0 )}
        withUnsafeBytes(of: transform.columns.3.w) { data.append(contentsOf: $0 )}
        return data
    }
    
    
}

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
                var header = Data()

                while header.count < IGTHeader.messageSize {
//                    print("starting to receive")
                    connection.receive(minimumIncompleteLength: 1, maximumLength: 58 - header.count) { content, contentContext, isComplete, error in
                        print("receiving")
                        if let content {
                            header.append(content)
                        }
                    }
                }
                let parsedHeader = IGTHeader.decode(header)
                print(parsedHeader)
                if let parsedHeader{
                    var body = Data()
                    while body.count < parsedHeader.bodySize {
                        connection.receive(minimumIncompleteLength: 1, maximumLength: Int(parsedHeader.bodySize) - body.count) { content, contentContext, isComplete, error in
                            print("receiving")
                            if let content {
                                body.append(content)
                            }
                        }
                    }
                }
            }
            receiveM()
        }
    }
    
    func processMessage(_ data:Data) {
        print(String(data: data, encoding: .utf8))
    }
}
