//
//  ViewController.swift
//  Eyes Tracking
//
//  Created by Shaheed Ahmed Dewan Sagar
//  Copyright © 2019 shaheed. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import WebKit
import FirebaseFirestore
import FirebaseAuth
import Mute
import AVFoundation

class ViewController: UIViewController
    , ARSCNViewDelegate
    , ARSessionDelegate
    , UIGestureRecognizerDelegate
    , UIScrollViewDelegate
    , WKNavigationDelegate
{

    @IBOutlet weak var webView: WKWebView!
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var eyePositionIndicatorView: UIView!
    @IBOutlet weak var eyePositionIndicatorCenterView: UIView!
    @IBOutlet weak var blurBarView: UIVisualEffectView!
    @IBOutlet weak var lookAtPositionXLabel: UILabel!
    @IBOutlet weak var lookAtPositionYLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var actionLabel: UILabel!
    @IBOutlet weak var distractedTimeLabel: UILabel!
    @IBOutlet weak var bottomStackView: UIStackView!
    @IBOutlet weak var topProgressBar: UIProgressView!
    @IBOutlet weak var trainingDotView: UIView!
    @IBOutlet weak var trainerBackgroundView: UIView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!
    
    var stopUpdating = false
    
    var isDistracted = false
    var distractedTime = 0
    var distractedTimeStarts = 0
    var distractedTimeEnds = 0
    var participantIdAsked = false
    
    var lastSavedUrl = ""
    var participantId = ""
    
    let startWarningAlert = UIAlertController(title: "Prepare for test", message: "Test will start in 5 second(s)", preferredStyle: .alert)
    var startTimerCount = 5
    var trainingTimerCount = 0
    var startTimerSheduler: Timer?
    var trainingTimerSheduler: Timer?
    
    var trainingDotPosition = 0
    let trainingDotPositions = [
        [4, 6],
        [164, 6],
        [320, 6],
        [320, 339],
        [320, 704],
        [164, 704],
        [4, 704],
        [4, 339]
    ]
    
    var staticPaddingAround = CGFloat(100)
    
    var eyePositions1: [ [Int] ] = []
    var eyePositions2: [ [Int] ] = []
    var eyePositions3: [ [Int] ] = []
    var eyePositions4: [ [Int] ] = []
    var eyePositions5: [ [Int] ] = []
    var eyePositions6: [ [Int] ] = []
    var eyePositions7: [ [Int] ] = []
    var eyePositions8: [ [Int] ] = []
    
    var eyeTrainingXvalues: [CGFloat] = []
    var eyeTrainingYvalues: [CGFloat] = []
    
    var trainingXMin: CGFloat = CGFloat(0)
    var trainingXMax: CGFloat = CGFloat(0)
    var trainingYMin: CGFloat = CGFloat(0)
    var trainingYMax: CGFloat = CGFloat(0)
    
    var activities: [Activity] = []
    var dbSessionId: String = ""
    var dbReady = false
    
    var faceNode: SCNNode = SCNNode()
    
    var eyeLNode: SCNNode = {
        let geometry = SCNCone(topRadius: 0.005, bottomRadius: 0, height: 0.2)
        geometry.radialSegmentCount = 3
        geometry.firstMaterial?.diffuse.contents = UIColor.blue
        let node = SCNNode()
        node.geometry = geometry
        node.eulerAngles.x = -.pi / 2
        node.position.z = 0.1
        let parentNode = SCNNode()
        parentNode.addChildNode(node)
        return parentNode
    }()
    
    var eyeRNode: SCNNode = {
        let geometry = SCNCone(topRadius: 0.005, bottomRadius: 0, height: 0.2)
        geometry.radialSegmentCount = 3
        geometry.firstMaterial?.diffuse.contents = UIColor.blue
        let node = SCNNode()
        node.geometry = geometry
        node.eulerAngles.x = -.pi / 2
        node.position.z = 0.1
        let parentNode = SCNNode()
        parentNode.addChildNode(node)
        return parentNode
    }()
    
    var lookAtTargetEyeLNode: SCNNode = SCNNode()
    var lookAtTargetEyeRNode: SCNNode = SCNNode()
    
    // actual physical size of iPhoneX screen
    let phoneScreenSize = CGSize(width: 0.0623908297, height: 0.135096943231532)
    
    // actual point size of iPhoneX screen
    let phoneScreenPointSize = CGSize(width: 375, height: 812)
    
    var virtualPhoneNode: SCNNode = SCNNode()
    
    var virtualScreenNode: SCNNode = {
        
        let screenGeometry = SCNPlane(width: 1, height: 1)
        screenGeometry.firstMaterial?.isDoubleSided = true
        screenGeometry.firstMaterial?.diffuse.contents = UIColor.green
        
        return SCNNode(geometry: screenGeometry)
    }()
    
    var eyeLookAtPositionXs: [CGFloat] = []
    
    var eyeLookAtPositionYs: [CGFloat] = []
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    let activityFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    var muted = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.topProgressBar.tintColor = UIColor.blue
        
        let tapGestureForwardButton = UITapGestureRecognizer(target: self, action: #selector (forwardButtonPressedTap))
        let longGestureForwardButton = UILongPressGestureRecognizer(target: self, action: #selector(forwardButtonPressedLongTap))
        tapGestureForwardButton.numberOfTapsRequired = 1
        forwardButton.addGestureRecognizer(tapGestureForwardButton)
        forwardButton.addGestureRecognizer(longGestureForwardButton)
        
        // initializing heptic feedback generators
        activityFeedbackGenerator.prepare()
        Mute.shared.checkInterval = 5.0
        Mute.shared.alwaysNotify = true
        Mute.shared.notify = { [weak self] m in
            self?.muted = m
        }
        
        WKWebView.clean()
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.load(URLRequest(url: URL(string: "https://www.google.ca/")!))
        self.lastSavedUrl = "https://www.google.ca/"
        
        // initialize touch detector on screen
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTouchOnScreen) )
        tapGesture.numberOfTapsRequired = 1
        tapGesture.delegate = self
        webView.addGestureRecognizer(tapGesture)
        
        webView.scrollView.delegate = self
        
        // Setup Design Elements
        eyePositionIndicatorView.layer.cornerRadius = eyePositionIndicatorView.bounds.width / 2
        sceneView.layer.cornerRadius = 28
        eyePositionIndicatorCenterView.layer.cornerRadius = 4
        
        blurBarView.layer.cornerRadius = 36
        blurBarView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        webView.layer.cornerRadius = 16
        webView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        
        // Setup Scenegraph
        sceneView.scene.rootNode.addChildNode(faceNode)
        sceneView.scene.rootNode.addChildNode(virtualPhoneNode)
        virtualPhoneNode.addChildNode(virtualScreenNode)
        faceNode.addChildNode(eyeLNode)
        faceNode.addChildNode(eyeRNode)
        eyeLNode.addChildNode(lookAtTargetEyeLNode)
        eyeRNode.addChildNode(lookAtTargetEyeRNode)
        
        // Set LookAtTargetEye at 2 meters away from the center of eyeballs to create segment vector
        lookAtTargetEyeLNode.position.z = 2
        lookAtTargetEyeRNode.position.z = 2
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if (!self.participantIdAsked) {
            self.askParticipantId()
            self.participantIdAsked = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        
        // Run the view's session
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pause the view's session
        sceneView.session.pause()
    }
    
    func askParticipantId() {
        let pidAlert = UIAlertController(title: "Participant Id", message: "Please enter your participant id", preferredStyle: UIAlertController.Style.alert)
        let action = UIAlertAction(title: "Save", style: .default) { (alertAction) in
            let textField = pidAlert.textFields![0] as UITextField
            self.participantId = textField.text!
            print("ParticipantID: \(self.participantId)")
            self.startTimer()
        }
        pidAlert.addTextField { (textField) in
            textField.placeholder = ""
        }
        
        pidAlert.addAction(action)
        self.present(pidAlert, animated:true, completion: nil)
    }
    
    func initializeFirestoreDB() {
        if (Auth.auth().currentUser == nil) {
            Auth.auth().signInAnonymously(completion: { (authDataResult, error) in
                print("@shaheed signed in to firebase")
                if (error != nil) {
                    print("@shaheed Error on Firebase Auth: \(error.debugDescription)")
                }
                self.registerNewSession()
            })
        } else {
            self.registerNewSession()
        }
    }
    
    func registerNewSession() {
        
        var reference: DocumentReference? = nil
        reference = Firestore.firestore().collection("tests").addDocument(data: [
            "participantId": self.participantId,
            "activities": self.activities,
            "createdAt": self.getCurrentTimeInMillis()
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added with ID: \(reference!.documentID)")
                self.dbSessionId = reference!.documentID
            }
        }
    }
    
    func getCurrentTimeInMillis() -> Int {
        return Int(NSDate().timeIntervalSince1970 * 1000)
    }
    
    func startTimer() {
        self.initializeFirestoreDB()
        startTimerSheduler = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateCounting), userInfo: nil, repeats: true)
        self.present(startWarningAlert, animated: true, completion: nil)
    }
    
    @objc func updateCounting(){
        print("counting..\(self.startTimerCount)")
        
        if (self.startTimerCount >= 0) {
            self.startWarningAlert.message = "Test will start in \(self.startTimerCount) second(s)"
            self.startTimerCount -= 1
        } else {
            self.startTimerSheduler?.invalidate()
            self.startTimerSheduler = nil
            self.startWarningAlert.dismiss(animated: true, completion: nil)
            self.markDBReady()
        }
    }
    
    func hideUnnecessaryUI() {
        UIView.animate(withDuration: 2) {
            self.sceneView.alpha = 0
            self.eyePositionIndicatorView.alpha = 0
            self.eyePositionIndicatorCenterView.alpha = 0
            self.blurBarView.alpha = 0
            self.bottomStackView.alpha = 0
            
            self.trainerBackgroundView.alpha = 0
            self.trainingDotView.alpha = 0
            
            self.backButton.alpha = 1
            self.forwardButton.alpha = 1
        }
    }
    
    func markDBReady() {
        if (!self.dbSessionId.isEmpty) {
            self.dbReady = true
            self.trainEyeTracker()
        } else {
            print("@shaheed error on initializing DB!")
            let alert = UIAlertController(title: "Failed", message: "Could not register new session!", preferredStyle: .alert)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func trainEyeTracker() {
        trainingTimerSheduler = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.trainingOngoing), userInfo: nil, repeats: true)
    }
    
    @objc func trainingOngoing() {
        self.trainingTimerCount += 1
        print("counting..\(self.trainingTimerCount)")
        
        if (self.trainingTimerCount % 3 == 0) {
            print("change position")
            UIView.animate(withDuration: 0.1) {
                self.trainingDotView.frame.origin.x = CGFloat(self.trainingDotPositions[self.trainingDotPosition][0])
                self.trainingDotView.frame.origin.y = CGFloat(self.trainingDotPositions[self.trainingDotPosition][1])
            }
            
            self.trainingDotPosition += 1
            if self.trainingDotPosition >= self.trainingDotPositions.count {
                self.trainingDotPosition = self.trainingDotPositions.count - 1
            }
        }
        
        if (self.trainingTimerCount >= 27) {
            self.trainingTimerSheduler?.invalidate()
            self.trainingTimerSheduler = nil
            
//            print("@stats eye 1 x \(self.findEyeLocationAvg(forList: self.eyePositions1, forPosition: 0))")
//            print("@stats eye 1 y \(self.findEyeLocationAvg(forList: self.eyePositions1, forPosition: 1))")
//
//            print("@stats eye 2 x \(self.findEyeLocationAvg(forList: self.eyePositions2, forPosition: 0))")
//            print("@stats eye 2 y \(self.findEyeLocationAvg(forList: self.eyePositions2, forPosition: 1))")
//
//            print("@stats eye 3 x \(self.findEyeLocationAvg(forList: self.eyePositions3, forPosition: 0))")
//            print("@stats eye 3 y \(self.findEyeLocationAvg(forList: self.eyePositions3, forPosition: 1))")
//
//            print("@stats eye 4 x \(self.findEyeLocationAvg(forList: self.eyePositions4, forPosition: 0))")
//            print("@stats eye 4 y \(self.findEyeLocationAvg(forList: self.eyePositions4, forPosition: 1))")
//
//            print("@stats eye 5 x \(self.findEyeLocationAvg(forList: self.eyePositions5, forPosition: 0))")
//            print("@stats eye 5 y \(self.findEyeLocationAvg(forList: self.eyePositions5, forPosition: 1))")
//
//            print("@stats eye 6 x \(self.findEyeLocationAvg(forList: self.eyePositions6, forPosition: 0))")
//            print("@stats eye 6 y \(self.findEyeLocationAvg(forList: self.eyePositions6, forPosition: 1))")
//
//            print("@stats eye 7 x \(self.findEyeLocationAvg(forList: self.eyePositions7, forPosition: 0))")
//            print("@stats eye 7 y \(self.findEyeLocationAvg(forList: self.eyePositions7, forPosition: 1))")
//
//            print("@stats eye 8 x \(self.findEyeLocationAvg(forList: self.eyePositions8, forPosition: 0))")
//            print("@stats eye 8 y \(self.findEyeLocationAvg(forList: self.eyePositions8, forPosition: 1))")
            self.eyeTrainingXvalues.append(self.findEyeLocationAvg(forList: self.eyePositions1, forPosition: 0))
            self.eyeTrainingXvalues.append(self.findEyeLocationAvg(forList: self.eyePositions2, forPosition: 0))
            self.eyeTrainingXvalues.append(self.findEyeLocationAvg(forList: self.eyePositions3, forPosition: 0))
            self.eyeTrainingXvalues.append(self.findEyeLocationAvg(forList: self.eyePositions4, forPosition: 0))
            self.eyeTrainingXvalues.append(self.findEyeLocationAvg(forList: self.eyePositions5, forPosition: 0))
            self.eyeTrainingXvalues.append(self.findEyeLocationAvg(forList: self.eyePositions6, forPosition: 0))
            self.eyeTrainingXvalues.append(self.findEyeLocationAvg(forList: self.eyePositions7, forPosition: 0))
            self.eyeTrainingXvalues.append(self.findEyeLocationAvg(forList: self.eyePositions8, forPosition: 0))
            
            self.eyeTrainingYvalues.append(self.findEyeLocationAvg(forList: self.eyePositions1, forPosition: 1))
            self.eyeTrainingYvalues.append(self.findEyeLocationAvg(forList: self.eyePositions2, forPosition: 1))
            self.eyeTrainingYvalues.append(self.findEyeLocationAvg(forList: self.eyePositions3, forPosition: 1))
            self.eyeTrainingYvalues.append(self.findEyeLocationAvg(forList: self.eyePositions4, forPosition: 1))
            self.eyeTrainingYvalues.append(self.findEyeLocationAvg(forList: self.eyePositions5, forPosition: 1))
            self.eyeTrainingYvalues.append(self.findEyeLocationAvg(forList: self.eyePositions6, forPosition: 1))
            self.eyeTrainingYvalues.append(self.findEyeLocationAvg(forList: self.eyePositions7, forPosition: 1))
            self.eyeTrainingYvalues.append(self.findEyeLocationAvg(forList: self.eyePositions8, forPosition: 1))
            
            self.updateTrainingMinMaxWithPadding()
            
            print("@stats eye x avg min: \(trainingXMin)")
            print("@stats eye x avg max: \(trainingXMax)")
            
            print("@stats eye y avg min: \(trainingYMin)")
            print("@stats eye y avg max: \(trainingYMax)")
            
            hideUnnecessaryUI()
            self.activities.removeAll()
        }
    }
    
    func findEyeLocationAvg(forList list: [[Int]], forPosition pos: Int) -> CGFloat {
        var total = 0
        for element in list {
            total += element[pos]
        }
        return CGFloat(total/list.count)
    }

    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        faceNode.transform = node.transform
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        
        update(withFaceAnchor: faceAnchor)
    }
    
    // MARK: - update(ARFaceAnchor)
    
    func update(withFaceAnchor anchor: ARFaceAnchor) {
        
        if self.stopUpdating {
            return
        }
        
        eyeRNode.simdTransform = anchor.rightEyeTransform
        eyeLNode.simdTransform = anchor.leftEyeTransform
        
        var eyeLLookAt = CGPoint()
        var eyeRLookAt = CGPoint()
        
        let heightCompensation: CGFloat = 312
        
        DispatchQueue.main.async {

            // Perform Hit test using the ray segments that are drawn by the center of the eyeballs to somewhere two meters away at direction of where users look at to the virtual plane that place at the same orientation of the phone screen
            
            let phoneScreenEyeRHitTestResults = self.virtualPhoneNode.hitTestWithSegment(from: self.lookAtTargetEyeRNode.worldPosition, to: self.eyeRNode.worldPosition, options: nil)
            
            let phoneScreenEyeLHitTestResults = self.virtualPhoneNode.hitTestWithSegment(from: self.lookAtTargetEyeLNode.worldPosition, to: self.eyeLNode.worldPosition, options: nil)
            
            for result in phoneScreenEyeRHitTestResults {
                
                eyeRLookAt.x = CGFloat(result.localCoordinates.x) / (self.phoneScreenSize.width / 2) * self.phoneScreenPointSize.width
                
                eyeRLookAt.y = CGFloat(result.localCoordinates.y) / (self.phoneScreenSize.height / 2) * self.phoneScreenPointSize.height + heightCompensation
            }
            
            for result in phoneScreenEyeLHitTestResults {
                
                eyeLLookAt.x = CGFloat(result.localCoordinates.x) / (self.phoneScreenSize.width / 2) * self.phoneScreenPointSize.width
                
                eyeLLookAt.y = CGFloat(result.localCoordinates.y) / (self.phoneScreenSize.height / 2) * self.phoneScreenPointSize.height + heightCompensation
            }
            
            // Add the latest position and keep up to 8 recent position to smooth with.
            let smoothThresholdNumber: Int = 10
            self.eyeLookAtPositionXs.append((eyeRLookAt.x + eyeLLookAt.x) / 2)
            self.eyeLookAtPositionYs.append(-(eyeRLookAt.y + eyeLLookAt.y) / 2)
            self.eyeLookAtPositionXs = Array(self.eyeLookAtPositionXs.suffix(smoothThresholdNumber))
            self.eyeLookAtPositionYs = Array(self.eyeLookAtPositionYs.suffix(smoothThresholdNumber))
            
            let smoothEyeLookAtPositionX = self.eyeLookAtPositionXs.average!
            let smoothEyeLookAtPositionY = self.eyeLookAtPositionYs.average!
            
            // update indicator position
            self.eyePositionIndicatorView.transform = CGAffineTransform(translationX: smoothEyeLookAtPositionX - self.trainingXMin, y: smoothEyeLookAtPositionY - self.trainingYMin)
            
            // update eye look at labels values
            let xValue = Int(round(smoothEyeLookAtPositionX + self.phoneScreenPointSize.width / 2))
            let yValue = Int(round(smoothEyeLookAtPositionY + self.phoneScreenPointSize.height / 2))
            self.lookAtPositionXLabel.text = "\(xValue)"
            
            self.lookAtPositionYLabel.text = "\(yValue)"
            
            // save eye positions for training
            if self.trainingTimerCount >= 2 && self.trainingTimerCount <= 3 {
                self.eyePositions1.append([ xValue, yValue ])
            }
            
            if self.trainingTimerCount >= 5 && self.trainingTimerCount <= 6 {
                self.eyePositions2.append([ xValue, yValue ])
            }
            
            if self.trainingTimerCount >= 8 && self.trainingTimerCount <= 9 {
                self.eyePositions3.append([ xValue, yValue ])
            }
            
            if self.trainingTimerCount >= 11 && self.trainingTimerCount <= 12 {
                self.eyePositions4.append([ xValue, yValue ])
            }
            
            if self.trainingTimerCount >= 14 && self.trainingTimerCount <= 15 {
                self.eyePositions5.append([ xValue, yValue ])
            }
            
            if self.trainingTimerCount >= 17 && self.trainingTimerCount <= 18 {
                self.eyePositions6.append([ xValue, yValue ])
            }
            
            if self.trainingTimerCount >= 20 && self.trainingTimerCount <= 21 {
                self.eyePositions7.append([ xValue, yValue ])
            }
            
            if self.trainingTimerCount >= 23 && self.trainingTimerCount <= 24 {
                self.eyePositions8.append([ xValue, yValue ])
            }
            
            // Calculate distance of the eyes to the camera
            let distanceL = self.eyeLNode.worldPosition - SCNVector3Zero
            let distanceR = self.eyeRNode.worldPosition - SCNVector3Zero
            
            // Average distance from two eyes
            let distance = (distanceL.length() + distanceR.length()) / 2
            
            // Update distance label value
            let roundedDistance = Int(round(distance * 100))
            self.distanceLabel.text = "\(roundedDistance) cm"
            
            if ((xValue < Int(self.trainingXMin) || xValue > Int(self.trainingXMax) && (yValue < Int(self.trainingYMin) || yValue > Int(self.trainingYMax))) && !self.isDistracted) {
                self.actionLabel.text = "Distracted"
                self.distractedTimeStarts = Int(NSDate().timeIntervalSince1970 * 1000)
                self.isDistracted = true
                print("@shaheed start: \(self.distractedTimeStarts)")
                
                if (self.dbReady) {
                    let activity = Activity.init(type: Activity.TYPE_DISTRACTED,
                                                 timeStamp: self.getCurrentTimeInMillis(),
                                                 metaData: [
                                                    "eyeX": xValue,
                                                    "eyeY": yValue,
                                                    "eyeDistance": roundedDistance
                        ]
                    )
                    self.activities.append(activity)
                    if (!self.muted) {
                        self.activityFeedbackGenerator.impactOccurred()
                        AudioServicesPlayAlertSound(SystemSoundID(1106))
                    }
                }
                self.topProgressBar.tintColor = UIColor.red
            }
            
            if ((xValue > Int(self.trainingXMin) && xValue < Int(self.trainingXMax) && (yValue > Int(self.trainingYMin) && yValue < Int(self.trainingYMax))) && self.isDistracted) {
                self.actionLabel.text = "On Screen"
                self.distractedTimeEnds = Int(NSDate().timeIntervalSince1970 * 1000)
                self.isDistracted = false
                print("@shaheed ends: \(self.distractedTimeEnds)")
                if (self.dbReady) {
                    let activity = Activity.init(type: Activity.TYPE_LOOKING,
                                                 timeStamp: self.getCurrentTimeInMillis(),
                                                 metaData: [
                                                    "eyeX": xValue,
                                                    "eyeY": yValue,
                                                    "eyeDistance": roundedDistance
                        ]
                    )
                    self.activities.append(activity)
                    if (!self.muted) {
                        self.activityFeedbackGenerator.impactOccurred()
                        AudioServicesPlayAlertSound(SystemSoundID(1106))
                    }
                }
                self.topProgressBar.tintColor = UIColor.blue
                
                self.distractedTime = self.distractedTimeEnds - self.distractedTimeStarts
                print("@shaheed distracted: \(self.distractedTime) ms")
                self.distractedTimeLabel.text = "Time Distracted: \(self.distractedTime) ms"
            }
        }
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        virtualPhoneNode.transform = (sceneView.pointOfView?.transform)!
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        faceNode.transform = node.transform
        guard let faceAnchor = anchor as? ARFaceAnchor else {
            return
        }
        update(withFaceAnchor: faceAnchor)
    }
    
    // touch detection implementation
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        print("@shaheed scroll detected end dragging")
        self.actionLabel.text = "Scrolling detected"
        
        if (self.dbReady) {
            let activity = Activity.init(type: Activity.TYPE_SCROLL, timeStamp: self.getCurrentTimeInMillis(), metaData: ["offset": scrollView.contentOffset.y])
            self.activities.append(activity)
//            if (!self.muted) {
//                self.activityFeedbackGenerator.impactOccurred()
//                AudioServicesPlayAlertSound(SystemSoundID(1106))
//            }
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @objc func handleTouchOnScreen(touch: UITapGestureRecognizer) {
        print("@shaheed touch detected")
        self.actionLabel.text = "Touch detected"
        
        let touchPoint = touch.location(in: self.webView);
        
        if (self.dbReady) {
            let activity = Activity.init(type: Activity.TYPE_TAP, timeStamp: self.getCurrentTimeInMillis(), metaData: [
                "touchX": touchPoint.x,
                "touchY": touchPoint.y
                ])
            self.activities.append(activity)
//            if (!self.muted) {
//                self.activityFeedbackGenerator.impactOccurred()
//                AudioServicesPlayAlertSound(SystemSoundID(1106))
//            }
        }
    }
    
    // MARK: WKNavigationDelegate
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // print("@shaheed wk url:\(navigationAction.request.url?.absoluteString)")
        // checking and saving if url is changed
        print("@shaheed lastURL:\(self.lastSavedUrl)")
        print("@shaheed newURL:\(self.webView.url?.absoluteString ?? "failed to get url")")
        if (self.dbReady && self.webView.url?.absoluteString.caseInsensitiveCompare(lastSavedUrl) != .orderedSame) {
            let activity = Activity.init(type: Activity.TYPE_URL_CHANGE, timeStamp: self.getCurrentTimeInMillis(), metaData: [
                "fromURL": self.lastSavedUrl,
                "toURL": self.webView.url!.absoluteString
                ])
            self.activities.append(activity)
//            if (!self.muted) {
//                self.activityFeedbackGenerator.impactOccurred()
//                AudioServicesPlayAlertSound(SystemSoundID(1106))
//            }
            self.lastSavedUrl = self.webView.url?.absoluteString ?? "failed to get url"
        }
        decisionHandler(.allow)
    }
    
    // MARK: Buttons
    @objc func forwardButtonPressedTap() {
        print("TAP")
        if (self.webView.canGoForward) {
            self.webView.goForward()
        }
    }
    
    func updateTrainingMinMaxWithPadding() {
        self.trainingXMin = self.eyeTrainingXvalues.min()! - self.staticPaddingAround
        self.trainingXMax = self.eyeTrainingXvalues.max()! + self.staticPaddingAround
        
        self.trainingYMin = self.eyeTrainingYvalues.min()! - self.staticPaddingAround
        self.trainingYMax = self.eyeTrainingYvalues.max()! + self.staticPaddingAround
    }
    
    @objc func forwardButtonPressedLongTap() {
        print("LONG TAP")
        let alert = UIAlertController(title: "Change padding", message: "Current padding: \(self.staticPaddingAround) px", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Low", style: .default , handler:{ (UIAlertAction) in
            
            self.staticPaddingAround = CGFloat(100)
            self.updateTrainingMinMaxWithPadding()
            
        }))
        
        alert.addAction(UIAlertAction(title: "Medium", style: .default , handler:{ (UIAlertAction) in
            
            self.staticPaddingAround = CGFloat(160)
            self.updateTrainingMinMaxWithPadding()
            
        }))
        
        alert.addAction(UIAlertAction(title: "High", style: .default , handler:{ (UIAlertAction) in
            
            self.staticPaddingAround = CGFloat(210)
            self.updateTrainingMinMaxWithPadding()
            
        }))
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler:{ (UIAlertAction) in
            print("Dismissed")
        }))
        
        self.present(alert, animated: true, completion: {
            print("Padding update done")
        })
    }
    
    
    @IBAction func backButtonPressed(_ sender: Any) {
        self.webView.goBack()
    }
    
}
