//
//  ViewController.swift
//  Graph-Swift
//
//  Created by Rohan Kotwani on 6/8/17.
//  Copyright © 2017 Rohan Kotwani. All rights reserved.
//


import UIKit
import AVFoundation
import CoreMotion

// CameraUtil.swift
import Foundation


struct CPoint {
    let x: CDouble
    let y: CDouble
}

class CameraUtil {
    class func imageFromSampleBuffer(buffer: CMSampleBuffer) -> UIImage {
        let pixelBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(buffer)!
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        let pixelBufferWidth = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let pixelBufferHeight = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        let imageRect: CGRect = CGRectMake(0, 0, pixelBufferWidth, pixelBufferHeight)
        let ciContext = CIContext.init()
        

        let cgimage = ciContext.createCGImage(ciImage, from: imageRect )
        
        let image = UIImage(cgImage: cgimage!)
        return image
    }
    
    class func CGRectMake(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    
}





struct AppUtility {
    
    static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.orientationLock = orientation
        }
    }
    
    /// OPTIONAL Added method to adjust lock and rotate to the desired orientation
    static func lockOrientation(_ orientation: UIInterfaceOrientationMask, andRotateTo rotateOrientation:UIInterfaceOrientation) {
        
        self.lockOrientation(orientation)
        
        UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
    }
    
}




