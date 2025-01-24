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
    var fallenDice: [SCNNode] = []
    var landedSides: [String] = []
    
    var sceneView: SCNView!
    var scene: SCNScene!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("AOINWDIOOAD")
        
        // Load the scene from ar.scnassets
        scene = SCNScene(named: "art.scnassets/MainBoard.scn")!
        
        // Set the View to retrieved scene
        sceneView = self.view as! SCNView
        sceneView.scene = scene
        sceneView.allowsCameraControl = false
        
        // Add a gesture tap recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
        
        // Create a world boundary to the physics world
        setupWorldBoundary(for: scene)
        
        // Set delegate
        sceneView.delegate = self
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
        let boxScene = SCNScene(named: "art.scnassets/dTest.scn")!
        
        // Get the root node of the die file
        let boxNode = boxScene.rootNode.childNodes.first!
        
        // Set the position of the die at the camera
        boxNode.position = SCNVector3(cameraNode.position.x, cameraNode.position.y, cameraNode.position.z)
        
        // Apply a random force
        let randomX = Float.random(in: -0.2...0.2)
        let randomY = Float.random(in: -0.2...0.2)
        let randomZ = Float.random(in: -0.2...0.2)
        boxNode.physicsBody?.applyForce(SCNVector3(x: randomX, y: randomY - 0.02, z: randomZ), asImpulse: true)
        
        // Apply a random spin (torque)
        let randomTorqueX = Float.random(in: -0.1...0.1)
        let randomTorqueY = Float.random(in: -0.1...0.1)
        let randomTorqueZ = Float.random(in: -0.1...0.1)
        boxNode.physicsBody?.applyTorque(SCNVector4(x: randomTorqueX, y: randomTorqueY, z: randomTorqueZ, w: 1.0), asImpulse: true)
        
        print(boxNode.worldPosition)
        // Add the die to the main scene
        scene.rootNode.addChildNode(boxNode)
        fallenDice.append(boxNode)
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
      
        var closestMarker: SCNNode?
        var minDistance: Float = Float.greatestFiniteMagnitude
        
//        let floorNode = scene.rootNode.childNode(withName: "floor", recursively: true)!

//        print(floorNode.worldPosition)
        print(dieNode.worldTransform)

        
        for marker in markerNodes {
            // Calculate distance to the ground (y = 0). We care about the absolute y position
            print(marker.worldPosition)
            let distance = marker.worldPosition.y // Assuming marker at y = 0 is closest to the ground
            
            // We check for the side that's closest to 0 in terms of y
            if distance < minDistance {
                closestMarker = marker
                minDistance = distance
            }
        }
        
        // If you want more clarity, let's print the distances for debugging:
        print("Closest marker: \(closestMarker?.name ?? "None"), distance: \(minDistance)")
        
        return closestMarker
    }

    
    // Check if the velocity is approximately zero
    func isVelocityZero(_ velocity: SCNVector3) -> Bool {
        let threshold: Float = 0.00001 // Define a small threshold for "stopped"
        return abs(velocity.x) < threshold && abs(velocity.y) < threshold && abs(velocity.z) < threshold
    }
}

extension GameViewController: SCNSceneRendererDelegate {
    func renderer(_ renderer: any SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // Check each fallen die and find the closest side when it has stopped moving
//        print("Checking render")
        for boxNode in fallenDice {
            if let boxPhysicsBody = boxNode.physicsBody {
                // Check if the velocity is approximately zero
                if isVelocityZero(boxPhysicsBody.velocity) {
                    // Die has stopped moving, now check for the closest side
                    if let closestMarker = calculateClosestSide(for: boxNode) {
                        print("Closest side for die \(boxNode.name ?? "Unnamed") is \(closestMarker.name ?? "No side")")
                        let index = fallenDice.firstIndex(of: boxNode)!
                        fallenDice.remove(at: index)
                        landedSides.append(closestMarker.name!)
                        print(landedSides)
                    }
                }
            }
        }
    }
}
