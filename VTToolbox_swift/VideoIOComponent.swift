//
//  VideoIOComponent.swift
//  VTToolbox_swift
//
//  Created by gezhaoyou on 16/7/7.
//  Copyright © 2016年 bravovcloud. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

final class VideoIOComponent: NSObject {
    private var avcEncoder:AVCEncoder = AVCEncoder()
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    var lockQueue:dispatch_queue_t = dispatch_queue_create("abc", DISPATCH_QUEUE_SERIAL)
    var session:AVCaptureSession! = AVCaptureSession()
    private var _output: AVCaptureVideoDataOutput? = nil
    var output:AVCaptureVideoDataOutput! {
        get {
            if _output == nil {
                _output = AVCaptureVideoDataOutput()
                _output!.alwaysDiscardsLateVideoFrames = true;
                _output!.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString):NSNumber(unsignedInt: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            }
            return _output!
        }
        
        set {
            if _output == newValue {
                return
            }
            
            // 这个地方不太理解，为什么让 _output 存储最新的值，而让 output 保存上一次的值
            if  let output:AVCaptureVideoDataOutput = _output {
                output.setSampleBufferDelegate(nil, queue: nil)
                session.removeOutput(output)
            }
            _output = newValue
        }
    }
    
    private(set) var input:AVCaptureDeviceInput?
    
    var orientation:AVCaptureVideoOrientation = .Portrait
    
    func attachCamera(viewController:UIViewController) {
        var cameraDevice: AVCaptureDevice?
        let devices = AVCaptureDevice.devices()
        
        for device in devices {
            if (device.hasMediaType(AVMediaTypeVideo)) {
                if (device.position == AVCaptureDevicePosition.Back) {
                    cameraDevice = device as? AVCaptureDevice
                    if cameraDevice != nil {
                        print("Capture Device found.")
                    }
                }
            }
        }
        
//        output = AVCaptureVideoDataOutput()
        guard let camera:AVCaptureDevice = cameraDevice else {
            input = nil
            return
        }
        
        do {
            
            output.setSampleBufferDelegate(self, queue: lockQueue)
            
            input = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(input) {
                session.addInput(input)
            }
            if session.canAddOutput(output) {
                session.addOutput(output)
            }
            
            session.beginConfiguration()
            if session.canSetSessionPreset(AVCaptureSessionPreset1280x720) {
                session.sessionPreset = AVCaptureSessionPreset1280x720
            }
            
            let connection:AVCaptureConnection = output.connectionWithMediaType(AVMediaTypeVideo)
            connection.videoOrientation = orientation
            session.commitConfiguration()
            
        } catch let error as NSError {
            print(error)
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspect
        
        previewLayer?.frame = viewController.view.bounds
        viewController.view.layer.addSublayer(previewLayer!)
        
        session.startRunning()
    }
}

extension VideoIOComponent: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(captureOutput:AVCaptureOutput!, didOutputSampleBuffer sampleBuffer:CMSampleBuffer!, fromConnection connection:AVCaptureConnection!) {
        guard let image:CVImageBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        avcEncoder.encodeImageBuffer(image, presentationTimeStamp: CMSampleBufferGetPresentationTimeStamp(sampleBuffer), presentationDuration: CMSampleBufferGetDuration(sampleBuffer))
            // print("get camera image data! Yeh!")
    }
}

