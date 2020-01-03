//
//  ViewController.swift
//  FloorIsLava
//
//  Created by Livia Vasconcelos on 02/01/20.
//  Copyright © 2020 Livia Vasconcelos. All rights reserved.
//

import UIKit
import ARKit
import CoreMotion

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    
    let configuration = ARWorldTrackingConfiguration()
    let motionManager = CMMotionManager()
    var vehicle       = SCNPhysicsVehicle()
    var orientation: CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.delegate = self
        self.configuration.planeDetection = .horizontal
        
        self.sceneView.debugOptions = [SCNDebugOptions.showWorldOrigin, SCNDebugOptions.showFeaturePoints]
        self.sceneView.session.run(configuration)
        self.sceneView.showsStatistics = true
        
        self.setupAccelerometer()
    }
    
    func createConcrete(planeAnchor: ARPlaneAnchor) -> SCNNode {
        let concreteNode = SCNNode(geometry: SCNPlane(width: CGFloat(planeAnchor.extent.x),
                                                      height: CGFloat(planeAnchor.extent.z)))
        concreteNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "concrete")
        concreteNode.geometry?.firstMaterial?.isDoubleSided = true
        concreteNode.position = SCNVector3(planeAnchor.center.x,
                                       planeAnchor.center.y,
                                       planeAnchor.center.z)
        concreteNode.eulerAngles = SCNVector3(90.degreesToRadians, 0, 0)
        
        let staticBody = SCNPhysicsBody.static()
        concreteNode.physicsBody = staticBody 
        
        return concreteNode
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        let concreteNode = createConcrete(planeAnchor: planeAnchor)
        node.addChildNode(concreteNode)
        print("---------- new ARPlane Anchor")
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        node.enumerateChildNodes { (childNode, _) in
            childNode.removeFromParentNode()
        }
        
        let lavaNode = createConcrete(planeAnchor: planeAnchor)
        node.addChildNode(lavaNode)
        print("***** UPDATING ****")
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard let _ = anchor as? ARPlaneAnchor else { return }
        node.enumerateChildNodes { (childNode, _) in
            childNode.removeFromParentNode()
        }
        
        print("(((( REMOVED ))))")
    }
    
    @IBAction func addCar(_ sender: Any) {
        guard let pointOfView = sceneView.pointOfView else { return }
        let transform               = pointOfView.transform
        let orientation             = SCNVector3(-transform.m31, -transform.m32, -transform.m33)
        let location                = SCNVector3(transform.m41, transform.m42, transform.m43)
        let currentPositionOfCamera = orientation + location
        
        let scene   = SCNScene(named: "CarScene.scn")
        let frame = scene?.rootNode.childNode(withName: "frame", recursively: false) ?? SCNNode()
        frame.position = currentPositionOfCamera
        
        let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: frame,
                                                                         options: [SCNPhysicsShape.Option.keepAsCompound: true]))
        frame.physicsBody = body
        
        let v_frontLeftWheel  = SCNPhysicsVehicleWheel(node: frame.childNode(withName: "frontLeftParent",
                                                                             recursively: false) ?? SCNNode())
        let v_frontRightWheel = SCNPhysicsVehicleWheel(node: frame.childNode(withName: "frontRightParent",
                                                                             recursively: false) ?? SCNNode())
        let v_rearLeftWheel   = SCNPhysicsVehicleWheel(node: frame.childNode(withName: "rearLeftParent",
                                                                             recursively: false) ?? SCNNode())
        let v_rearRightWheel  = SCNPhysicsVehicleWheel(node: frame.childNode(withName: "rearRightParent",
                                                                             recursively: false) ?? SCNNode())
        
        
        self.vehicle = SCNPhysicsVehicle(chassisBody: frame.physicsBody ?? SCNPhysicsBody(),
                                         wheels: [v_rearLeftWheel, v_rearRightWheel,
                                                  v_frontLeftWheel, v_frontRightWheel])
        sceneView.scene.physicsWorld.addBehavior(self.vehicle)
        sceneView.scene.rootNode.addChildNode(frame)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: TimeInterval) {
        self.vehicle.setSteeringAngle(orientation, forWheelAt: 2)
        self.vehicle.setSteeringAngle(orientation, forWheelAt: 3)
    }
    
    func setupAccelerometer() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 1/60
            motionManager.startAccelerometerUpdates(to: .main) { (accelerometerData, error) in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                if let acceleration = accelerometerData?.acceleration {
                    self.accelerometerDidChange(acceleration: acceleration)
                }
            }
        } else {
            print("Accelerometer not available.")
        }
    }
    
    func accelerometerDidChange(acceleration: CMAcceleration) {
        if acceleration.x > 0 {
            self.orientation = -CGFloat(acceleration.y)
        } else {
            self.orientation = CGFloat(acceleration.y)
        }
    }
    
}

extension Int {
    var degreesToRadians: Double { return Double(self) * .pi/180}
}

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}

