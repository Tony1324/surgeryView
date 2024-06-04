//
//  Polydata.swift
//  surgeryView
//
//  Created by Tony Zhang on 5/4/24.
//

import Foundation
import RealityKit


struct PolyDataMessage: OpenIGTDecodable {
    
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
    var attribute_header: [(UInt16, UInt32)]
    var attribute_names: [String]
    var attribute_data: [[Float]]

    static func decode(_ data: Data) -> PolyDataMessage? {
        let data = DataReader(data)

        guard let npoints: UInt32 = data.readInt() else {return nil}
        guard let nvertices: UInt32 = data.readInt() else {return nil}
        guard let size_vertices: UInt32 = data.readInt() else {return nil}
        guard let nlines: UInt32 = data.readInt() else {return nil}
        guard let size_lines: UInt32 = data.readInt() else {return nil}
        guard let npolygons: UInt32 = data.readInt() else {return nil}
        guard let size_polygons: UInt32 = data.readInt() else {return nil}
        guard let ntriangle_strips: UInt32 = data.readInt() else {return nil}
        guard let size_triangle_strips: UInt32 = data.readInt() else {return nil}
        guard let nattributes: UInt32 = data.readInt() else {return nil}

        var points: [SIMD3<Float>] = []

        for _ in 0..<Int(npoints) {
            guard let x = data.readFloat() else {return nil}

            guard let y = data.readFloat() else {return nil}

            guard let z = data.readFloat() else {return nil}

            points.append(SIMD3(x: x as Float, y: z as Float, z: -y as Float))
        }

        guard let vertices = extractStructArray(nvertices) else {return nil}

        guard let lines = extractStructArray(nlines) else {return nil}

        guard let polygons = extractStructArray(npolygons) else {return nil}

        guard let triangle_strips = extractStructArray(ntriangle_strips) else {return nil}

        func extractStructArray(_ count: UInt32) -> STRUCT_ARRAY? {
            var structs: [POINT_INDICES] = []
            for _ in 0..<Int(count) {
                guard let nindices: UInt32 = data.readInt() else {return nil}

                var indices: [UInt32] = []
                for _ in 0..<Int(nindices) {
                    guard let index: UInt32 = data.readInt() else {return nil}
                    indices.append(index)
                }

                structs.append(POINT_INDICES(nindices: nindices, indices: indices))
            }

            return STRUCT_ARRAY(structs: structs)
        }
        
        var attribute_header: [(UInt16, UInt32)] = []
        
        for _ in 0..<Int(nattributes) {
            guard let attributeType: UInt16 = data.readInt() else {return nil}
            guard let nattribute: UInt32 = data.readInt() else {return nil}
            attribute_header.append((attributeType,nattribute))
        }
        
        // TODO
        var attribute_names:[String] = []
        
        var attribute_data: [[Float]] = []

        return PolyDataMessage(npoints: npoints, nvertices: nvertices, size_vertices: size_vertices, nlines: nlines, size_lines: size_lines, npolygons: npolygons, size_polygons: size_polygons, ntriangle_strips: ntriangle_strips, size_triangle_strips: size_triangle_strips, nattributes: nattributes, points: points, vertices: vertices, lines: lines, polygons: polygons, triangle_strips: triangle_strips, attribute_header: attribute_header, attribute_names: attribute_names, attribute_data: attribute_data)
    }
    
    func generateModelEntityFromTris() -> ModelEntity? {
        // Create mesh vertices
        var meshDescriptor = MeshDescriptor(name: "mesh")
        meshDescriptor.positions = MeshBuffers.Positions(points)
        var triangles: [UInt32] = []
        for triangle in triangle_strips.structs {
            if triangle.indices.count == 3{
                triangles.append(triangle.indices[0])
                triangles.append(triangle.indices[1])
                triangles.append(triangle.indices[2])
            }
            return nil
        }
        meshDescriptor.primitives = .triangles(triangles)
        
        if let mesh = try? MeshResource.generate(from: [meshDescriptor]) {
            var model = ModelEntity(mesh: mesh, materials: [SimpleMaterial(color: .blue, isMetallic: false)])
            return model
        }
        return nil
    }
    
    func generateModelEntityFromPolys() -> ModelEntity? {
        // Create mesh vertices
        var meshDescriptor = MeshDescriptor(name: "mesh")
        meshDescriptor.positions = MeshBuffers.Positions(points)
        var counts: [UInt8] = []
        var polys: [UInt32] = []
        for poly in polygons.structs {
            counts.append(UInt8(poly.indices.count))
            polys.append(contentsOf: poly.indices)
        }
        meshDescriptor.primitives = .polygons(counts, polys)
        
        // Create model component
        if let mesh = try? MeshResource.generate(from: [meshDescriptor]) {
            var model = ModelEntity(mesh: mesh, materials: [PhysicallyBasedMaterial()])
            return model
        }
        return nil
    }
}
