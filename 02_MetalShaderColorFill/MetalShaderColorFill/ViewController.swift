//
//  ViewController.swift
//  MetalShaderColorFill
//
//  Created by Shuichi Tsutsumi on 2017/09/10.
//  Copyright © 2017 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import MetalKit

class ViewController: UIViewController, MTKViewDelegate {

    private let device = MTLCreateSystemDefaultDevice()!
    private var commandQueue: MTLCommandQueue!

    private let vertexData: [Float] = [
        -1, -1, 0, 1,
         1, -1, 0, 1,
        -1,  1, 0, 1,
         1,  1, 0, 1
    ]
    private var vertexBuffer: MTLBuffer!
    private var renderPipeline: MTLRenderPipelineState!
    private let renderPassDescriptor = MTLRenderPassDescriptor()

    @IBOutlet private weak var mtkView: MTKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Metalのセットアップ
        setupMetal()

        //
        makeBuffers()
        
        //
        makePipeline()
        
        //
        mtkView.enableSetNeedsDisplay = true

        // ビューの更新依頼 → draw(in:)が呼ばれる
        mtkView.setNeedsDisplay()
    }

    private func setupMetal() {
        // MTLCommandQueueを初期化
        commandQueue = device.makeCommandQueue()
        
        // MTKViewのセットアップ
        mtkView.device = device
        mtkView.delegate = self
    }

    private func makeBuffers() {
        let size = vertexData.count * MemoryLayout<Float>.size
        vertexBuffer = device.makeBuffer(bytes: vertexData, length: size)
    }
    
    private func makePipeline() {
        guard let library = device.makeDefaultLibrary() else {fatalError()}
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "vertexShader")
        descriptor.fragmentFunction = library.makeFunction(name: "fragmentShader")
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        renderPipeline = try! device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    // MARK: - MTKViewDelegate
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        print("\(self.classForCoder)/" + #function)
    }
    
    func draw(in view: MTKView) {
        // ドローアブルを取得
        guard let drawable = view.currentDrawable else {return}

        // コマンドバッファを作成
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {fatalError()}

        //
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        
        // エンコーダ生成
        let renderEncoder =
            commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

        guard let renderPipeline = renderPipeline else {fatalError()}
        renderEncoder.setRenderPipelineState(renderPipeline)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)

        // エンコード完了
        renderEncoder.endEncoding()

        // 表示するドローアブルを登録
        commandBuffer.present(drawable)
        
        // コマンドバッファをコミット（エンキュー）
        commandBuffer.commit()
        
        // 完了まで待つ
        commandBuffer.waitUntilCompleted()
    }
}

