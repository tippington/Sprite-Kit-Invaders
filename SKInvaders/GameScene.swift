//
//  GameScene.swift
//  SKInvaders
//
//  Created by Riccardo D'Antoni on 15/07/14.
//  Copyright (c) 2014 Razeware. All rights reserved.
//

import SpriteKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {

    // initializes the contact queue to an array
    var contactQueue = Array<SKPhysicsContact>()
    
    
    // Private GameScene Properties
    
    var score: Int = 0
    var shipHealth: Float = 1.0
    
    let kMinInvaderBottomHeight: Float = 32.0
    var gameEnding: Bool = false
    
    
    // initializes the tap queue to an empty array
    var tapQueue: Array<Int> = []
    

    
    let motionManager: CMMotionManager = CMMotionManager()
    
    enum InvaderMovementDirection {
        case Right
        case Left
        case DownThenRight
        case DownThenLeft
        case None
    }
    
    // defines the possible types of invader enemies
    enum InvaderType {
        case A
        case B
        case C
    }
    
    // defines bullet types
    enum BulletType {
        case ShipFiredBulletType
        case InvaderFiredBulletType
    }
    
    
    // defines the size of invaders & that they'll be laid out
    // on a grid of rows and columns on the screen
    let kInvaderSize = CGSize(width:24, height: 16)
    let kInvaderGridSpacing = CGSize(width: 12, height: 12)
    let kInvaderRowCount = 6
    let kInvaderColCount = 6
    
    // define a name used to identify invaders when searching
    // for them in the scene
    let kInvaderName = "invader"
    
    let kShipSize = CGSize(width:30, height:16)
    let kShipName = "ship"
    let kScoreHudName = "scoreHud"
    let kHealthHudName = "healthHud"
    
    let kShipFiredBulletName = "shipFiredBullet"
    let kInvaderFiredBulletName = "invaderFiredBullet"
    let kBulletSize = CGSizeMake(4, 8)
    
    // defines bitmasks for stuffing multiple on/off variables into a single 32-bit unsigned integer
    let kInvaderCategory: UInt32 = 0x1 << 0
    let kShipFiredBulletCategory: UInt32 = 0x1 << 1
    let kShipCategory: UInt32 = 0x1 << 2
    let kSceneEdgeCategory: UInt32 = 0x1 << 3
    let kInvaderFiredBulletCategory: UInt32 = 0x1 << 4
  
  var contentCreated = false
    
    // invaders begin by moving to the right
    var invaderMovementDirection: InvaderMovementDirection = .Right
    
    // invaders haven't moved yet, so set the time to zero
    var timeOfLastMove: CFTimeInterval = 0.0
    
    // invaders take 1 second for each move
    var timePerMove: CFTimeInterval = 1.0
    
    
    
    
    
  
  // Object Lifecycle Management
  
  // Scene Setup and Content Creation
  override func didMoveToView(view: SKView) {
    
    if (!self.contentCreated) {
      self.createContent()
      self.contentCreated = true
        
        // kicks off the production of accelerometer data
        motionManager.startAccelerometerUpdates()
        
        // ensures that user interactions are enabled for the scene
        // so it can receive tap events
        userInteractionEnabled = true
        
        // sets the scene as the contact delegate of the physics engine
        physicsWorld.contactDelegate = self
        
    }
  }
  
    
    
    
    
    
    
  func createContent() {
    
    // builds an infinitely-thin wall around the edge of the screen
    physicsBody = SKPhysicsBody(edgeLoopFromRect: frame)
    
    physicsBody!.categoryBitMask = kSceneEdgeCategory
    
    setupInvaders()
    
    func makeShip() -> SKNode {
        let ship = SKSpriteNode(imageNamed: "Ship.png")
        ship.name = kShipName
        
        // create a rectangular physics body the same size as the ship
        ship.physicsBody = SKPhysicsBody(rectangleOfSize: ship.frame.size)
        
        // make the shape dynamic, making it subject to things such as
        // collisions and other outside forces
        ship.physicsBody!.dynamic = true
        
        // ship not affected by gravity, therefore won't drop off the bottom
        // of the screen
        ship.physicsBody!.affectedByGravity = false
        
        // give the ship an arbitrary mass so that its movement feels natural
        ship.physicsBody!.mass = 0.02
        
        // set the ship's category
        ship.physicsBody!.categoryBitMask = kShipCategory
        
        // DON'T detect contact between the ship and other physics bodies
        ship.physicsBody!.contactTestBitMask = 0x0
        
        // DO detect collisions between the ship and the scene's outer edges
        ship.physicsBody!.collisionBitMask = kSceneEdgeCategory
        
        return ship
    }
    
    func setupHud() {
        
        // names the score label, making it easier to find
        let scoreLabel = SKLabelNode(fontNamed: "Courier")
        scoreLabel.name = kScoreHudName
        scoreLabel.fontSize = 25
        
        // color the score label green
        scoreLabel.fontColor = SKColor.greenColor()
        scoreLabel.text = String(format: "Score: %04u", 0)
        
        // position the score label
        println(size.height)
        scoreLabel.position = CGPoint(x: frame.size.width / 2, y: size.height - (40 + scoreLabel.frame.size.height/2))
        addChild(scoreLabel)
        
        // names the health label, making it easier to find
        let healthLabel = SKLabelNode(fontNamed: "Courier")
        healthLabel.name = kHealthHudName
        healthLabel.fontSize = 25
        
        // colors the health label red
        healthLabel.fontColor = SKColor.redColor()
        healthLabel.text = String(format: "Health: %04u", self.shipHealth)
        
        // position the health below the score level
        healthLabel.position = CGPoint(x: frame.size.width / 2, y: size.height - (80 + healthLabel.frame.size.height / 2))
        addChild(healthLabel)
        
    }
    
    // create a ship using makeShip()
    // will work later to create the ship after player death
    let ship = makeShip()
    
    func setupShip() {
        
        // place the ship on the screen
        ship.position = CGPoint(x:size.width / 2.0, y:kShipSize.height / 2.0)
        addChild(ship)
    }
    
    setupShip()
    
    setupHud()
    
    // black space color
    self.backgroundColor = SKColor.blackColor()
    
    }
    
    
    
    
    
    
    
    func loadInvaderTexturesOfType(invaderType: InvaderType) -> Array<SKTexture> {
        
        var prefix: String
        
        switch(invaderType) {
        case .A:
            prefix = "InvaderA"
        case .B:
            prefix = "InvaderB"
        case .C:
            prefix = "InvaderC"
        default:
            prefix = "InvaderC"
        }
        
        // loads a pair of sprite images for each invader type, creates SKTexture objects from them
        return [SKTexture(imageNamed: String(format: "%@_00.png", prefix)),
            SKTexture(imageNamed: String(format: "%@_01.png", prefix))]
    }
    
    func makeInvaderOfType(invaderType: InvaderType) -> SKNode {
        
        let invaderTextures = self.loadInvaderTexturesOfType(invaderType)
        
        // uses first SKTexture as sprite's base image
        let invader = SKSpriteNode(texture: invaderTextures[0])
        invader.name = kInvaderName
        
        // ANIMATES these two images in continuous animation loop
        invader.runAction(SKAction.repeatActionForever(SKAction.animateWithTextures(invaderTextures, timePerFrame: self.timePerMove)))
        
        // invaders' bitmasks setup
        invader.physicsBody = SKPhysicsBody(rectangleOfSize: invader.frame.size)
        invader.physicsBody!.dynamic = false
        invader.physicsBody!.categoryBitMask = kShipFiredBulletCategory
        invader.physicsBody!.contactTestBitMask = kInvaderCategory
        invader.physicsBody!.collisionBitMask = 0x0
        
        return invader
    }
    
    
    
    

    
    
    
    
    
    func setupInvaders() {

        // declare and set the baseOrigin constant and loop over the rows
        let baseOrigin = CGPoint(x:size.width / 3, y: 180)
        for var row = 1; row <= kInvaderRowCount; row++ {
        
            // choose a single InvaderType for all invaders in this row based on the row number
            var invaderType: InvaderType
            if row % 3 == 0 {
                invaderType = .A
            } else if row % 3 == 1 {
                invaderType = .B
            } else {
                invaderType = .C
            }
        
            // figure out where the first invader in this row should be positioned
            let invaderPositionY = CGFloat(row) * (kInvaderSize.height * 2) + baseOrigin.y
            var invaderPosition = CGPoint(x:baseOrigin.x, y:invaderPositionY)
        
            // loop over the columns
            for var col = 1; col <= kInvaderColCount; col++ {
            
                // create invader for current row and column and add it to the scene
                var invader = makeInvaderOfType(invaderType)
                invader.position = invaderPosition
                addChild(invader)
            
                // update the invaderPosition so that it's correct for the next invader
                invaderPosition = CGPoint(x: invaderPosition.x + kInvaderSize.width + kInvaderGridSpacing.width, y: invaderPositionY)
            }
        }
    }
    
    
    
    
    
    
    // bullets
    func makeBulletOfType(bulletType: BulletType) -> SKNode! {
    
        var bullet: SKNode!
        
        switch (bulletType) {
            case .ShipFiredBulletType:
                bullet = SKSpriteNode(color: SKColor.greenColor(), size: kBulletSize)
                bullet.name = kShipFiredBulletName
                bullet.physicsBody = SKPhysicsBody(rectangleOfSize: bullet.frame.size)
                bullet.physicsBody!.dynamic = true
                bullet.physicsBody!.affectedByGravity = false
                bullet.physicsBody!.categoryBitMask = kInvaderCategory
                bullet.physicsBody!.contactTestBitMask = kShipCategory
                bullet.physicsBody!.collisionBitMask = 0x0
            
            case .InvaderFiredBulletType:
                bullet = SKSpriteNode(color: SKColor.magentaColor(), size: kBulletSize)
                bullet.name = kInvaderFiredBulletName
                bullet.physicsBody = SKPhysicsBody(rectangleOfSize: bullet.frame.size)
                bullet.physicsBody!.dynamic = true
                bullet.physicsBody!.affectedByGravity = false
                bullet.physicsBody!.categoryBitMask = kInvaderFiredBulletCategory
                bullet.physicsBody!.contactTestBitMask = kShipCategory
                bullet.physicsBody!.collisionBitMask = 0x0
                break;
            default:
                bullet = nil
            }
    
        return bullet
        }

  
  // Scene Update
  
    // called before each frame is rendered
    override func update(currentTime: CFTimeInterval) {
        
        // checks to see if game is over every time scene updates
        if self.isGameOver() {
            self.endGame()
        }
        
        //handles the contact queue
        processContactsForUpdate(currentTime)
        
        //processes any user taps
        processUserTapsForUpdate(currentTime)
        
        // moves ship for user input
        processUserMotionForUpdate(currentTime)
        
        // moves invaders
        moveInvadersForUpdate(currentTime)
        
        // starts invaders firing back at you
        fireInvaderBulletsForUpdate(currentTime)
    
    }

  
    
    
    
    
  
  // Scene Update Helpers
    func moveInvadersForUpdate(currentTime: CFTimeInterval) {
        
        // if it's not yet time to move, then exit the method.
        // moveInvadersForUpdate is invoked 60x per second, but
        // we don't want them to move that quickly
        if (currentTime - timeOfLastMove < timePerMove) {
            return
        }
        
        determineInvaderMovementDirection()
        
        // loops over the invaders by name [USING TRAILING CLOSURE SYNTAX]
        enumerateChildNodesWithName(kInvaderName) {
            node, stop in
            
            // moves the invaders 10px right, left, or down depending on
            // the value of invaderMovementDirection
            switch self.invaderMovementDirection {
            case .Right:
                node.position = CGPoint(x: node.position.x + 10, y: node.position.y)
            case .Left:
                node.position = CGPoint(x: node.position.x - 10, y: node.position.y)
            case .DownThenLeft, .DownThenRight:
                node.position = CGPoint(x: node.position.x, y: node.position.y - 10)
            case .None:
                break
            }
            
            // reset the clock to move the invaders
            self.timeOfLastMove = currentTime
        }
    }
    
    // ACCELEROMETER TILT INTEGRATION
    func processUserMotionForUpdate(currentTime: CFTimeInterval) {
        
        
        // get the ship from the scene so you can move it
        if let ship = self.childNodeWithName(kShipName) as? SKSpriteNode {
        
        // get accelerometer data from the motion manager
        // it's an optional, so only assigns if there
        // actually is a value in accelerometerData
        if let data = motionManager.accelerometerData {
            
            // tilting right produces a positive value, while
            // tilting left produces a negative value, so
            // this considers device not tilted unless it's at
            // least 0.2 to either side
            if (fabs(data.acceleration.x) > 0.2) {
                
                // applies force to ship's physics body
                // in the same direction as data.acceleration.x
                // 40.0 is an arbitrary value to make the ship's
                // motion feel natural
                ship.physicsBody!.applyForce(CGVectorMake(40.0 * CGFloat(data.acceleration.x), 0))
                }
            }
        }
    }
    

    func processUserTapsForUpdate(currentTime: CFTimeInterval) {
        
        // loop over your tapQueue
        for tapCount in self.tapQueue {
            if tapCount == 1 {
                
                // if the queue entry is a single tap, handle it
                // defends against the possibility of double-taps, swipes, etc
                self.fireShipBullets()
                
            }
            
        // remove the tap from the queue
        self.tapQueue.removeAtIndex(0)
        
        }
    }
    
    func fireInvaderBulletsForUpdate(currentTime:CFTimeInterval) {
        
        let existingBullet = self.childNodeWithName(kInvaderFiredBulletName)
        
        //  only fire a bullet if one's not already on-screen
        if existingBullet == nil {
            
            var allInvaders = Array<SKNode>()
            
            // collect all the invaders currently on-screen
            self.enumerateChildNodesWithName(kInvaderName) {
                node, stop in
                
                allInvaders.append(node)
            }
        
            if allInvaders.count > 0 {
                
                // select an invader at random
                let allInvadersIndex = Int(arc4random_uniform(UInt32(allInvaders.count)))
                
                let invader = allInvaders[allInvadersIndex]
                
                // create a bullet and fire it from just below the selected invader
                let bullet = self.makeBulletOfType(.InvaderFiredBulletType)
                bullet.position = CGPointMake(invader.position.x, invader.position.y - invader.frame.size.height / 2 + bullet.frame.size.height / 2)
                
                // the bullet should travel straight down and move just off the bottom of the screen
                let bulletDestination = CGPointMake(invader.position.x, -(bullet.frame.size.height / 2))
                
                // fire off the invader's bullet
                self.fireBullet(bullet, toDestination: bulletDestination, withDuration: 2.0, andSoundFileName: "InvaderBullet.wav")
            }
        }
    }
    
    // handles items in the contact queue and then clears it
    func processContactsForUpdate(currentTime: CFTimeInterval) {
            
        for contact in self.contactQueue {
            self.handleContact(contact)
                
            if let index = (self.contactQueue as NSArray).indexOfObject(contact) as Int? {
                self.contactQueue.removeAtIndex(index)
            }
        }
    }
    
    
    
    
    
    

    
  
    // Invader Movement Helpers
    func determineInvaderMovementDirection() {

        // keeps a reference to the current invaderMovementDirection so that
        // it can be modified below
        var proposedMovementDirection: InvaderMovementDirection = invaderMovementDirection
        
        // loop over all the invaders in the scene and invoke
        // the block with the invader as an argument
        enumerateChildNodesWithName(kInvaderName) { node, stop in
            switch self.invaderMovementDirection {
            case .Right:
                
                // checks if the invader is about to move offscreen on the right
                // and if it is, changes the direction to down then left
                if (CGRectGetMaxX(node.frame) >= node.scene!.size.width - 1.0) {
                    proposedMovementDirection = .DownThenLeft
                    
                    self.adjustInvaderMovementToTimePerMove(self.timePerMove * 0.8)
                    
                    stop.memory = true
                }
            case .Left:
                
                // checks if the invader is about to move offscreen on the left
                // and if it is, changes the direction to down then right
                if (CGRectGetMinX(node.frame) <= 1.0) {
                    proposedMovementDirection = .DownThenRight
                    
                    self.adjustInvaderMovementToTimePerMove(self.timePerMove * 0.8)
                    
                    stop.memory = true
                }
            case .DownThenLeft:
                
                // if invaders are moving down then left, they've already moved down
                // so they should now move left
                proposedMovementDirection = .Left
                stop.memory = true
            case .DownThenRight:
                
                // if invaders are moving down then right, they've already moved down
                // so they should now move right
                proposedMovementDirection = .Right
                stop.memory = true
            default:
                break
            }
        }
        
        // if the proposed invader movement directions is different than the current
        // invader movement direction, update the current invader movement direction
        // to the proposed movement direction
        if (proposedMovementDirection != invaderMovementDirection) {
            invaderMovementDirection = proposedMovementDirection
        }
    }
    
        func adjustInvaderMovementToTimePerMove(newTimerPerMove: CFTimeInterval) {
            
            // ignore bogus values - value <= 0 would mean infinitely fast or
            // reverse movement, which is garbage
            if newTimerPerMove <= 0 {
                return
            }
            
            // set the scene's timePerMove to the given value, speeding up movement
            // of invaders within moveInvadersForUpdate
            // also record the ratio of the change so you can adjust
            // node's speed accordingly
            // also speeds up the animation of invaders so animation cycles through its
            // two frames more quickly
            // ratio ensures that if new timePerMove is 1/3 the old, then animation
            // will be 3x as fast
            let ratio: CGFloat = CGFloat(self.timePerMove / newTimerPerMove)
            self.timePerMove = newTimerPerMove
            
            self.enumerateChildNodesWithName(kInvaderName) {
                node, stop in
                
                node.speed = node.speed * ratio
                
            }
            
        }

        
                
                

  
  // Bullet Helpers
    
    func fireBullet(bullet: SKNode, toDestination destination: CGPoint, withDuration duration: CFTimeInterval, andSoundFileName soundName: String) {
        
        // creates an SKAction that moves the bullet to the desired destination and then removes it from the scene
        // actions are done consecutively, i.e. the next action only takes place after the previous one has
        // been completed
        let bulletAction = SKAction.sequence([SKAction.moveTo(destination, duration: duration), SKAction.waitForDuration(3.0/60.0), SKAction.removeFromParent()])
        
        // play desired sound to signal that bullet was fired
        let soundAction = SKAction.playSoundFileNamed(soundName, waitForCompletion: true)
        
        // move the bullet and play sound at same time by putting them in the same GROUP
        // group actions are run in parallel, not sequentially
        bullet.runAction(SKAction.group([bulletAction, soundAction]))
        
        // fire the bullet by adding it to the scene
        // brings it onscreen and starts the actions
        self.addChild(bullet)
        
    }
    
    func fireShipBullets() {
        
        let existingBullet = self.childNodeWithName(kShipFiredBulletName)
        
        // only fire bullet if there isn't already one onscreen
        if existingBullet == nil {
            
            if let ship = self.childNodeWithName(kShipName) {
                
                if let bullet = self.makeBulletOfType(.ShipFiredBulletType) {
                    
                    // set bullet's position so that it comes out of the top of the ship
                    bullet.position = CGPointMake(ship.position.x, ship.position.y + ship.frame.size.height - bullet.frame.size.height / 2)
                    
                    // set bullet's destination to be just off the top of the screen
                    // x coordinate is the same as that of the bullet's position, so it
                    // will fly straight up
                    let bulletDestination = CGPointMake(ship.position.x, self.frame.size.height + bullet.frame.size.height / 2)
                    
                    //  fire the bullet!
                    self.fireBullet(bullet, toDestination: bulletDestination, withDuration: 1.0, andSoundFileName: "ShipBullet.wav")
                    
                }
                
            }
            
        }
        
    }
    
    
    
    
    
    
    
    
  
  // User Tap Helpers

    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        // intentional no-op
    }

    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        // intentional no-op
    }

    override func touchesCancelled(touches: NSSet, withEvent event: UIEvent) {
        // intentional no-op
    }
    
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {

    
        if let touch : AnyObject = touches.anyObject() {

            if (touch.tapCount == 1) {
            
                //add a tap to the queue
                self.tapQueue.append(1)
            }
        }
    }

    
    
    
    
  
  // HUD Helpers
  
    func adjustScoreBy(points: Int) {
        
        self.score += points
        
        let score = self.childNodeWithName(kScoreHudName) as SKLabelNode
        
        score.text = String(format: "Score: %04u", self.score)
        
    }
    
    func adjustShipHealthBy(healthAdjustment: Float) {
        
        self.shipHealth += healthAdjustment
        
        let health = self.childNodeWithName(kHealthHudName) as SKLabelNode
        
        health.text = String(format: "Health: %.1f%%", (self.shipHealth * 100))
        
    }
    
    
    
  // Physics Contact Helpers
    
    func didBeginContact(contact: SKPhysicsContact!) {
        if contact != nil {
            self.contactQueue.append(contact)
            println(contact)
        }
    }
    
    func handleContact(contact: SKPhysicsContact) {
        // Don't allow the same contact twice
        // Ensure you haven't already handled this contact and removed its nodes
        if (contact.bodyA.node?.parent == nil || contact.bodyB.node?.parent == nil) {
            return
        }
        
        var nodeNames = [contact.bodyA.node!.name!, contact.bodyB.node!.name!]
        
        // containsObject is not yet implemented in Swift's Array, so casts the Array to NSArray
        // to get access to NSArray's methods
        if (nodeNames as NSArray).containsObject(kShipName) && (nodeNames as NSArray).containsObject(kInvaderFiredBulletName) {
            
            // If an invader bullet hits your ship, remove both your ship and the bullet
            // from the scene and play a sound
            self.runAction(SKAction.playSoundFileNamed("ShipHit.wav", waitForCompletion: false))
            
            // adjust ship's health when it gets hit by invader bullet
            self.adjustShipHealthBy(-0.334)
            
            
            // if ship's health is zero, remove ship and invader bullet from scene
            if self.shipHealth <= 0 {
                
                
                contact.bodyA.node!.removeFromParent()
                contact.bodyB.node!.removeFromParent()
                
                } else {
                
                // if ship's health > zero, only remove invader bullet from scene
                // also dim ship's sprite to indicate damage
                let ship = self.childNodeWithName(kShipName)!
                
                ship.alpha = CGFloat(self.shipHealth)
                
                if contact.bodyA.node == ship {
                    
                    contact.bodyB.node!.removeFromParent()
                    
                } else {
                    
                    contact.bodyA.node!.removeFromParent()
                    
                }
                
            
            }
        
        } else if ((nodeNames as NSArray).containsObject(kInvaderName) && (nodeNames as NSArray).containsObject(kShipFiredBulletName)) {
            
            // If a ship bullet hits an invader, remove both your the bullet
            // and the invader from the scene and play a different sound
            self.runAction(SKAction.playSoundFileNamed("InvaderHit.wav", waitForCompletion: false))
            contact.bodyA.node!.removeFromParent()
            contact.bodyB.node!.removeFromParent()
            
            println("Ship Bullet Hit Enemy")
            
            // when invader is hit, add 100 points to the score
            self.adjustScoreBy(100)
            
        }
    }
    
    
    
    
  
  // Game End Helpers
    
    func isGameOver() -> Bool {
        
        // get all invaders that remain in the scene
        let invader = self.childNodeWithName(kInvaderName)
        
        // iterate through the invaders to check if any invaders are too low
        var invaderTooLow = false
        
        self.enumerateChildNodesWithName(kInvaderName) {
            node, stop in
            
            if (Float(CGRectGetMinY(node.frame)) <= self.kMinInvaderBottomHeight) {
                
                invaderTooLow = true
                stop.memory = true
            }
        }
        
        // get a pointer to your ship - if health drops to 0 then player is removed, in this
        // case will return nil
        let ship = self.childNodeWithName(kShipName)?
        
        // return whether game is over (i.e. if there are no more invaders, invader is too low, or
        // shp is destroyed, then game is over)
        return invader == nil || invaderTooLow || ship == nil
    }
    
    func endGame() {
        
        // end game only once
        if !self.gameEnding {
            
            self.gameEnding = true
            
            // stop accelerometer updates
            self.motionManager.stopAccelerometerUpdates()
            
            // show gameover scene
            let gameOverScene: GameOverScene = GameOverScene(size: self.size)
            
            view!.presentScene(gameOverScene, transition: SKTransition.doorsOpenHorizontalWithDuration(1.0))
        }
    }
    
  

}