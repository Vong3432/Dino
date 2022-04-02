//
//  Meteorite.swift
//  Dino
//
//  Created by Vong Nyuksoon on 31/03/2022.
//

import Foundation
import SpriteKit

class Meteorite: SKSpriteNode {
    static let uniqueName = "Meteorite"
    
    func setup() {
        let texture = SKTexture(imageNamed: "flaming_meteor")
        zPosition = 2
        
        let randomSize = Int.random(in: 20...72)
        scale(to: CGSize(width: randomSize, height: randomSize))
        
        let body = SKPhysicsBody(circleOfRadius: texture.size().width / 2)
        body.affectedByGravity = true
        body.allowsRotation = false
        body.isDynamic = true
        body.restitution = 0
        
//        body.mass = 5 * 1010
        /**
         The categoryBitMask sets the category that the sprite belongs to, whereas the collisionBitMask sets the category with which the sprite can collide with and not pass-through them.

         For collision detection, you need to set the contactTestBitMask = collisionBitMask. Here, you set the categories of sprites with which you want the contact delegates to be called upon contact.
         */
        body.contactTestBitMask = PhysicsCategory.Dino
        body.categoryBitMask = PhysicsCategory.Meteorite
        body.collisionBitMask = PhysicsCategory.Dino
        
        physicsBody = body
        
        name = Meteorite.uniqueName
    }
    
    func fall(toward player: SKSpriteNode, parentFrame: CGRect) {
        
        let minX = frame.minX
        let maxX = frame.maxX
        let randomX = Double.random(in: minX...maxX)
        let center = CGPoint(x: frame.midX, y: frame.midY)
        let fallDirectionFactor = randomX < center.x ? 1.0 : -1.0
        
        // set the starting position of meteorite
//        position = CGPoint(x: randomX, y: parentFrame.maxY)
        position = CGPoint(x: randomX, y: parentFrame.maxY)
        
        // calculate angle
//        let angle = Double.random(in: 0...Double.pi * 2)
        let angle = Double.pi
        let magnitude:CGFloat = 20
        zRotation = angle - 90

        let dx = magnitude * cos(angle) * fallDirectionFactor
        let dy = magnitude * sin(angle) * fallDirectionFactor
        let vector = CGVector(dx: dx, dy: dy)
        
        physicsBody?.applyImpulse(vector)
    }
}

