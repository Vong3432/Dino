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
    case pause
    case end
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // game states
    var logo: SKSpriteNode!
    var gameOver: SKSpriteNode!
    var gameState = GameState.showingLogo

    private var timer = 60 {
        didSet {
            self.timerLabel.text = "\(self.timer)"
        }
    }
    
    // fps
    var lastUpdateTime: TimeInterval = 0
    var fpsLabel = SKLabelNode(text: "FPS: 0")
    
    private let motionManager = CMMotionManager()
    
    // screen objects
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
    let meteoriteGenerator = SKNode()
    var dino: Dino!
    var meteorite: Meteorite!
    var directionCircle = SKShapeNode(circleOfRadius: 5)
    var timerLabel = SKLabelNode(text: "60")
    
    // bgm & effects
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
            reset()
            
            // change to playing state
            gameState = .playing
            
            guard let view = view else { return }
            startGameScene(view)
            
            let fadeOut = SKAction.fadeOut(withDuration: 0.5)
            let remove = SKAction.removeFromParent()
            let wait = SKAction.wait(forDuration: 0.5)
            
            let sequence = SKAction.sequence([fadeOut, wait, remove])
            logo.run(sequence)
        case .playing:
            guard let view = view else { return }
            dino.jump()
            break
        case .dead:
            break
        case .pause:
            break
        case .end:
            gameOver.alpha = 1
            gameState = .end
            playBGM("home", type: "wav")
            break
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        updateFPS(currentTime)
        handleDeviceMovement()
    }
    
}

extension GameScene {
    func updateFPS(_ currentTime: TimeInterval) {
        // update FPS
        let deltaTime = currentTime - lastUpdateTime
        let currentFPS = 1 / deltaTime
        
        fpsLabel.text = "FPS: \(currentFPS.formatted())"
        lastUpdateTime = currentTime
    }
    
    func updateTimer() {
        print(timer)
        // update timer
        if timer > 0 && gameState == .playing { timer -= 1 }
        else if timer == 0 && gameState == .playing {
            // if player have survived for 60 seconds
            gameState = .end
        }
    }
    
    func handleDeviceMovement() {
        guard let data = motionManager.accelerometerData else { return }
        
        if UIDevice.current.orientation == UIDeviceOrientation.landscapeLeft {
            // switch side
            //            dino.xScale = dino.xScale * -1
            dino.move(with: CGVector(dx: 100 * CGFloat(data.acceleration.y), dy: 0))
            
        } else if UIDevice.current.orientation == UIDeviceOrientation.landscapeRight {
            //            dino.xScale = dino.xScale * 1
            dino.move(with: CGVector(dx: -100 * CGFloat(data.acceleration.y), dy: 0))
        }
        
        if UIDevice.current.orientation == .faceUp {
            dino.jump()
        }
    }
    
    func reset() {
        timer = 60
        removeAllChildren()
        removeAllActions()
        motionManager.stopAccelerometerUpdates()
    }
    
    func pause() {
        motionManager.stopAccelerometerUpdates()
    }
    
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
        if motionManager.isAccelerometerAvailable {
            motionManager.startAccelerometerUpdates()
        }
        
        setupGameScene()
        setupBg(view)
        playBGM("bgm")
        setupDirectionCircle()
        setupDino()
        spawn(view)
    }
    
    func setupGameScene() {
        // transform the frame of scene into wall by providing physicsBody so that dino will not fall outside of the view
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        
        fpsLabel.position = CGPoint(x: size.width / 10, y: size.height / 10)
        fpsLabel.zPosition = 2
        fpsLabel.fontSize = 21
        
        // minus 52 because (32+20, fontSize + padding)
        timerLabel.position = CGPoint(x: frame.maxX - 52, y: frame.maxY - 52)
        
        timerLabel.fontSize = 32
        timerLabel.fontName = "HelveticaNeue-Bold"
        timerLabel.zPosition = 2
        
        addChild(fpsLabel)
        addChild(timerLabel)
        
        // 1 wait action
        let wait1Second = SKAction.wait(forDuration: 1)
        // 2 decrement action
        let decrementTimer = SKAction.run { [weak self] in
            self?.timer -= 1
        }
        // 3. wait + decrement
        let sequence = SKAction.sequence([wait1Second, decrementTimer])
        // 4. (wait + decrement) forever
        let repeatForever = SKAction.repeatForever(sequence)

        // run it!
        self.run(repeatForever)
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
        dino = Dino(texture: nil, color: .black, size: .zero)
        dino.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(dino)
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
    
    /// Spawner method for the meteorites
    func spawn(_ view: SKView) {
        let wait = SKAction.wait(forDuration: 1, withRange: 0.4)
        let spawn = SKAction.run({self.generateMeteorite()})
        
        let sequence = SKAction.sequence([wait, spawn])
        meteoriteGenerator.run(SKAction.repeatForever(sequence))
        addChild(meteoriteGenerator)
    }
    
    /// Method that creates meteorite
    func generateMeteorite() {
        // creating meteorite object
        meteorite = Meteorite(imageNamed: "flaming_meteor")
        meteorite.setup()
        meteorite.position = CGPoint(x: frame.maxX, y: frame.maxY)
        
        addChild(meteorite)
        
        // configure where to spawn and the angle to fall onto the ground
        guard let meteorite = meteorite else { return }
        let center = CGPoint(x: frame.midX, y: frame.midY)
        let v1 = CGVector(dx: dino.position.x - center.x, dy: dino.position.y - center.y)
        let v2 = CGVector(dx: meteorite.position.x - center.x, dy: meteorite.position.y - center.y)
        let angle = atan2(v2.dy, v2.dx) - atan2(v1.dy, v1.dx)
        //  let angle = cos(Double.pi)
        let vector = CGVector(dx: -10 * cos(angle * Double.pi / 180), dy: 0)
        
        meteorite.physicsBody?.applyImpulse(vector)
        
        // remove after 2s
        let wait = SKAction.wait(forDuration: 2)
        let seq = SKAction.sequence([wait, SKAction.removeFromParent()])
        meteorite.run(seq)
    }
}
