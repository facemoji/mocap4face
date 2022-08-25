/*
 See LICENSE.md for this sample’s licensing information.
*/

import UIKit
import SceneKit
import CoreMedia
import AVFoundation
import MetalKit
import Mocap4Face

#if targetEnvironment(simulator)
    #error("This demo app can only be run on a real iOS device because iOS simulators do not support camera input. The SDK itself works in the simulator, you just need to feed it pre-recorded videos or images.")
#endif

class ViewController: UIViewController, VideoCaptureDelegate, SCNSceneRendererDelegate {
    @IBOutlet weak var cameraViewContainer: UIView!
    @IBOutlet weak var tableView: UICollectionView!
    @IBOutlet weak var lblText: UILabel!
    @IBOutlet weak var cameraSwitchButtonBlur: UIVisualEffectView!

    private let tableSource = TableDataSource()
    
    var cameraView: MetalTextureView!
    var tracker: Future<FaceTracker?>!
    var capture: VideoCapture!
    
    private var tableViewWidth: CGFloat = 0
    
    // Hide the home button for a clearer view
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create face tracker
        tracker = FaceTracker.createVideoTracker()
            .logError("Error loading tracker")
        
        tracker.whenDone { t in
            // Called when the tracker finishes loading
            if let tracker = t {
                DispatchQueue.main.async {
                    // Pre-fill blendshape coefficient names to the table view
                    self.tableSource.setBlendshapeNames(tracker.blendshapeNames + ViewController.faceRotationToSliders(Quaternion.identity).keys)
                }
            }
        }
        
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .dark
        }
        
        // Start camera feed
        capture = VideoCapture()
        capture.delegate = self
        capture.startCamera(position: .front)
        
        cameraView = MetalTextureView(frame: cameraViewContainer.bounds)
        cameraView.device = (cameraView.device ?? MTLCreateSystemDefaultDevice()!)
        cameraViewContainer.addSubview(cameraView)
               
        tableView?.dataSource = tableSource
        tableView?.delegate = self
        
        cameraSwitchButtonBlur.layer.cornerRadius = 22
        cameraSwitchButtonBlur.clipsToBounds = true
        
        cameraViewContainer.alpha = 0
        cameraSwitchButtonBlur.alpha = 0
        tableView.alpha = 0
        view.backgroundColor = UIColor(red: 0, green: 1, blue: 204.0/255.0, alpha: 1)
        
        UIView.animate(withDuration: 1, animations: {
            self.view.backgroundColor = UIColor.black
        }, completion: {result in
            UIView.animate(withDuration: 1) {
                self.cameraViewContainer.alpha = 1
                self.cameraSwitchButtonBlur.alpha = 1
                self.tableView.alpha = 1
            }
        })
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        organizeViews()
        if self.cameraViewContainer.frame != cameraViewContainer.frame {
            self.cameraViewContainer.frame = cameraViewContainer.frame
        }
    }
    
    /// Called when a new camera frame arrives
    func sampleBufferAvailable(_ buffer: CMSampleBuffer, brightness: CGFloat) {
        guard case let tracker?? = tracker.currentValue else {
            // Face tracker not initialized yet
            return
        }

        // Run the face tracker and get the facial coefficients
        let result = tracker.track(buffer)
        
        // Update camera preview in the UI
        cameraView.setSampleBuffer(buffer)
        
        DispatchQueue.main.async { [weak self] in
            UIView.performWithoutAnimation {
                if let result = result {
                    self?.tableSource.setData(
                        // Show blendshapes and also convert head rotation to blendshape-like values
                        result.blendshapes.merging(ViewController.faceRotationToSliders(result.rotationQuaternion), uniquingKeysWith: { $1 } )
                    )
                } else {
                    self?.tableSource.setData([:])
                }
                self?.tableView?.reloadData()
            }
        }
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        organizeViews()
    }
    
    /// Adjusts views for portrait/landscape
    func organizeViews() {
        
        let screenBounds = UIScreen.main.bounds
        let buttonWidth = cameraSwitchButtonBlur.frame.width
        let buttonMargin: CGFloat = 20
        let safeAreaInsets = self.view.safeAreaInsets
        
        if UIDevice.current.orientation.isLandscape {
            let homeRight = UIDevice.current.orientation == .landscapeLeft
            let cameraViewWidth = max(screenBounds.height, screenBounds.width * 0.55)
            cameraViewContainer.frame = CGRect(x: 0, y: safeAreaInsets.top, width: cameraViewWidth, height: screenBounds.height)
            tableViewWidth = screenBounds.width - cameraViewWidth - (homeRight ? 0 : (safeAreaInsets.right))
            tableView?.frame = CGRect(x: cameraViewWidth, y: safeAreaInsets.top, width: tableViewWidth, height: screenBounds.height)
            cameraSwitchButtonBlur.frame = CGRect(x: cameraViewWidth - buttonWidth - buttonMargin, y: screenBounds.height - buttonWidth - buttonMargin, width: cameraSwitchButtonBlur.frame.width, height: cameraSwitchButtonBlur.frame.height)
        } else {
            lblText.frame = CGRect(x: safeAreaInsets.left + 20, y: safeAreaInsets.top + 20, width: screenBounds.width - 40, height: lblText.bounds.height)
            cameraViewContainer.frame = CGRect(x: safeAreaInsets.left, y: safeAreaInsets.top, width: screenBounds.width, height: screenBounds.width)
            tableViewWidth = screenBounds.width - safeAreaInsets.left - safeAreaInsets.right
            tableView?.frame = CGRect(x: safeAreaInsets.left, y: screenBounds.width + safeAreaInsets.top, width: tableViewWidth, height: screenBounds.height - screenBounds.width - safeAreaInsets.top - safeAreaInsets.bottom)
            cameraSwitchButtonBlur.frame = CGRect(x: screenBounds.width - buttonWidth - buttonMargin, y: screenBounds.width + safeAreaInsets.top - buttonWidth - buttonMargin, width: cameraSwitchButtonBlur.frame.width, height: cameraSwitchButtonBlur.frame.height)
        }
        cameraView.frame = CGRect(x: 0, y: 0, width: cameraViewContainer.bounds.width, height: cameraViewContainer.bounds.height)
        
        lblText.isHidden = true
    }
    
    
    /// Called when user taps the switch camera button
    func switchCameras() {
        capture.startCamera(position: capture.position == .front ? .back : .front)
    }
    
    /// Converts face rotation to blendshape-like sliders for displaying them in the UI
    static func faceRotationToSliders(_ rotation: Quaternion) -> [String:Float] {
        let euler = rotation.toEuler()
        let halfPi = Float.pi * 0.5
        return [
            "headLeft": max(0, euler.y) / halfPi,
            "headRight": -min(0, euler.y) / halfPi,
            "headUp": -min(0, euler.x) / halfPi,
            "headDown": max(0, euler.x) / halfPi,
            "headRollLeft": -min(0, euler.z) / halfPi,
            "headRollRight": max(0, euler.z) / halfPi,
        ]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startOrientationListening()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        endOrientationListening()
    }
    @IBAction func onSwitchCameraClick(_ sender: Any) {
        switchCameras()
    }
    
    func startOrientationListening() {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(onOrientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    func endOrientationListening() {
        NotificationCenter.default.removeObserver(self)
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }
    
    @objc func onOrientationChanged() {
        DispatchQueue.main.async { [weak self] in
            self?.capture.changeOrientation()
            self?.organizeViews()
        }
    }
    
}

extension ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: tableViewWidth, height: 20)
    }
}