class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate,  UIGestureRecognizerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var sensitivity: UISlider!
    
    //    @IBOutlet weak var camera_settings: UISwitch!
    
    
    func registerSettingsBundle(){
        let appDefaults = [String:AnyObject]()
        UserDefaults.standard.register(defaults: appDefaults)
    }
    
    var camera_set = AVCaptureDevice.Position.back
    var pinchGesture = UILongPressGestureRecognizer()
    var session : AVCaptureSession!
    var device : AVCaptureDevice!
    var input: AVCaptureDeviceInput?
    var output : AVCaptureVideoDataOutput!
    var framecount  = 0
    var total_savecount = 0
    var save_rate_gate = 0
    var savecount_motion = 0
    var savecount_object = 0
    var newimage: UIImage!
    
    let opencv = OpenCVWrapper()
    
    var take_motion_photo_flag = false
    var object_photo_flag = false
    
    var radius_history = 0.0
    var focus_x = 4.0
    var focus_y = 3.0
    var shift_x = 0.0
    var shift_y = 0.0
    
    var motion_correction = true
    var desiredZoomFactor: CGFloat = 0.0;
    var object = false;
    
    var isIphone=false;
    var isIpad=false;
    
    var timer:Timer?

    var roll = 0.0;
    var yaw = 0.0;
    var pitch = 0.0;
    
    func firstUpdateDisplayFromDefaults(){
        //Get the defaults
        let defaults = UserDefaults.standard

        defaults.set(motion_correction,forKey:"motion_correction")
    }
    
    func updateDisplayFromDefaults(){
        //Get the defaults
        let defaults = UserDefaults.standard
        motion_correction = defaults.bool(forKey: "motion_correction")
        
        
    }
    
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Don't forget to reset when view is being removed
        AppUtility.lockOrientation(.all)
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.pinchGesture.delegate = self
        
        self.pinchGesture = UILongPressGestureRecognizer(target: self, action: #selector(pinchRecognized(_:)))
        
        self.view.addGestureRecognizer(self.pinchGesture)
        
        
        
        let launchedBefore = UserDefaults.standard.bool(forKey: "launchedBefore")
        print("launched Before",launchedBefore)
        if launchedBefore  {
            print("First launch, setting NSUserDefault.")
            registerSettingsBundle()
            updateDisplayFromDefaults()
            
            print("Not first launch.")
        }
        else {
            self.registerSettingsBundle()
            firstUpdateDisplayFromDefaults()
            updateDisplayFromDefaults()
        }
        
        UIDevice.current.isBatteryMonitoringEnabled = true
        

        isIphone = UIDevice.current.userInterfaceIdiom == .phone;
        isIpad = UIDevice.current.userInterfaceIdiom == .pad;

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("memorty warning")
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func take(_ sender: Any) {
        // when button is tapped, this method is called
    }
    
    func initCamera() -> Bool {
        session = AVCaptureSession()
        if self.isIphone{
            session.sessionPreset = AVCaptureSession.Preset.high
        }
        else{
            session.sessionPreset = AVCaptureSession.Preset.medium
        }
//        AVCaptureSessionPresetHigh
        
//        session = AVCaptureSession()
        device = AVCaptureDevice.default(for: AVMediaType.video)
        
        do{
            input = try AVCaptureDeviceInput(device: device!)
        }
        catch{
            print(error)
        }
        
        if let input = input{
            session?.addInput(input)
        }
        
        do {

            
            output = AVCaptureVideoDataOutput()
            output.videoSettings = [ kCVPixelBufferPixelFormatTypeKey as AnyHashable: Int(kCVPixelFormatType_32BGRA) ] as! [String : Any]
            
            try device.lockForConfiguration()
            device.activeVideoMinFrameDuration = CMTimeMake(1, 15)
            device.exposureMode = AVCaptureDevice.ExposureMode.autoExpose
            device.unlockForConfiguration()
            
            let queue: DispatchQueue = DispatchQueue(label: "myqueue", attributes: [])
            output.setSampleBufferDelegate(self, queue: queue)
            
            output.alwaysDiscardsLateVideoFrames = true
        } catch let error as NSError {
            print(error)
            return false
        }
        
        if session.canAddOutput(output) {
            session.addOutput(output)
        } else {
            return false
        }
        
        
        
        for connection in self.output.connections {
            if let conn = connection as? AVCaptureConnection {
                
                if UIDevice.current.orientation == UIDeviceOrientation.landscapeLeft{
                    conn.videoOrientation = AVCaptureVideoOrientation.landscapeRight
                    AppUtility.lockOrientation(.landscape)
                    
                }
                else if UIDevice.current.orientation == UIDeviceOrientation.landscapeRight{
                    conn.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
                    AppUtility.lockOrientation(.landscape)
                    
                }
                else if UIDevice.current.orientation == UIDeviceOrientation.portraitUpsideDown{
                    conn.videoOrientation = AVCaptureVideoOrientation.portraitUpsideDown
                    
                    
                }
                else if UIDevice.current.orientation == UIDeviceOrientation.portrait{
                    conn.videoOrientation = AVCaptureVideoOrientation.portrait
                    AppUtility.lockOrientation(.portrait)
                    
                }
                
                
                
            }
            
            
        }
        
        //        AppUtility.lockOrientation(.portrait)
        // Or to rotate and lock
        AppUtility.lockOrientation(.portrait, andRotateTo: .portrait)

        return true
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        DispatchQueue.main.async(execute: {
            
            var image: UIImage = CameraUtil.imageFromSampleBuffer(buffer: sampleBuffer )
            
            //pass array to function as test
            let rotarry : NSMutableArray = [1.0,0.0,0.0,0.0,1.0,0.0,0.0,0.0,1.0]
            
            if (self.framecount == 2){
                self.newimage = image;
            }
            
            
        
            self.object = false;
            
            // The skip rate is used to improve the performance of the algorithm & to reduce 'double pictures' when
            // using high quality photos
            if self.framecount >= 3 && self.isIphone{
               
                
                let bitarry = OpenCVWrapper.phaseshiftImage(withOpenCV:image, pastImg:self.newimage, rotation_array:rotarry)! as NSArray;
                
//                let bitarry : NSMutableArray = [0,0,0,0,0]

                
                self.shift_x = 0.9*(bitarry.object(at: 0) as! Double) + 0.1*self.shift_x;
                self.shift_y =  0.9*(bitarry.object(at:1) as! Double) + 0.1*self.shift_y;
//                self.shift_x = 1.0*(bitarry.object(at: 0) as! Double);
//                self.shift_y =  1.0*(bitarry.object(at:1) as! Double);
                
//                print(rsquared)
                
                
                let radius = sqrt(self.shift_x*self.shift_x + self.shift_y*self.shift_y);
                
                
                // includes information about the past
               self.radius_history = 0.5*radius + 0.5*self.radius_history

            }
            
            
            self.newimage = image;

            //Motion Correction
            if( self.motion_correction == true && self.isIphone){

                image = self.opencv.squareImage(withOpenCV: image, pastImg:self.newimage, y_shift:self.shift_y * Double(image.scale), x_shift:self.shift_x * Double(image.scale), rotation_array:rotarry);
            }
            
            
            self.imageView.image = image
            
            self.framecount = self.framecount + 1 ;
            
        
            if self.isIpad {
                print("is Ipad")
                usleep(500);
            }
            


            
        })
    }

    
    
    func focusCenter(){
        
        //for some reason focus y & focus x are reversed... might change this later
        let focusPoint = CGPoint(x:(self.focus_y+0.5)/6.0 , y:1-(self.focus_x+0.5)/8.0)
        
        let captureDevice = (AVCaptureDevice.devices(for: AVMediaType.video) as! [AVCaptureDevice]).filter{$0.position == .back}.first
        
        if let device = captureDevice {
            do {
                try device.lockForConfiguration()
                
                device.focusPointOfInterest = focusPoint
                //device.focusMode = .continuousAutoFocus
                device.focusMode = .autoFocus
                //device.focusMode = .locked
                device.exposurePointOfInterest = focusPoint
                device.exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
                device.unlockForConfiguration()
            }
            catch {
                // just ignore
            }
        }
    }
    
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if error != nil {
            // we got back an error!
            print("error")
        } else {
            self.total_savecount = self.total_savecount + 1;
            self.save_rate_gate = self.save_rate_gate + 1
//            print(self.total_savecount)
        }
        
    }
    
    func savePhoto(image: UIImage?){
        UIImageWriteToSavedPhotosAlbum(image!, self, #selector(ViewController.image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @IBAction func triggerSavePhoto(_ sender: AnyObject?){
        let image = self.imageView.image;
        savePhoto(image:image);
    }
    
    
    @IBAction func pauseCamera(_ sender: AnyObject) {
        print("pause")
        
        
        self.framecount = 0
        self.timer?.invalidate()
        self.timer = nil;
        session.stopRunning()
        
        let savealertController = UIAlertController (title: "Saving Video...", message: "Please wait", preferredStyle: .alert)
        
        let alertController = UIAlertController (title: "PhotoCoco Paused", message: "Please choose an option", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        
        let settingsAction = UIAlertAction(title: "Camera Settings", style: .default) { (_) -> Void in
            guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
                return
            }
            
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                    print("Settings opened: \(success)") // Prints true
                })
            }
        }
        
        
        let settingsSaveVideo = UIAlertAction(title: "Save Video", style: .default) { (_) -> Void in

                let imageAnimator = ImageAnimator(renderSettings: RenderSettings.init(size: self.newimage.size, fps: Int32(40), avCodecKey: AVVideoCodecH264, videoFilename: "render", videoFilenameExt: "mp4")
                    , photosTaken: Int(self.total_savecount), videoLimit: Int(1000))
            
                alertController.dismiss(animated: true, completion: nil)

                savealertController.addAction(cancelAction)
                self.present(savealertController, animated: true, completion: nil)
                
                //Make the time to save slightly proportional to the number of pictures taken
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.25 + sqrt(Double(self.total_savecount))){
                    imageAnimator.render() {
                        self.total_savecount = 0
                        savealertController.dismiss(animated: true, completion: nil)
                    }
                }
        }
        
        alertController.addAction(settingsAction)
        alertController.addAction(settingsSaveVideo)
        alertController.addAction(cancelAction)
        
        
        present(alertController, animated: true, completion: nil)
        
        
        
        
    }
    
    
    @IBAction func resumeCamera(_ sender: AnyObject) {
        print(self.initCamera())
        session.startRunning()
        self.registerSettingsBundle()
        self.updateDisplayFromDefaults()

        
    }
    
    //    @IBAction func changeCamera(_ sender: AnyObject) {
    //
    //        if session.isRunning == true {
    //            session.stopRunning()
    //            self.imageView.image = OpenCVWrapper.blackImage(withOpenCV: self.newimage)
    //        }
    //
    //        if self.camera_settings.isOn == true {
    //            self.camera_set = AVCaptureDevicePosition.front
    //        }
    //        else{
    //            self.camera_set = AVCaptureDevicePosition.back
    //        }
    //
    //        initCamera()
    //    }
    
    
    
    //    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    //        let screenSize = self.imageView.bounds.size
    //        if let touchPoint = touches.first {
    //            let x = touchPoint.location(in: self.imageView).y / screenSize.height
    //            let y = 1.0 - touchPoint.location(in: self.imageView).x / screenSize.width
    //            let focusPoint = CGPoint(x: x, y: y)
    //
    //            let captureDevice = (AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as! [AVCaptureDevice]).filter{$0.position == .back}.first
    //
    //            if let device = captureDevice {
    //                do {
    //                    try device.lockForConfiguration()
    //
    //                    device.focusPointOfInterest = focusPoint
    //                    //device.focusMode = .continuousAutoFocus
    //                    device.focusMode = .autoFocus
    //                    //device.focusMode = .locked
    //                    device.exposurePointOfInterest = focusPoint
    //                    device.exposureMode = AVCaptureExposureMode.continuousAutoExposure
    //                    device.unlockForConfiguration()
    //                }
    //                catch {
    //                    // just ignore
    //                }
    //            }
    //        }
    //
    //
    //    }
    
    
    func resetZoom() {
        
        let captureDevice = (AVCaptureDevice.devices(for: AVMediaType.video) as! [AVCaptureDevice]).filter{$0.position == .back}.first
        
        guard let device = captureDevice else { return }
        
        defer { device.unlockForConfiguration() }
        
        device.videoZoomFactor = max(1.0, 0.0)
        
    }
