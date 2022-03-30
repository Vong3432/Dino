//
//  Meteorite.swift
//  Dino
//
//  Created by Vong Nyuksoon on 31/03/2022.
//

import Foundation
import SpriteKit

class Meteorite: SKSpriteNode {
    func setup() {
        let texture = SKTexture(imageNamed: "flaming_meteor")
        zPosition = 2
        
        let body = SKPhysicsBody(circleOfRadius: texture.size().width / 2)
        body.affectedByGravity = true
        body.allowsRotation = false
        body.isDynamic = true
        body.restitution = 0.2
//        body.mass = 5 * 1010
        //        body.categoryBitMask = obstacleCategory
        //        body.collisionBitMask = floorCategory
        //        body.contactTestBitMask = heroCategory
        
        
        physicsBody = body
        name = "Meteorite"
        
//        let pA = CGPoint(x: frame.midX, y: frame.maxY)
//        let pB = CGPoint(x: frame.minX, y: frame.midY)
//        let vector = CGVector(dx: pB.x - pA.x, dy: pB.y - pA.y)
        
       
        //        let moveLeft = SKAction.moveBy(x: -scene!.size.width - obstacle.size.width - 10, y: 0, duration: 2)
        //        let move = SKAction.move
        
    }
}

