//
//  GameViewController.swift
//  DiceRoller
//
//  Created by Logan on 1/23/25.
//

import UIKit
import QuartzCore
import SceneKit

class GameViewController: UIViewController {
    
    var sceneView: SCNView!
    var scene: SCNScene!
    
    var fallingDice: [SCNNode] = []
    var sideList: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupScene()
        setupWorldBoundary(for: scene)
    }
    
    func setupScene() {
        
        print("Starting Board")
        // Load the scene from ar.scnassets
        scene = SCNScene(named: "art.scnassets/MainBoard.scn")!
        
        // Set the View to retrieved scene
        sceneView = self.view as! SCNView
        sceneView.scene = scene
        sceneView.allowsCameraControl = false
        
        // Add a gesture tap recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
    
        // Set render delegate may not need
        sceneView.delegate = self
        
        // Set up physics world delegate
        scene?.physicsWorld.contactDelegate = self
    }
    
    func setupWorldBoundary(for scene: SCNScene) {
        // Define the dimensions of the boundary walls
        let boundaryWidth: CGFloat = 2.0
        let boundaryHeight: CGFloat = 5.0
        let wallThickness: CGFloat = 0.1
        
        // Create positions for each wall (left, right, front, back)
        let wallPositions = [
            SCNVector3(-boundaryWidth / 2, 0, 0),  // Left wall
            SCNVector3(boundaryWidth / 2, 0, 0),   // Right wall
            SCNVector3(0, 0, -boundaryWidth / 2),  // Back wall
            SCNVector3(0, 0, boundaryWidth / 2)    // Front wall
        ]
        
        // Loop to create and add walls
        for (index, position) in wallPositions.enumerated() {
            // Walls are tall and thin
            let wallGeometry = SCNBox(
                width: index < 2 ? wallThickness : boundaryWidth,  // Left/right walls are thin vertically
                height: boundaryHeight,
                length: index < 2 ? boundaryWidth : wallThickness, // Front/back walls are thin horizontally
                chamferRadius: 0
            )
            
            wallGeometry.firstMaterial?.diffuse.contents = UIColor.clear // Make walls invisible
            
            let wallNode = SCNNode(geometry: wallGeometry)
            wallNode.position = position
            
            // Add a static physics body to each wall
            wallNode.physicsBody = SCNPhysicsBody.static()
            
            // Add wall to the scene
            scene.rootNode.addChildNode(wallNode)
        }
    }
    
    @objc
    func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        // Get the scene view
        let sceneView = self.view as! SCNView
        let scene = sceneView.scene!
        
        // Find the camera node
        let cameraNode = scene.rootNode.childNode(withName: "camera", recursively: true)!
        
        // Load die file
        let dieScene = SCNScene(named: "art.scnassets/dTest.scn")!
        
        // Get the root node of the die file
        let dieNode = dieScene.rootNode.childNodes.first!
//        
//        let dieNode = SCNNode(geometry: SCNSphere(radius: 0.1))
//        dieNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
//        dieNode.name = "ball"
        
        // Set the position of the die at the camera
        dieNode.position = SCNVector3(cameraNode.position.x, cameraNode.position.y, cameraNode.position.z)

        // Apply a random force
        let randomX = Float.random(in: -0.2...0.2)
        let randomY = Float.random(in: -0.2...0.2)
        let randomZ = Float.random(in: -0.2...0.2)
        dieNode.physicsBody?.applyForce(SCNVector3(x: randomX, y: randomY - 0.02, z: randomZ), asImpulse: true)
        
        // Apply a random spin (torque)
        let randomTorqueX = Float.random(in: -0.1...0.1)
        let randomTorqueY = Float.random(in: -0.1...0.1)
        let randomTorqueZ = Float.random(in: -0.1...0.1)
        dieNode.physicsBody?.applyTorque(SCNVector4(x: randomTorqueX, y: randomTorqueY, z: randomTorqueZ, w: 1.0), asImpulse: true)
        
        print(dieNode.worldPosition)
        // Add the die to the main scene
        scene.rootNode.addChildNode(dieNode)
        fallingDice.append(dieNode)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
        
    // Function to calculate which side is closest to the ground (assuming y = 0 is the ground)
    func calculateClosestSide(for dieNode: SCNNode) -> SCNNode? {
        print("Calculating Side")
        let markerNodes = dieNode.childNodes
        
        var furthestMarker: SCNNode?
        var maxDistance: Float = 0.0

        for marker in markerNodes {
            let distance = marker.presentation.worldPosition.y // Assuming marker at y = 0 is closest to the ground

            // check for the side that's furthest from 0 in terms of y
            if distance > maxDistance {
                furthestMarker = marker
                maxDistance = distance
            }
        }

        print("Furthest marker: \(furthestMarker?.name ?? "None"), distance: \(maxDistance)")
        return furthestMarker
    }

    
    // Check if the velocity is approximately zero
    func isVelocityZero(_ velocity: SCNVector3) -> Bool {
        let threshold: Float = 0.00001 // Define a small threshold for "stopped"
        return abs(velocity.x) < threshold && abs(velocity.y) < threshold && abs(velocity.z) < threshold
    }
}

extension GameViewController: SCNSceneRendererDelegate {
    func renderer(_ renderer: any SCNSceneRenderer, updateAtTime time: TimeInterval) {
        for dieNode in fallingDice {
            if dieNode.physicsBody?.isResting == true {
                let die = dieNode.presentation
                print("Die Presentation")
                print(die.position)
                if let side = calculateClosestSide(for: dieNode) {
                    print(side.name ?? "You fucked up")
                    sideList.append(side.name!)
                }
                
                // remove die notde
                if let index = fallingDice.firstIndex(of: dieNode) {
                    fallingDice.remove(at: index)
                }
            }
        }
    }
}

extension GameViewController: SCNPhysicsContactDelegate {
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        // Code
    }
}