//    UIPinchGestureRecognizer
    @IBAction func pinchRecognized(_ sender:  UILongPressGestureRecognizer) {
        
        let captureDevice = (AVCaptureDevice.devices(for: AVMediaType.video) as! [AVCaptureDevice]).filter{$0.position == .back}.first
        
        guard let device = captureDevice else { return }
        
        if sender.state == .changed {
            
            let maxZoomFactor = device.activeFormat.videoMaxZoomFactor
            let pinchVelocityDividerFactor: CGFloat = 27.0
            
            do {
                
                try device.lockForConfiguration()
                defer { device.unlockForConfiguration() }
                
//                let currentdesiredZoomFactor = device.videoZoomFactor + atan2(sender.velocity, pinchVelocityDividerFactor)
                print(device.videoZoomFactor)
                let currentdesiredZoomFactor = device.videoZoomFactor + 0.1
//                let currentdesiredZoomFactor = CGFloat(4.0)
                device.videoZoomFactor = max(1.0, min(currentdesiredZoomFactor, maxZoomFactor))
                
                //                print(self.desiredZoomFactor)
                
                //max zoom is around 25
                //adjust 5% of zoom factor object movement sensitivity for scaling 0.05*(zoom_factor/sqrt(zoom_factor))
                //adjust 25% of zoom factor for camera motion for scaling 0.25*(zoom_factor/sqrt(zoom_factor))

//                self.registerSettingsBundle()
//                self.updateDisplayFromDefaults()
//
//                // adjust the rsquared require to take a picture by increasing the
//                // minimum object detection rsquard value by .1% of the zoom
//                self.object_movement_sensitivity = self.object_movement_sensitivity + 0.001*sqrt(Double(self.desiredZoomFactor));
//
//                // ajust the rsquard value to take a picture by 0.1% of the zoom.
//                // a low value is chosen because we don't want to taken too many blurr photos
//                self.object_movement_picture_tolerance = self.object_movement_picture_tolerance - 0.001*sqrt(Double(self.desiredZoomFactor));
//
//                // adjust the camera motion quality by increasing the tolerance by 1% of the zoom
//                // the zoom changes the x y shifts significantly
//                self.camera_motion_picture_tolerance = self.camera_motion_picture_tolerance + 0.05*sqrt(Double(self.desiredZoomFactor));

                
                self.desiredZoomFactor = currentdesiredZoomFactor;
                
            } catch {
                print(error)
            }
        }
    }
    
    
}
