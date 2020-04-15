//
//  GameScene.swift
//  SCNFrogger
//
//  Created by Kim Pedersen on 02/12/14.
//  Copyright (c) 2014 RWDevCon. All rights reserved.
//

import SceneKit
import SpriteKit


class GameScene : SCNScene, SCNSceneRendererDelegate, SCNPhysicsContactDelegate, GameLevelSpawnDelegate {
    
    // MARK: Properties
    var sceneView: SCNView!
    var gameState = GameState.WaitingForFirstTap
    
    var camera: SCNNode!
    var cameraOrthographicScale = 0.5
    var cameraOffsetFromPlayer = SCNVector3(x: 0.25, y: 1.25, z: 0.55)
    
    var levelData: GameLevel!
    let levelWidth: Int = 19
    let levelHeight: Int = 50
    
    var player: SCNNode!
    let playerScene = SCNScene(named: "assets.scnassets/Models/frog.dae")
    var playerGridCol = 7
    var playerGridRow = 6
    var playerChildNode: SCNNode!
    
    let carScene = SCNScene(named: "assets.scnassets/Models/car.dae")
    
    
    // MARK: Init
    init(view: SCNView) {
        
        sceneView = view
        super.init()
        self.physicsWorld.contactDelegate = self
        view.delegate = self
        
        initializeLevel()
    }
    
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    
    func initializeLevel() {
        setupGestureRecognizersForView(view: sceneView)
        setupLights()
        setupLevel()
        setupPlayer()
        setupCamera()
        switchToWaitingForFirstTap()
    }
    
    
    func setupPlayer() {
        player = SCNNode()
        player.name = "Player"
        player.position = levelData.coordinatesForGridPosition(column: playerGridCol, row: playerGridRow)
        player.position.y = 0.2
        
        let playerMaterial = SCNMaterial()
        playerMaterial.diffuse.contents = UIImage(named: "assets.scnassets/Textures/model_texture.tga")
        playerMaterial.locksAmbientWithDiffuse = false
        
        playerChildNode = playerScene!.rootNode.childNode(withName: "Frog", recursively: false)!
        playerChildNode.geometry!.firstMaterial = playerMaterial
        playerChildNode.position = SCNVector3(x: 0.0, y: 0.0, z: 0.075)
        
        player.addChildNode(playerChildNode)
        
        // Create a physicsbody for collision detection
        let playerPhysicsBodyShape = SCNPhysicsShape(geometry: SCNBox(width: 0.08, height: 0.08, length: 0.08, chamferRadius: 0.0), options: nil)
        
        playerChildNode.physicsBody = SCNPhysicsBody(type: SCNPhysicsBodyType.kinematic, shape: playerPhysicsBodyShape)
        playerChildNode.physicsBody!.categoryBitMask = PhysicsCategory.Player
        playerChildNode.physicsBody!.collisionBitMask = PhysicsCategory.Car
        if #available(iOS 9.0, *) {
            playerChildNode.physicsBody!.contactTestBitMask = PhysicsCategory.Car
        } else {
            // Fallback on earlier versions
        }
        
        //        player.physicsBody = SCNPhysicsBody(type: SCNPhysicsBodyType.kinematic, shape: playerPhysicsBodyShape)
        //        player.physicsBody!.categoryBitMask = PhysicsCategory.Player
        //        player.physicsBody!.collisionBitMask = PhysicsCategory.Car
        
