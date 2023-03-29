//
//  TextureLoader.swift
//  DisplacementRippleMetal
//
//  Created by Dayo Banjo on 3/27/23.
//

import Metal
import MetalKit

class TexturableLoader {
    static func setTexturable(device: MTLDevice, name: String) -> MTLTexture? {
        let textureLoader = MTKTextureLoader(device: device)
        var textureIn: MTLTexture?
        do {
            textureIn = try textureLoader.newTexture(name: name, scaleFactor: 1, bundle: nil)
        }
        catch let error {
            print("Error \(error) loading texture")
        }
        
        return textureIn
    }
}
