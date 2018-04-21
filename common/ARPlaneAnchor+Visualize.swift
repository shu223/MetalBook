//
//  ARPlaneAnchor+Visualize.swift
//
//  Created by Shuichi Tsutsumi on 2017/08/29.
//  Copyright © 2017 Shuichi Tsutsumi. All rights reserved.
//

import Foundation
import ARKit

extension ARPlaneAnchor {
    
    func addPlaneNode(on node: SCNNode) -> SCNNode {
        // 平面ジオメトリを作成
        let geometry = SCNPlane(width: CGFloat(extent.x), height: CGFloat(extent.z))

        // 平面ジオメトリを持つノードを作成
        let planeNode = SCNNode(geometry: geometry)
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, 1, 0, 0)
        
        DispatchQueue.main.async(execute: {
            node.addChildNode(planeNode)
        })
        
        return planeNode
    }
    
    func findPlaneNode(on node: SCNNode) -> SCNNode? {
        for childNode in node.childNodes {
            if childNode.geometry as? SCNPlane != nil {
                return childNode
            }
        }
        return nil
    }
    
    func updatePlaneNode(on node: SCNNode) {
        DispatchQueue.main.async(execute: {
            guard let plane = self.findPlaneNode(on: node)?.geometry as? SCNPlane else {return}
            guard !PlaneSizeEqualToExtent(plane: plane, extent: self.extent) else {return}

            // 平面ジオメトリのサイズを更新
            print("current plane size: (\(plane.width), \(plane.height))")
            plane.width = CGFloat(self.extent.x)
            plane.height = CGFloat(self.extent.z)
            print("updated plane size: (\(plane.width), \(plane.height))")
        })
    }
}

fileprivate func PlaneSizeEqualToExtent(plane: SCNPlane, extent: vector_float3) -> Bool {
    if plane.width != CGFloat(extent.x) || plane.height != CGFloat(extent.z) {
        return false
    } else {
        return true
    }
}
