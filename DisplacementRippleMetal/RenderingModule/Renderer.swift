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

struct Vertex {
    var position: simd_float4
    var color: simd_float4
    var texture: simd_float2
}

let MaxOutstandingFrameCount = 3

class Renderer: NSObject, MTKViewDelegate {
    private var renderPipelineState: MTLRenderPipelineState!
    private var frameSemaphore = DispatchSemaphore(value: MaxOutstandingFrameCount)
    private var frameIndex: Int
    
    private var vertexBuffer: MTLBuffer?
    private var indexBuffer: MTLBuffer?
    
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let view: MTKView
    
    private let vertexFunctionName: String
    private let fragmentFunctionName: String
    private let kernelFunctionName: String?
    
    private var texture: MTLTexture?
    private var sampleState: MTLSamplerState?
    private var renderingElapsedTime: TimeInterval = .zero
    private var previousRenderElapsedTime: TimeInterval = .zero
    
    var touchPoint: CGPoint = .zero
    
    var vertices = [
        Vertex(position:  simd_float4(-1, 1, 0, 1), color: simd_float4(0.5, 1, 0.6, 0), texture: simd_float2(0, 1)),
        Vertex(position:  simd_float4(-1, -1, 0, 1), color: simd_float4(0.7, 1, 0.7, 0), texture: simd_float2(0, 0)),
        Vertex(position:  simd_float4(1, -1, 0, 1), color: simd_float4(0.59, 0, 1, 0), texture: simd_float2(1, 0)),
        Vertex(position:  simd_float4(1, 1, 0, 1), color: simd_float4(-1, 1, 0, 0), texture: simd_float2(1,1)),
        
    ]
    var indicies: [UInt16] = [0, 1, 2,2, 3, 0]
    
    init(device: MTLDevice,
         view: MTKView,
         vertexFunctionName: String = "vertex_main",
         fragmentFunctionName: String = "fragment_main",
         kernelFunctionName: String? = nil
    ) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        self.view = view
        self.frameIndex = 0
        self.vertexFunctionName = vertexFunctionName
        self.fragmentFunctionName = fragmentFunctionName
        self.kernelFunctionName = kernelFunctionName
        super.init()
        
        view.device = device
        view.delegate = self
        view.clearColor = MTLClearColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
        
        makeResources()
        makePipeline()
        buildSamplerState()
    }
    
    private func buildSamplerState() {
        let descriptor = MTLSamplerDescriptor()
        descriptor.minFilter = .linear
        descriptor.magFilter = .linear
        sampleState = device.makeSamplerState(descriptor: descriptor)
    }
    
    private func makePipeline() {
        
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
        
        guard let vertexFunction = library.makeFunction(name: vertexFunctionName),
              let fragmentFunction = library.makeFunction(name: fragmentFunctionName)
        else {
            fatalError("Please add both vertex and fragment funciton")
        }
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        
        do {
            renderPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        } catch {
            fatalError("Error while creating render pipeline state: \(error)")
        }
    }
    
    private func makeResources() {
        vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Vertex>.size)
        indexBuffer = device.makeBuffer(bytes: indicies, length: indicies.count * MemoryLayout<UInt16>.size)
    }
    
    // MARK: - MTKViewDelegate
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    func draw(in view: MTKView) {
        frameSemaphore.wait()
        
        guard let renderPassDescriptor = view.currentRenderPassDescriptor,
              let indexBuffer = indexBuffer,
              let sampleState = sampleState
        else { return }
        
        let currentTime = CACurrentMediaTime()
        let timestep = currentTime - previousRenderElapsedTime
        
        var uniforms = Uniforms(resolution: SIMD2<Float>(Float(view.drawableSize.width),
                                                         Float(view.drawableSize.height)),
                                mouse: SIMD2<Float>(Float(touchPoint.x), Float(touchPoint.y)),
                                time: Float(renderingElapsedTime))
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        
        let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderCommandEncoder.setRenderPipelineState(renderPipelineState)
        renderCommandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderCommandEncoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 0)
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
        renderingElapsedTime += timestep
        previousRenderElapsedTime = currentTime
    }
}
