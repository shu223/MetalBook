//
//  MetalRenderView.swift
//  ARMetalArgumentBuffers
//
//  Created by Shuichi Tsutsumi on 2017/09/25.
//  Copyright © 2017 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import MetalKit

class MetalRenderView: MTKView, MTKViewDelegate {

    private var commandQueue: MTLCommandQueue!
    private var sampler: MTLSamplerState!
    private var argEncoder: MTLArgumentEncoder!

    internal var textureLoader: MTKTextureLoader!
    
    private let vertexData: [Float] = [
        -1, -1, 0, 1,
        1, -1, 0, 1,
        -1,  1, 0, 1,
        1,  1, 0, 1
    ]
    private lazy var vertexBuffer: MTLBuffer? = {
        let size = vertexData.count * MemoryLayout<Float>.size
        return makeBuffer(bytes: vertexData, length: size)
    }()
    
    private let textureCoordinateData: [Float] = [
        0, 1,
        1, 1,
        0, 0,
        1, 0
    ]
    private lazy var texCoordBuffer: MTLBuffer? = {
        let size = textureCoordinateData.count * MemoryLayout<Float>.size
        return makeBuffer(bytes: textureCoordinateData, length: size)
    }()
    

    private var cameraTexture: MTLTexture?
    private var snapshotTexture: MTLTexture?
    private var argBuffer: MTLBuffer?
    var time: Float = 0

    private var renderDescriptor: MTLRenderPipelineDescriptor?
    private var renderPipeline: MTLRenderPipelineState?
    
    
    init(frame frameRect: CGRect) {
        guard let device = MTLCreateSystemDefaultDevice() else {fatalError()}
        super.init(frame: frameRect, device: device)
        commonInit()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        guard let device = MTLCreateSystemDefaultDevice() else {fatalError()}
        self.device = device
        commonInit()
    }
    
    private func commonInit() {
        guard let device = device else {fatalError()}
        commandQueue = device.makeCommandQueue()
        textureLoader = MTKTextureLoader(device: device)

        guard let library = device.makeDefaultLibrary() else {fatalError()}
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "vertexShader")
        descriptor.fragmentFunction = library.makeFunction(name: "fragmentShader")
        renderDescriptor = descriptor

        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.supportArgumentBuffers = true
        sampler = device.makeSamplerState(descriptor: samplerDescriptor)!
        
        guard let fragmentFunction = renderDescriptor?.fragmentFunction else {return}
        // インデックスを間違えると、
        // > failed assertion `Function fragmentShader does not have a buffer argument with buffer index 1'
        argEncoder = fragmentFunction.makeArgumentEncoder(bufferIndex: 0)
        
        argBuffer = device.makeBuffer(length: argEncoder.encodedLength, options: [])
        guard let argBuffer = argBuffer else {fatalError()}
        argEncoder.setArgumentBuffer(argBuffer, offset: 0)

        framebufferOnly = false
        enableSetNeedsDisplay = true
        isPaused = true
        delegate = self
    }
    
    // MARK: - Private
    
    func makeBuffer(bytes: UnsafeRawPointer, length: Int) -> MTLBuffer {
        guard let device = device else {fatalError()}
        return device.makeBuffer(bytes: bytes, length: length, options: [])!
    }
    
    // MARK: - MTKViewDelegate
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        print("\(self.classForCoder)/" + #function)
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable else {return}
        guard let renderPipeline = renderPipeline else {return}
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {fatalError()}
        
        guard let renderPassDescriptor = currentRenderPassDescriptor else {return}
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {return}
        
        renderEncoder.setRenderPipelineState(renderPipeline)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(texCoordBuffer, offset: 0, index: 1)
        
        renderEncoder.setFragmentBuffer(argBuffer, offset: 0, index: 0)
        
        // これをやらないと、
        // > Execution of the command buffer was aborted due to an error during execution. Caused GPU Hang Error (IOAF code 3)
        if let texture = snapshotTexture {
            renderEncoder.useResource(texture, usage: .sample)
        }
        if let texture = cameraTexture {
            renderEncoder.useResource(texture, usage: .sample)
        }
        
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
    
    internal func registerTexturesFor(cameraImage: CGImage, snapshotImage: CGImage) {
        cameraTexture = try? self.textureLoader.newTexture(cgImage: cameraImage)
        snapshotTexture = try? self.textureLoader.newTexture(cgImage: snapshotImage)

        guard let argEncoder = argEncoder else {fatalError()}
        
        argEncoder.setTexture(snapshotTexture, index: 0)
        argEncoder.setTexture(cameraTexture, index: 1)
        argEncoder.setSamplerState(sampler, index: 2)
        argEncoder.constantData(at: 3).storeBytes(of: time, as: Float.self)
        
        if renderPipeline == nil, let texture = snapshotTexture {
            guard let descriptor = renderDescriptor else {return}
            guard let device = device else {fatalError()}
            descriptor.colorAttachments[0].pixelFormat = texture.pixelFormat
            renderPipeline = try? device.makeRenderPipelineState(descriptor: descriptor)
        }
        
        setNeedsDisplay()
    }
}

