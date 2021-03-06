//
//  HandNode.swift
//  SCNFrogger
//
//  Created by Kim Pedersen on 11/12/14.
//  Copyright (c) 2014 RWDevCon. All rights reserved.
//

import SpriteKit

class HandNode : SKNode {
  
  override init() {
    
    super.init()
    
    name = "Tutorial"
    
    // Load textures
    let handTexture = SKTexture(imageNamed:"assets.scnassets/Textures/hand.png")
    handTexture.filteringMode = SKTextureFilteringMode.nearest
    let handTextureClick = SKTexture(imageNamed:"assets.scnassets/Textures/hand_click.png")
    handTextureClick.filteringMode = SKTextureFilteringMode.nearest
    
    // Create animation
    let handAnimation = SKAction.animate(with: [handTexture, handTextureClick], timePerFrame:0.5)
    
    // Create a sprite node abd animate it
    let handSprite = SKSpriteNode(texture: handTexture)
    handSprite.xScale = 2.0
    handSprite.yScale = 2.0
    handSprite.run(SKAction.repeatForever(handAnimation))
    
    addChild(handSprite)
  }
  
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
}
