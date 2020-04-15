//
//  GameViewController.swift
//  RWDevConSceneKitFinal
//
//  Created by Kim Pedersen on 24/11/14.
//  Copyright (c) 2014 RWDevCon. All rights reserved.
//

import SceneKit
import SpriteKit

class GameViewController: UIViewController {
  
  var scnView: SCNView {
    get {
        return self.view as! SCNView
    }
  }
    
    var scene : SCNScene?
  
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        // Set up the SCNView
        scnView.backgroundColor = UIColor(red: 100.0/255.0, green: 149.0/255.0, blue: 237.0/255.0, alpha: 1.0)
        scnView.showsStatistics = true
        scnView.antialiasingMode = SCNAntialiasingMode.multisampling2X
        scnView.overlaySKScene = SKScene(size: view.bounds.size)
  //      scnView.isPlaying = true
        
        // Set up the scene
        self.scene = GameScene(view: scnView)
        scene!.rootNode.isHidden = true
        
        scene!.physicsWorld.speed = 2.0

        
        // Start playing the scene
        scnView.scene = scene
        scnView.scene!.rootNode.isHidden = false
        scnView.play(self)
  }
  
  
////  override func shouldAutorotate() -> Bool {
////    return true
////  }
////
////
////  override func prefersStatusBarHidden() -> Bool {
////    return true
////  }
////
////
////  override func supportedInterfaceOrientations() -> Int {
////    return Int(UIInterfaceOrientationMask.portrait.rawValue)
//  }
  
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
}
