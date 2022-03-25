//
//  GameScene.swift
//  Dino
//
//  Created by Vong Nyuksoon on 25/03/2022.
//

import Foundation
import SpriteKit
import CoreMotion
import SwiftUI

enum GameState {
    case showingLogo
    case playing
    case dead
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // game states
    var logo: SKSpriteNode!
    var gameOver: SKSpriteNode!
    var gameState = GameState.showingLogo
    
    // fps
    var lastUpdateTime: TimeInterval = 0
    var fpsLabel = SKLabelNode(text: "FPS: 0")
    
    private let motionManager = CMMotionManager()
    
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
    
    var dino: SKSpriteNode!
    var directionCircle = SKShapeNode(circleOfRadius: 5)
    var background = SKSpriteNode(imageNamed: "bg")
    var backgroundMusic: SKAudioNode!
    
    override func didMove(to view: SKView) {
        createLogos()
    }

    func didBegin(_ contact: SKPhysicsContact) {
        gameOver.alpha = 1
        gameState = .dead
        playBGM("home", type: "wav")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch gameState {
        case .showingLogo:
            gameState = .playing
            
            let fadeOut = SKAction.fadeOut(withDuration: 0.5)
            let remove = SKAction.removeFromParent()
            let wait = SKAction.wait(forDuration: 0.5)
            
            let sequence = SKAction.sequence([fadeOut, wait, remove])
            logo.run(sequence)
        case .playing:
            guard let view = view else { return }
            startGameScene(view)
        case .dead:
            
            break
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        let deltaTime = currentTime - lastUpdateTime
        let currentFPS = 1 / deltaTime
        
        fpsLabel.text = "FPS: \(currentFPS.formatted())"
        
        lastUpdateTime = currentTime
        
        guard let data = motionManager.accelerometerData else { return }
        
        
        if UIDevice.current.orientation == UIDeviceOrientation.landscapeLeft {
            // switch side
            dino.xScale = dino.xScale * -1
            dino.physicsBody?.applyForce(CGVector(dx: 100 * CGFloat(data.acceleration.y), dy: 0))
            
        } else {
            dino.xScale = dino.xScale * 1
            dino.physicsBody?.applyForce(CGVector(dx: -100 * CGFloat(data.acceleration.y), dy: 0))
            
        }
        
    }
    
    
}

extension GameScene {
    func createLogos() {
        logo = SKSpriteNode(imageNamed: "logo")
        logo.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(logo)
        
        gameOver = SKSpriteNode(imageNamed: "gameover")
        gameOver.position = CGPoint(x: frame.midX, y: frame.midY)
        gameOver.alpha = 0
        addChild(gameOver)
        
        playBGM("home", type: "wav")
    }
    
    func startGameScene(_ view: SKView) {
        motionManager.startAccelerometerUpdates()
        
        setupGameScene()
        setupBg(view)
        playBGM("bgm")
        setupDirectionCircle()
        setupDino()
    }
    
    func setupGameScene() {
        // transform the frame of scene into wall by providing physicsBody so that dino will not fall outside of the view
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        
        fpsLabel.position = CGPoint(x: size.width / 10, y: size.height / 10)
        fpsLabel.zPosition = 2
        fpsLabel.fontSize = 12
        
        addChild(fpsLabel)
    }
    
    func setupBg(_ view: SKView) {
        // config background
        background.zPosition = 1
        background.size = view.frame.size
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        
        addChild(background)
    }
    
    func playBGM(_ name: String, type: String = "mp3") {
        // remove previous bgm if exist
        if backgroundMusic != nil {
            backgroundMusic.removeFromParent()
        }
        
        if let musicURL = Bundle.main.url(forResource: name, withExtension: type) {
            backgroundMusic = SKAudioNode(url: musicURL)
            addChild(backgroundMusic)
        }
    }
    
    func setupDino() {
        dino = SKSpriteNode(texture: frames.first)
        let openingAnimation: SKAction = SKAction.animate(with: frames, timePerFrame: 0.1, resize: false, restore: true)
        
        // config dino
        dino.size = CGSize(width: 52, height: 52)
        dino.position = CGPoint(x: frame.midX, y: frame.midY)
        dino.zPosition = 2000
        
        // add to scene
        addChild(dino)
        
        dino.physicsBody = SKPhysicsBody(circleOfRadius: dino.size.width / 2)
        dino.physicsBody?.allowsRotation = false
        dino.physicsBody?.restitution = 0.2
        
        // animate sprite
        dino.run(SKAction.repeatForever(openingAnimation))
    }
    
    func setupDirectionCircle() {
        directionCircle.zPosition = 2.0
        directionCircle.position = CGPoint(x: self.frame.midX, y: self.frame.maxY - 40)  //Middle of Screen
        directionCircle.fillColor = SKColor.white
        directionCircle.strokeColor = SKColor.black
        
        let delayAction = SKAction.wait(forDuration: TimeInterval(1)) // delay 2s
        let scaleUpAction = SKAction.scale(by: 2, duration: 1)
        let actionSequences = SKAction.sequence([delayAction, scaleUpAction])
        
        addChild(directionCircle)
        directionCircle.run(actionSequences)
    }
}
