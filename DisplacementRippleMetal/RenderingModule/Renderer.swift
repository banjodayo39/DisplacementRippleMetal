//
//  Renderer.swift
//  DisplacementRippleMetal
//
//  Created by Dayo Banjo on 3/28/23.
//

import Foundation
import UIKit
import Metal
import MetalKit
import simd

struct Constants  {
    var moveBy: Float = 0
    var resolution: SIMD2<Float> = .zero;
}

struct Vertex {
    var position: simd_float4
    var color: simd_float4
    var texture: simd_float2
}

let MaxOutstandingFrameCount = 3

class Renderer: NSObject, MTKViewDelegate {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let view: MTKView
    
    var time: Float = 0.0
    
    private var renderPipelineState: MTLRenderPipelineState!
    
    private var frameSemaphore = DispatchSemaphore(value: MaxOutstandingFrameCount)
    private var frameIndex: Int
    
    private var vertexBuffer: MTLBuffer?
    private var indexBuffer: MTLBuffer?
    
    var constant = Constants()
    var texture: MTLTexture?
    var sampleState: MTLSamplerState?
    lazy var screenSize = view.bounds.size
    let screenScale = UIScreen.main.scale 
    var resolution: simd_float2!
 
    var vertices = [
        Vertex(position:  simd_float4(-1, 1, 0, 1), color: simd_float4(0.5, 1, 0.6, 0), texture: simd_float2(0, 1)),
        Vertex(position:  simd_float4(-1, -1, 0, 1), color: simd_float4(0.7, 1, 0.7, 0), texture: simd_float2(0, 0)),
        Vertex(position:  simd_float4(1, -1, 0, 1), color: simd_float4(0.59, 0, 1, 0), texture: simd_float2(1, 0)),
        Vertex(position:  simd_float4(1, 1, 0, 1), color: simd_float4(-1, 1, 0, 0), texture: simd_float2(1,1)),
        
    ]
    var indicies: [UInt16] = [0, 1, 2,2, 3, 0]
    
    init(device: MTLDevice, view: MTKView) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        self.view = view
        self.frameIndex = 0
        
        
        super.init()
        
        view.device = device
        view.delegate = self
        view.clearColor = MTLClearColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
        
        makeResources()
        makePipeline()
        buildSamplerState()
    }
    
    func buildSamplerState() {
        let descriptor = MTLSamplerDescriptor()
        descriptor.minFilter = .linear
        descriptor.magFilter = .linear
        sampleState = device.makeSamplerState(descriptor: descriptor)
    }
    
    func makePipeline() {
        
        texture = TexturableLoader.setTexturable(device: device, name: "burriedhourglass")
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Unable to create default Metal library")
        }
        
        let vertexDescriptor = MTLVertexDescriptor()
        
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        vertexDescriptor.attributes[1].format = .float4
        vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD3<Float>>.stride
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        vertexDescriptor.attributes[2].format = .float2
        vertexDescriptor.attributes[2].offset = MemoryLayout<SIMD3<Float>>.stride + MemoryLayout<SIMD4<Float>>.stride
        vertexDescriptor.attributes[2].bufferIndex = 0
        
        vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride
        
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        
        renderPipelineDescriptor.vertexFunction = library.makeFunction(name: "vertex_main")!
        renderPipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragment_monterey")!
        
        do {
            renderPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        } catch {
            fatalError("Error while creating render pipeline state: \(error)")
        }
    }
    
    func makeResources() {
        resolution = simd_float2(Float(screenSize.width * screenScale), Float(screenSize.height * screenScale))
        
        constant.resolution = resolution
        vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Vertex>.size)
        indexBuffer = device.makeBuffer(bytes: indicies, length: indicies.count * MemoryLayout<UInt16>.size)
    }
    
    func updateConstants(view: MTKView) {
        time += 1.0 / Float(view.preferredFramesPerSecond)
        
        constant.moveBy = abs(sin(time) + 0.5)
    }
    
    // MARK: - MTKViewDelegate
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
    
    func draw(in view: MTKView) {
        frameSemaphore.wait()
        updateConstants(view: view)
        
        guard let renderPassDescriptor = view.currentRenderPassDescriptor,
              let indexBuffer = indexBuffer,
              let sampleState = sampleState
        else { return }
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        
        let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderCommandEncoder.setRenderPipelineState(renderPipelineState)
        renderCommandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderCommandEncoder.setVertexBytes(&constant, length: MemoryLayout<Constants>.stride, index: 1)
        renderCommandEncoder.setFragmentTexture(texture, index: 0)
        renderCommandEncoder.setFragmentSamplerState(sampleState, index: 0)
        
        renderCommandEncoder.drawIndexedPrimitives(type: .triangle,
                                                   indexCount: indicies.count,
                                                   indexType: .uint16,
                                                   indexBuffer: indexBuffer,
                                                   indexBufferOffset: 0)
        renderCommandEncoder.endEncoding()
        
        commandBuffer.present(view.currentDrawable!)
        
        commandBuffer.addCompletedHandler { [weak self] _ in
            self?.frameSemaphore.signal()
        }
        
        commandBuffer.commit()
        
        frameIndex += 1
    }
}
