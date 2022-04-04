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

struct PhysicsCategory {
    static let All: UInt32 = UInt32.max
    static let Block: UInt32 = 0b1
    static let Dino: UInt32 = 0b01
    static let Meteorite: UInt32 = 0b11
    static let None: UInt32 = 0
}

enum GameState {
    case showingLogo
    case playing
    case dead
    case pause
    case end
}

class GameScene: SKScene {
    
    // MARK: - Game States
    var logo: SKSpriteNode!
    var gameOver: SKSpriteNode!
    var gameState = GameState.showingLogo
    var currentHealth: Int = 0
    
    let maxHealthPerRound = 3
    let timerPerRound = 60
    var collidedMeteorite = [SKNode]()
    
    private var timer = 60 {
        didSet {
            self.timerLabel.text = "\(self.timer)"
        }
    }
    
    // MARK: - FPS
    var lastUpdateTime: TimeInterval = 0
    var fpsLabel = SKLabelNode(text: "FPS: 0")
    
    private let motionManager = CMMotionManager()
    
    // MARK: - Screen objects
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
    
    
    // MARK: - bgm & effects
    var background = SKSpriteNode(imageNamed: "bg")
    var backgroundMusic: SKAudioNode!
    
    // MARK: - Delegates
    override func didMove(to view: SKView) {
        createLogos()
        physicsWorld.contactDelegate = self
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
            dino.jump()
            break
        case .dead:
            break
        case .pause:
            break
        case .end:
            toHomeScene()
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

// MARK: - Contact delegate
extension GameScene: SKPhysicsContactDelegate {
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }
        
        if nodeA.name == Meteorite.uniqueName && nodeA.position.y < frame.midY || nodeB.name == Dino.uniqueName {
            explore(meteorite: nodeA)
        }
        if nodeB.name == Meteorite.uniqueName && nodeB.position.y < frame.midY || nodeA.name == Dino.uniqueName {
            explore(meteorite: nodeB)
        }
        
        if nodeA.name == Meteorite.uniqueName && nodeB.name == Dino.uniqueName {
            collisionBetween(dino: nodeB, meteorite: nodeA)
        } else if nodeB.name == Meteorite.uniqueName && nodeA.name == Dino.uniqueName {
            collisionBetween(dino: nodeA, meteorite: nodeB)
        }
        
    }
    
    func collisionBetween(dino: SKNode, meteorite: SKNode) {
        currentHealth -= 1
        drawHealth()
    }
    
    func explore(meteorite: SKNode) {
        
        guard collidedMeteorite.contains(meteorite) == false else {
            return
        }
        
        collidedMeteorite.append(meteorite)
        
        let explosionTexture = SKTexture(imageNamed: "explosion")
        let action = SKAction.setTexture(explosionTexture)
        
        let wait = SKAction.wait(forDuration: 1)
        let seq = SKAction.sequence([action, wait, SKAction.removeFromParent()])
        
        meteorite.run(seq)
    }
}

extension GameScene {
    
    // MARK: - Player movement handlers
    func handleDeviceMovement() {
        guard let data = motionManager.accelerometerData else { return }
        
        let dy = data.acceleration.x * 0
        let dx = data.acceleration.y * -1000
        
//        physicsWorld.gravity = CGVector(dx: dx, dy: dy)
        dino.move(with: CGVector(dx: dx, dy: dy))
    }
    
    // MARK: - Game states handlers
    func reset() {
        collidedMeteorite = []
        currentHealth = maxHealthPerRound
        timer = timerPerRound
        clear()
        motionManager.stopAccelerometerUpdates()
    }
    
    func clear() {
        removeAllActions()
        removeAllChildren()
        
        directionCircle.setScale(1.0)
        meteoriteGenerator.removeAllActions()
    }
    
    func pause() {
        motionManager.stopAccelerometerUpdates()
    }
    
