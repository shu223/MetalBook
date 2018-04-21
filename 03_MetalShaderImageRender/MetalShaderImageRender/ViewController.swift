//
//  ViewController.swift
//  MetalShaderImageRender
//
//  Created by Shuichi Tsutsumi on 2017/09/10.
//  Copyright © 2017 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import MetalKit

let vertexData: [Float] = [-1, -1, 0, 1,
                            1, -1, 0, 1,
                           -1,  1, 0, 1,
                            1,  1, 0, 1]

let textureCoordinateData: [Float] = [0, 1,
                                      1, 1,
                                      0, 0,
                                      1, 0]

class ViewController: UIViewController, MTKViewDelegate {

    private let device = MTLCreateSystemDefaultDevice()!
    private var commandQueue: MTLCommandQueue!
    private var texture: MTLTexture!

    private var vertexBuffer: MTLBuffer!
    private var texCoordBuffer: MTLBuffer!
    private var renderPipeline: MTLRenderPipelineState!
    private let renderPassDescriptor = MTLRenderPassDescriptor()

    @IBOutlet private weak var mtkView: MTKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Metalのセットアップ
        setupMetal()

        // 画像をテクスチャとしてロード
        loadTexture()

        //
        makeBuffers()
        
        //
        makePipeline(pixelFormat: texture.pixelFormat)
        
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
        var size: Int
        size = vertexData.count * MemoryLayout<Float>.size
        vertexBuffer = device.makeBuffer(bytes: vertexData, length: size, options: [])
        
        size = textureCoordinateData.count * MemoryLayout<Float>.size
        texCoordBuffer = device.makeBuffer(bytes: textureCoordinateData, length: size, options: [])
    }
    
    private func makePipeline(pixelFormat: MTLPixelFormat) {
        guard let library = device.makeDefaultLibrary() else {fatalError()}
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "vertexShader")
        descriptor.fragmentFunction = library.makeFunction(name: "fragmentShader")
        descriptor.colorAttachments[0].pixelFormat = pixelFormat
        renderPipeline = try! device.makeRenderPipelineState(descriptor: descriptor)
    }

    private func loadTexture() {
        // MTKTextureLoaderを初期化
        let textureLoader = MTKTextureLoader(device: device)
        // テクスチャをロード
        texture = try! textureLoader.newTexture(
            name: "highsierra",
            scaleFactor: view.contentScaleFactor,
            bundle: nil)
        
        // ピクセルフォーマットを合わせる
        mtkView.colorPixelFormat = texture.pixelFormat
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
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {return}

        guard let renderPipeline = renderPipeline else {fatalError()}
        renderEncoder.setRenderPipelineState(renderPipeline)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(texCoordBuffer, offset: 0, index: 1)
        renderEncoder.setFragmentTexture(texture, index: 0)
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

