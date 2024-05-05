//
//  Polydata.swift
//  surgeryView
//
//  Created by Tony Zhang on 5/4/24.
//

import Foundation

struct PolyDataMessage {
    var npoints: UInt32
    var nvertices: UInt32
    var size_vertices: UInt32
    var nlines: UInt32
    var size_lines: UInt32
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

    static func decode(_ data: Data) -> PolyDataMessage? {
        var offset = 0

        print(data.map { String(format: "%02x", $0) }.joined(separator: " "))


        let npoints = UInt32(bigEndian: data.withUnsafeBytes{$0.load(fromByteOffset: offset, as: UInt32.self)})
        offset += MemoryLayout<UInt32>.size

        let nvertices = UInt32(bigEndian: data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) })
        offset += MemoryLayout<UInt32>.size

        let size_vertices = UInt32(bigEndian: data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) })
        offset += MemoryLayout<UInt32>.size

        let nlines = UInt32(bigEndian: data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) })
        offset += MemoryLayout<UInt32>.size

        let size_lines = UInt32(bigEndian: data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) })
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
                let nindices = (data.subdata(in: offset..<offset+MemoryLayout<UInt32>.size).withUnsafeBytes { $0.pointee } as UInt32).bigEndian
                offset += MemoryLayout<UInt32>.size

                var indices: [UInt32] = []
                for _ in 0..<Int(nindices) {
                    let index = (data.subdata(in: offset..<offset+MemoryLayout<UInt32>.size).withUnsafeBytes { $0.pointee } as UInt32).bigEndian
                    offset += MemoryLayout<UInt32>.size
                    indices.append(index)
                }

                structs.append(POINT_INDICES(nindices: nindices, indices: indices))
            }

            return STRUCT_ARRAY(structs: structs)
        }

        return PolyDataMessage(npoints: npoints, nvertices: nvertices, size_vertices: size_vertices, nlines: nlines, size_lines: size_lines, npolygons: npolygons, size_polygons: size_polygons, ntriangle_strips: ntriangle_strips, size_triangle_strips: size_triangle_strips, nattributes: nattributes, points: points, vertices: vertices, lines: lines, polygons: polygons, triangle_strips: triangle_strips)
    }
}
