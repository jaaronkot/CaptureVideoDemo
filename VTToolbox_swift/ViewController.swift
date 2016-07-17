//
//  ViewController.swift
//  VTToolbox_swift
//
//  Created by gezhaoyou on 16/6/27.
//  Copyright © 2016年 bravovcloud. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    var startCalled: Bool?
    var captureSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer?
    var h264File: String?
    var fileHandler: NSFileHandle?
    var avConnection: AVCaptureConnection?
    
    var capture:VideoIOComponent!
    
    var fd: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        startCalled = true
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func StartPtnPush(sender: UIButton) {
        capture = VideoIOComponent()
        capture.attachCamera(self)
    }
    
//    func startCamera() {
//        // var deviceError: NSError? = nil
//        var cameraDevice: AVCaptureDevice?
//        let devices = AVCaptureDevice.devices()
//        
//        for device in devices {
//            if (device.hasMediaType(AVMediaTypeVideo)) {
//                if (device.position == AVCaptureDevicePosition.Back) {
//                    cameraDevice = device as? AVCaptureDevice
//                    if cameraDevice != nil {
//                        print("Capture Device found.")
//                    }
//                }
//            }
//        }
//    
//        var inputDevice: AVCaptureDeviceInput?
//        do {
//            inputDevice = try AVCaptureDeviceInput(device: cameraDevice)
//        } catch {
//            // error handle
//        }
//        
//        let key = String(kCVPixelBufferPixelFormatTypeKey)
//        let val = NSNumber(unsignedInt: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
//        
//        let videoSettings = NSDictionary(object:val, forKey:key)
//        
//        let outputDevice = AVCaptureVideoDataOutput()
//        outputDevice.videoSettings = videoSettings as [NSObject : AnyObject]
//        outputDevice.setSampleBufferDelegate(self, queue: dispatch_get_main_queue())
//        
//        // init capture session
//        captureSession.addInput(inputDevice)
//        captureSession.addOutput(outputDevice)
//        
//        
//        captureSession.beginConfiguration()
//        captureSession.sessionPreset = AVCaptureSessionPreset640x480
//        avConnection = outputDevice.connectionWithMediaType(AVMediaTypeVideo)
//        
//        captureSession.commitConfiguration()
//        
//        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
//        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspect
//        
//        previewLayer?.frame = self.view.bounds
//        self.view.layer.addSublayer(previewLayer!)
//        
//        // go
//        captureSession.startRunning()
//    }
//    
//    // write sps, pps
//    func gotSpsPps(sps: NSData, pps: NSData) {
//        
//    }
//    
//    // h264hw encoder delegate
//    func gotEncodeData(data: NSData, isKeyFrame: Bool) {
//        
//    }
}

// 得到 CVImageBuffer 
extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(captureOutput:AVCaptureOutput!, didOutputSampleBuffer sampleBuffer:CMSampleBuffer!, fromConnection connection:AVCaptureConnection!) {
        guard let image:CVImageBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        print("get camera image data! Yeh!")
    }
}