    func toHomeScene() {
        pause()
        clear()
        
        logo = SKSpriteNode(imageNamed: "logo")
        logo.position = CGPoint(x: frame.midX, y: frame.midY)
        logo.alpha = 1
        
        addChild(logo)
        
        gameOver.alpha = 0
        gameState = .showingLogo
        playBGM("home", type: "wav")
    }
    
    
    // MARK: - UI generation handlers
    func setupGameScene() {
        // transform the frame of scene into wall by providing physicsBody so that dino will not fall outside of the view
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        self.physicsBody?.categoryBitMask = PhysicsCategory.Block
        self.physicsBody?.collisionBitMask = PhysicsCategory.Block
        
        fpsLabel.position = CGPoint(x: size.width / 10, y: size.height / 10)
        fpsLabel.zPosition = 2
        fpsLabel.fontSize = 21
        
        // minus 52 because (32+20, fontSize + padding)
        timerLabel.position = CGPoint(x: frame.maxX - 52, y: frame.maxY - 52)
        
        timerLabel.fontSize = 32
        timerLabel.fontName = "HelveticaNeue-Bold"
        timerLabel.zPosition = 2
        
        drawHealth()
        
        addChild(fpsLabel)
        addChild(timerLabel)
        
        updateTimer()
    }
    
    func drawHealth() {
        
        guard currentHealth > 0 else {
            self.toHomeScene()
            return
        }
        
        let screenPadding = 20.0
        let screenCgPoint = CGPoint(x: frame.minX + screenPadding, y: frame.maxY - screenPadding)
        let healthSize = CGSize(width: 32, height: 32)
        var count = 1.0
        
        // clear
        for child in children {
            if child.name == Heart.FILLED || child.name == Heart.EMPTY {
                child.removeFromParent()
            }
        }
        
        for _ in 0..<currentHealth {
            let heart = SKSpriteNode(imageNamed: "heart_fill")
            heart.name = Heart.FILLED
            heart.size = healthSize
            heart.zPosition = 2
            heart.position = CGPoint(x: (screenCgPoint.x * count * 1.25) + screenPadding, y: screenCgPoint.y - screenPadding)
            count += 1.0
            
            addChild(heart)
        }
        
        for _ in Int(count)..<maxHealthPerRound + 1 {
            let heart = SKSpriteNode(imageNamed: "heart_empty")
            heart.name = Heart.EMPTY
            heart.size = healthSize
            heart.zPosition = 2
            heart.position = CGPoint(x: (screenCgPoint.x * count * 1.25) + screenPadding, y: screenCgPoint.y - screenPadding)
            count += 1.0
            
            addChild(heart)
        }
    }
    
    func setupBg(_ view: SKView) {
        // config background
        background.zPosition = 1
        background.size = view.frame.size
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        
        addChild(background)
    }
    
    func setupDino() {
        dino = Dino(texture: nil, color: .black, size: .zero)
        dino.position = CGPoint(x: frame.midX, y: frame.minY)
        
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
    
    // MARK: - Utilities
    func updateFPS(_ currentTime: TimeInterval) {
        // update FPS
        let deltaTime = currentTime - lastUpdateTime
        let currentFPS = 1 / deltaTime
        
        fpsLabel.text = "FPS: \(currentFPS.formatted())"
        lastUpdateTime = currentTime
    }
    
    func updateTimer() {
        // 1 wait action
        let wait1Second = SKAction.wait(forDuration: 1)
        // 2 decrement action
        let decrementTimer = SKAction.run { [weak self] in
            guard let self = self else { return }
            guard self.timer > 0 else {
                self.toHomeScene()
                return
            }
            
            self.timer -= 1
        }
        // 3. wait + decrement
        let sequence = SKAction.sequence([wait1Second, decrementTimer])
        // 4. (wait + decrement) forever
        let repeatForever = SKAction.repeatForever(sequence)
        
        // run it!
        self.run(repeatForever)
    }
    
    // MARK: - BGM and effects
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
    
    // MARK: - Spawner method for the meteorites
    func spawn(_ view: SKView) {
        let wait = SKAction.wait(forDuration: 0.6, withRange: 0.1)
        let spawn = SKAction.run({self.generateMeteorite()})
        
        let sequence = SKAction.sequence([wait, spawn])
        meteoriteGenerator.run(SKAction.repeatForever(sequence))
        addChild(meteoriteGenerator)
    }
    
    // MARK: - Method that creates meteorite
    func generateMeteorite() {
        // creating meteorite object
        meteorite = Meteorite(imageNamed: "flaming_meteor")
        meteorite.setup()
        
        addChild(meteorite)
        
        meteorite.fall(toward: dino, parentFrame: frame)
    }
}
