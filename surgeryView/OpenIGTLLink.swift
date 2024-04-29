//
//  OpenIGTLLink.swift
//  surgeryView
//
//  Created by BreastCAD on 4/23/24.
//

import Foundation
import Network

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
        
        let timeStamp = UInt64(bigEndian: data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt64.self) })
        offset += MemoryLayout<UInt64>.size
        
        let bodySize = UInt64(bigEndian: data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt64.self) })
        offset += MemoryLayout<UInt64>.size
        
        let CRC = UInt64(bigEndian: data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt64.self) })

        return IGTHeader(v: v, messageType: messageType, deviceName: deviceName, timeStamp: timeStamp, bodySize: bodySize, CRC: CRC)
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
    var points: [(Float32, Float32, Float32)]
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

        var points: [(Float32, Float32, Float32)] = []

        for _ in 0..<Int(npoints) {
            let x = Float32(bitPattern: UInt32(bigEndian: data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) }))
            offset += MemoryLayout<UInt32>.size

            let y = Float32(bitPattern: UInt32(bigEndian: data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) }))
            offset += MemoryLayout<UInt32>.size

            let z = Float32(bitPattern: UInt32(bigEndian: data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) }))
            offset += MemoryLayout<UInt32>.size

            points.append((x, y, z))
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

class CommunicationsManager{
    var connection: NWConnection?
    var endpoint: NWEndpoint = .hostPort(host: "127.0.0.1", port: .init(rawValue: 8267)!)
    
    init(host: NWEndpoint.Host, port: NWEndpoint.Port) {
        self.endpoint = NWEndpoint.hostPort(host: host, port: port)
    }
    
    func startClient() {
        connection = NWConnection(to: endpoint, using: .tcp)
        if let connection {
            connection.start(queue: .main)
            connection.send(content: "testing".data(using: .utf8), completion: .contentProcessed({ error in
                print("something happened")
            }))
            
            func receiveM() {
                var header = Data()
                while header.count < IGTHeader.messageSize {
                    connection.receive(minimumIncompleteLength: 0, maximumLength: 58 - header.count) { content, contentContext, isComplete, error in
                        if let content {
                            header.append(content)
                        }
                    }
                }


                let parsedHeader = IGTHeader.decode(header)
            }
            receiveM()
        }
    }
    
    func processMessage(_ data:Data) {
        print(String(data: data, encoding: .utf8))
    }
}