        rootNode.addChildNode(player)
    }
    
    
    func setupCamera() {
        camera = SCNNode()
        camera.name = "Camera"
        camera.position = cameraOffsetFromPlayer
        camera.camera = SCNCamera()
        camera.camera!.usesOrthographicProjection = true
        camera.camera!.orthographicScale = cameraOrthographicScale
        camera.camera!.zNear = 0.05
        camera.camera!.zFar = 150.0
        player.addChildNode(camera)
        
        camera.constraints = [SCNLookAtConstraint(target: player)]
    }
    
    
    func setupLevel() {
        levelData = GameLevel(width: levelWidth, height: levelHeight)
        levelData.setupLevelAtPosition(position: SCNVector3Zero, parentNode: rootNode)
        levelData.spawnDelegate = self
    }
    
    
    func setupGestureRecognizersForView(view: SCNView) {
        OperationQueue.main.addOperation {
            
            // Create tap gesture recognizer
            let tapGesture = UITapGestureRecognizer(target: self, action:#selector(self.handleTap(gesture:)))
            tapGesture.numberOfTapsRequired = 1
            view.addGestureRecognizer(tapGesture)
            
            // Create swipe gesture recognizers
            let swipeUpGesture = UISwipeGestureRecognizer(target: self, action: #selector(self.handleSwipe(gesture:)))
            swipeUpGesture.direction = UISwipeGestureRecognizer.Direction.up
            view.addGestureRecognizer(swipeUpGesture)
            
            let swipeDownGesture = UISwipeGestureRecognizer(target: self, action: #selector(self.handleSwipe(gesture:)))
            swipeDownGesture.direction = UISwipeGestureRecognizer.Direction.down
            view.addGestureRecognizer(swipeDownGesture)
            
            let swipeLeftGesture = UISwipeGestureRecognizer(target: self, action: #selector(self.handleSwipe(gesture:)))
            swipeLeftGesture.direction = UISwipeGestureRecognizer.Direction.left
            view.addGestureRecognizer(swipeLeftGesture)
            
            let swipeRightGesture = UISwipeGestureRecognizer(target: self, action: #selector(self.handleSwipe(gesture:)))
            swipeRightGesture.direction = UISwipeGestureRecognizer.Direction.right
            view.addGestureRecognizer(swipeRightGesture)
        }
    }
    
    
    func setupLights() {
        
        // Create ambient light
        let ambientLight = SCNLight()
        ambientLight.type = SCNLight.LightType.ambient
        ambientLight.color = UIColor.white
        let ambientLightNode = SCNNode()
        ambientLightNode.name = "AmbientLight"
        ambientLightNode.light = ambientLight
        rootNode.addChildNode(ambientLightNode)
        
        // Create an omni-directional light
        let omniLight = SCNLight()
        omniLight.type = SCNLight.LightType.omni
        omniLight.color = UIColor.white
        let omniLightNode = SCNNode()
        omniLightNode.name = "OmniLight"
        omniLightNode.light = omniLight
        omniLightNode.position = SCNVector3(x: -10.0, y: 20, z: 10.0)
        rootNode.addChildNode(omniLightNode)
        
    }
    
    
    // MARK: Game State
    func switchToWaitingForFirstTap() {
        
        gameState = GameState.WaitingForFirstTap
        
        // Fade in
        if let overlay = sceneView.overlaySKScene {
            overlay.enumerateChildNodes(withName: "RestartLevel", using: { node, stop in
                node.run(SKAction.sequence(
                    [SKAction.fadeOut(withDuration: 0.5),
                     SKAction.removeFromParent()]))
            })
            
            // Tap to play animation icon
            let handNode = HandNode()
            OperationQueue.main.addOperation {
                handNode.position = CGPoint(x: self.sceneView.bounds.size.width * 0.5, y: self.sceneView.bounds.size.height * 0.2)
            }
            overlay.addChild(handNode)
        }
    }
    
    
    func switchToPlaying() {
        
        gameState = GameState.Playing
        if let overlay = sceneView.overlaySKScene {
            // Remove tutorial
            overlay.enumerateChildNodes(withName: "Tutorial", using: { node, stop in
                node.run(SKAction.sequence(
                    [SKAction.fadeOut(withDuration: 0.25),
                     SKAction.removeFromParent()]))
            })
        }
    }
    
    
    func switchToGameOver() {
        
        gameState = GameState.GameOver
        
        if let overlay = sceneView.overlaySKScene {
            
            let gameOverLabel = LabelNode(
                position: CGPoint(x: overlay.size.width/2.0, y: overlay.size.height/2.0),
                size: 24, color: .white,
                text: "Game Over",
                name: "GameOver")
            
            overlay.addChild(gameOverLabel)
            
            let clickToRestartLabel = LabelNode(
                position: CGPoint(x: gameOverLabel.position.x, y: gameOverLabel.position.y - 24.0),
                size: 14,
                color: .white,
                text: "Tap to restart",
                name: "GameOver")
            
            overlay.addChild(clickToRestartLabel)
        }
        physicsWorld.contactDelegate = nil
    }
    
    
    func switchToRestartLevel() {
        
        gameState = GameState.RestartLevel
        if let overlay = sceneView.overlaySKScene {
            
            // Fade out game over screen
            overlay.enumerateChildNodes(withName: "GameOver", using: { node, stop in
                node.run(SKAction.sequence(
                    [SKAction.fadeOut(withDuration: 0.25),
                     SKAction.removeFromParent()]))
            })
            
            // Fade to black - and create a new level to play
            let blackNode = SKSpriteNode(color: UIColor.black, size: overlay.frame.size)
            blackNode.name = "RestartLevel"
            blackNode.alpha = 0.0
            blackNode.position = CGPoint(x: sceneView.bounds.size.width/2.0, y: sceneView.bounds.size.height/2.0)
            overlay.addChild(blackNode)
            blackNode.run(SKAction.sequence([SKAction.fadeIn(withDuration: 0.5), SKAction.run({
                let newScene = GameScene(view: self.sceneView)
                newScene.physicsWorld.contactDelegate = newScene
                self.sceneView.scene = newScene
                self.sceneView.delegate = newScene
            })]))
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if gameState == GameState.Playing && playerGridRow == levelData.data.rowCount() - 6 {
            // player completed the level
            switchToGameOver()
        }
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, didApplyAnimationsAtTime time: TimeInterval) {
        
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: TimeInterval) {
        
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        if gameState == GameState.Playing {
            switchToGameOver()
        }
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didUpdate contact: SCNPhysicsContact) {
        print("update")
    }
    func physicsWorld(_ world: SCNPhysicsWorld, didEnd contact: SCNPhysicsContact) {
        print("end")
    }
    
    
    
    func spawnCarAtPosition(position: SCNVector3) {
        
        // Create a material using the model_texture.tga image
        let carMaterial = SCNMaterial()
        carMaterial.diffuse.contents = UIImage(named: "assets.scnassets/Textures/model_texture.tga")
        carMaterial.locksAmbientWithDiffuse = false
        
        // Create a clone of the Car node of the carScene - you need a clone because you need to add many cars
        let carNode = carScene!.rootNode.childNode(withName: "Car", recursively: false)!.clone() as SCNNode
        
        carNode.name = "Car"
        
        carNode.position = position
        
        // Set the material
        carNode.geometry!.firstMaterial = carMaterial
        
        // Create a physicsbody for collision detection
        let carPhysicsBodyShape = SCNPhysicsShape(geometry: SCNBox(width: 0.30, height: 0.20, length: 0.16, chamferRadius: 0.0), options: nil)
        
        carNode.physicsBody = SCNPhysicsBody(type: SCNPhysicsBodyType.kinematic, shape: carPhysicsBodyShape)
        carNode.physicsBody!.categoryBitMask = PhysicsCategory.Car
        carNode.physicsBody!.collisionBitMask = PhysicsCategory.Player
        if #available(iOS 9.0, *) {
            carNode.physicsBody!.contactTestBitMask = PhysicsCategory.Player
        } else {
            // Fallback on earlier versions
        }
        
        rootNode.addChildNode(carNode)
        
        // Move the car
        let moveDirection: Float = position.x > 0.0 ? -1.0 : 1.0
        let moveDistance = levelData.gameLevelWidth()
        let moveAction = SCNAction.move(by: SCNVector3(x: moveDistance * moveDirection, y: 0.0, z: 0.0), duration: 10.0)
        let removeAction = SCNAction.run { node -> Void in
            node.removeFromParentNode()
        }
        carNode.runAction(SCNAction.sequence([moveAction, removeAction]))
        
        // Rotate the car to move it in the right direction
        if moveDirection > 0.0 {
            carNode.rotation = SCNVector4(x: 0.0, y: 1.0, z: 0.0, w: 3.1415)
        }
    }
    
    
    // MARK: Touch Handling
    @objc func handleTap(gesture: UIGestureRecognizer) {
        if gesture is UITapGestureRecognizer {
            movePlayerInDirection(direction: .Forward)
        }
    }
    
    
    @objc func handleSwipe(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case UISwipeGestureRecognizer.Direction.up:
                movePlayerInDirection(direction: .Forward)
                break
                
            case UISwipeGestureRecognizer.Direction.down:
                movePlayerInDirection(direction: .Backward)
                break
                
            case UISwipeGestureRecognizer.Direction.left:
                movePlayerInDirection(direction: .Left)
                break
                
            case UISwipeGestureRecognizer.Direction.right:
                movePlayerInDirection(direction: .Right)
                break
                
            default:
                break
            }
        }
    }
    
    
    // MARK: Player movement
    func movePlayerInDirection(direction: MoveDirection) {
        
        switch gameState {
        case .WaitingForFirstTap:
            
            // Start playing
            switchToPlaying()
            movePlayerInDirection(direction: direction)
            
            break
            
        case .Playing:
            // 1 - Check for player movement
            let gridColumnAndRowAfterMove = levelData.gridColumnAndRowAfterMoveInDirection(direction: direction, currentGridColumn: playerGridCol, currentGridRow: playerGridRow)
            
            if gridColumnAndRowAfterMove.didMove == false {
                return
            }
            
            // 2 - Set the new player grid position
            playerGridCol = gridColumnAndRowAfterMove.newGridColumn
            playerGridRow = gridColumnAndRowAfterMove.newGridRow
            
            // 3 - Calculate the coordinates for the player after the move
            var newPlayerPosition = levelData.coordinatesForGridPosition(column: playerGridCol, row: playerGridRow)
            newPlayerPosition.y = 0.2
            
            // 4 - Move player
            let moveAction = SCNAction.move(to: newPlayerPosition, duration: 0.2)
            let jumpUpAction = SCNAction.move(by: SCNVector3(x: 0.0, y: 0.2, z: 0.0), duration: 0.1)
            jumpUpAction.timingMode = SCNActionTimingMode.easeOut
            let jumpDownAction = SCNAction.move(by: SCNVector3(x: 0.0, y: -0.2, z: 0.0), duration: 0.1)
            jumpDownAction.timingMode = SCNActionTimingMode.easeIn
            let jumpAction = SCNAction.sequence([jumpUpAction, jumpDownAction])
            
            player.runAction(moveAction)
            playerChildNode.runAction(jumpAction)
            
            break
            
        case .GameOver:
            
            // Switch to tutorial
            switchToRestartLevel()
            break
            
        case .RestartLevel:
            
            // Switch to new level
            switchToWaitingForFirstTap()
            break
        }
        
    }
    
    
    func sizeOfBoundingBoxFromNode(node: SCNNode) -> (width: Float, height: Float, depth: Float) {
        var boundingBoxMin = SCNVector3Zero
        var boundingBoxMax = SCNVector3Zero
        let boundingBox = node.boundingBox
        boundingBoxMin = boundingBox.min
        boundingBoxMax = boundingBox.max
        
        let width = boundingBoxMax.x - boundingBoxMin.x
        let height = boundingBoxMax.y - boundingBoxMin.y
        let depth = boundingBoxMax.z - boundingBoxMin.z
        
        return (width, height, depth)
    }
    
}
