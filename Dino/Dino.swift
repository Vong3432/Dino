//
//  Dino.swift
//  Dino
//
//  Created by Vong Nyuksoon on 31/03/2022.
//

import Foundation
import SpriteKit


class Dino: SKSpriteNode {
    static let uniqueName = "Dino"
    
    fileprivate let frames: [SKTexture] = {
        let sheet = SpriteSheet(texture: SKTexture(imageNamed: "Dino"), rows: 1, columns: 24, spacing: 3, margin: 0)
        
        var frames = [SKTexture]()
        for column in 0..<24 {
            guard column >= (24-7) else { continue }
            
            if let texture = sheet.textureForColumn(column: column, row: 0) {
                frames.append(texture)
            }
        }
        
        return frames
    }()
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: frames.first, color: color, size: size)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        let openingAnimation: SKAction = SKAction.animate(with: frames, timePerFrame: 0.1, resize: false, restore: true)
        
        // config dino
        size = CGSize(width: 52, height: 52)
        zPosition = 2000
        
        physicsBody = SKPhysicsBody(circleOfRadius: self.size.width / 2)
        physicsBody?.allowsRotation = false
        physicsBody?.restitution = 0.2
        
        name = Dino.uniqueName
        
        /**
         The categoryBitMask sets the category that the sprite belongs to, whereas the collisionBitMask sets the category with which the sprite can collide with and not pass-through them.

         For collision detection, you need to set the contactTestBitMask = collisionBitMask. Here, you set the categories of sprites with which you want the contact delegates to be called upon contact.
         */
        physicsBody?.contactTestBitMask = PhysicsCategory.Meteorite
        physicsBody?.categoryBitMask = PhysicsCategory.Dino
        physicsBody?.collisionBitMask = PhysicsCategory.Meteorite
        physicsBody?.usesPreciseCollisionDetection = true
        
        // animate sprite
        run(SKAction.repeatForever(openingAnimation))
    }
    
    /// called in update(:) from GameScene
    func move(with vector: CGVector) {
        physicsBody?.applyForce(vector)
    }
    
    func jump() {
        physicsBody?.applyImpulse(CGVector(dx: 0, dy: 10))
    }
}
