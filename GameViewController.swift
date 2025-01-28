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
    
    var resultLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupScene()
        setupWorldBoundary(for: scene)
//        setupUI()
    }
    
    func setupScene() {
        
        print("Starting Board")
        // Load the scene from ar.scnassets
        scene = SCNScene(named: "art.scnassets/MainBoard.scn")!
        
        // Set the View to retrieved scene
        sceneView = self.view as? SCNView
        sceneView.scene = scene
        sceneView.allowsCameraControl = true
        
        // Add a gesture tap recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
    
        // Set render delegate may not need
        sceneView.delegate = self
        
        // Set up physics world delegate
        scene?.physicsWorld.contactDelegate = self
    }
    
    func setupUI() {
        // Create a UILabel for displaying dice result and add it to the main view
        resultLabel = UILabel(frame: CGRect(x: 0, y: 50, width: self.view.frame.width, height: 50))
        resultLabel.textAlignment = .center
        resultLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        resultLabel.textColor = .black
//        resultLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        resultLabel.text = "Roll the dice!"
        self.view.addSubview(resultLabel)
        
        // Create a UIImageView with an SF Symbol for settings
        let settingIcon = UIImageView()
        settingIcon.image = UIImage(systemName: "gear")
        settingIcon.tintColor = .label
        // enable auto layout
        settingIcon.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(settingIcon)
        
        NSLayoutConstraint.activate([
            settingIcon.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16), // Add padding from the top
            settingIcon.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),           // Add padding from the left
            settingIcon.widthAnchor.constraint(equalToConstant: 50),                                  // Set width
            settingIcon.heightAnchor.constraint(equalToConstant: 50)                                  // Set height
        ])
        
        // TODO: add setting icons that take you to different pages
    }
    
    func setupWorldBoundary(for scene: SCNScene) {
        // TODO: adjust the width/height to align with device screen
        
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
    
    enum Dice: String {
        case d4 = "art.scnassets/D4.scn"
        case d6 = "art.scnassets/D6.scn"
        case d8 = "art.scnassets/D8.scn"
        case d10 = "art.scnassets/D10.scn"
        case d12 = "art.scnassets/D12.scn"
        case d20 = "art.scnassets/D20.scn"
    }
    
    @objc
    func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        // Get the scene view
        let sceneView = self.view as! SCNView
        let scene = sceneView.scene!
        
        // Find the camera node
        let cameraNode = scene.rootNode.childNode(withName: "camera", recursively: true)!
        
        // Load die file
//        let selectDie = Int.random(in: 1...6)
//        
//        let dieScene: SCNScene
//        switch selectDie {
//        case 1:
//            dieScene = SCNScene(named: "art.scnassets/D4.scn")!
//        case 2:
//            dieScene = SCNScene(named: "art.scnassets/D6.scn")!
//        case 3:
//            dieScene = SCNScene(named: "art.scnassets/D8.scn")!
//        case 4:
//            dieScene = SCNScene(named: "art.scnassets/D10.scn")!
//        case 5:
//            dieScene = SCNScene(named: "art.scnassets/D12.scn")!
//        case 6:
//            dieScene = SCNScene(named: "art.scnassets/D20.scn")!
//        default:
//            dieScene = SCNScene(named: "art.scnassets/D20.scn")!
//        }
        
        
        let dieScene = SCNScene(named: "art.scnassets/D4.scn")!
        
        // Get the root node of the die file
        let dieNode = dieScene.rootNode.childNodes.first!
        
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
    func findUpSide(for dieNode: SCNNode) -> SCNNode? {
        print("Calculating Side")
        let markerNodes = dieNode.childNodes
        
        // marker variables
        var furthestMarker: SCNNode?
        var maxDistance: Float = 0.0

        for marker in markerNodes {
            // get the absolute position of the markers
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
                
                // debugging prints
                let die = dieNode.presentation
                print("Die Presentation")
                print(die.position)
                
                // find the upside face
                if let side = findUpSide(for: dieNode) {
                    print(side.name ?? "-1")
                    
                    // update UI on the main thread
//                    DispatchQueue.main.async {
//                        self.resultLabel.text = side.name ?? "-1"
//                    }
                    
                    sideList.append(side.name!)
                }
                
                // remove die nodes
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
