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
        body.isDynamic = false
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
        
        // set initial x position
        let minX = parentFrame.minX
        let maxX = parentFrame.maxX
        position = CGPoint(x: Double.random(in: minX...maxX), y: parentFrame.maxY)
        
        //        print(position.x)
        let angle = findAngle(targetPosition: player.position)
        zRotation = angle + (.pi / 2)
        
        let radius = hypot(player.position.x - position.x, player.position.y - position.y)
        let x = radius * cos(angle)
        let y = radius * sin(angle)
        
//        print(angle)
        
        let move = SKAction.moveBy(x: x, y: y, duration: 1)
        let wait = SKAction.wait(forDuration: 5)
        let remove = SKAction.removeFromParent()
        let repeatForever = SKAction.repeatForever(move)
        
        let sequence = SKAction.sequence([repeatForever, wait, remove])
        
        run(sequence)
    }
    
    private func findAngle(targetPosition: CGPoint) -> Double {
        let angle = atan2(targetPosition.y - position.y, targetPosition.x - position.x)
        return angle
    }
}

