//
//  ShaderItem.swift
//  DisplacementRippleMetal
//
//  Created by Dayo Banjo on 10/14/23.
//

import Foundation

struct ShaderItem: Identifiable {
    let id = UUID()
    let title: String
    let vertexName: String
    let fragmentName: String
    let kernelName: String?
}

extension ShaderItem: Equatable {
    static func ==(lhs: ShaderItem, rhs: ShaderItem) -> Bool {
        return lhs.id == rhs.id
    }
}

extension ShaderItem: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


struct ShaderItemSection: Identifiable {
    let id = UUID()
    let title: String
    let shaderItems: [ShaderItem]
}

extension ShaderItemSection: Equatable {
    static func ==(lhs: ShaderItemSection, rhs: ShaderItemSection) -> Bool {
        return lhs.id == rhs.id
    }
}

extension ShaderItemSection: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

class ShaderItemDataSource {
    
    static let sections: [ShaderItemSection] = [
        ShaderItemSection(title: "Basic",
                          shaderItems: [
                            ShaderItem(title: "Plain", vertexName: "vertex_main", fragmentName: "fragment_main", kernelName: nil),
                            ShaderItem(title: "Monterey", vertexName: "vertex_main", fragmentName: "fragment_monterey", kernelName: nil),
                            ShaderItem(title: "Concentric", vertexName: "vertex_main", fragmentName: "fragment_concentric", kernelName: nil),
       ])
    ]
}
