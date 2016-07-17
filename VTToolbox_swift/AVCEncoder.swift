//
//  AVCEncoder.swift
//  VTToolbox_swift
//
//  Created by gezhaoyou on 16/7/7.
//  Copyright © 2016年 bravovcloud. All rights reserved.
//

// import Foundation
import AVFoundation
import VideoToolbox
import CoreFoundation

final class AVCEncoder: NSObject {
    private var h264File:String!
    private var session:VTCompressionSessionRef?
    private var fileHandle:NSFileHandle!
    var formatDescription:CMFormatDescriptionRef? = nil {
        didSet {
            guard !CMFormatDescriptionEqual(formatDescription, oldValue) else {
                return
            }
            
            didSetFormatDescription(video: formatDescription)
        }
    }
    
    private var callback:VTCompressionOutputCallback = {(
        outputCallbackRefCon:UnsafeMutablePointer<Void>,
        sourceFrameRefCon:UnsafeMutablePointer<Void>,
        status:OSStatus,
        infoFlags:VTEncodeInfoFlags,
        sampleBuffer:CMSampleBuffer?
        ) in
        guard let sampleBuffer:CMSampleBuffer = sampleBuffer where status == noErr else {
            return
        }
        
        // print("get h.264 data!")
        let encoder:AVCEncoder = unsafeBitCast(outputCallbackRefCon, AVCEncoder.self)
        
        let isKeyframe = !CFDictionaryContainsKey(unsafeBitCast(CFArrayGetValueAtIndex(CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true), 0), CFDictionary.self), unsafeBitCast(kCMSampleAttachmentKey_NotSync, UnsafePointer<Void>.self))
        if isKeyframe {
            encoder.formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)
        }
        encoder.sampleOutput(video: sampleBuffer)
    }
    
    // 264 description
    private func didSetFormatDescription(video formatDescription:CMFormatDescriptionRef?) {
    
        let sampleData =  NSMutableData()
        // let formatDesrciption :CMFormatDescriptionRef = CMSampleBufferGetFormatDescription(sampleBuffer!)!
        let sps = UnsafeMutablePointer<UnsafePointer<UInt8>>.alloc(1)
        let pps = UnsafeMutablePointer<UnsafePointer<UInt8>>.alloc(1)
        let spsLength = UnsafeMutablePointer<Int>.alloc(1)
        let ppsLength = UnsafeMutablePointer<Int>.alloc(1)
        let spsCount = UnsafeMutablePointer<Int>.alloc(1)
        let ppsCount = UnsafeMutablePointer<Int>.alloc(1)
        sps.initialize(nil)
        pps.initialize(nil)
        spsLength.initialize(0)
        ppsLength.initialize(0)
        spsCount.initialize(0)
        ppsCount.initialize(0)
        var err : OSStatus
        err = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDescription!, 0, sps, spsLength, spsCount, nil )
        if (err != noErr) {
            NSLog("An Error occured while getting h264 parameter")
        }
        err = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDescription!, 1, pps, ppsLength, ppsCount, nil )
        if (err != noErr) {
            NSLog("An Error occured while getting h264 parameter")
        }
        let naluStart:[UInt8] = [0x00, 0x00, 0x00, 0x01]
        sampleData.appendBytes(naluStart, length: naluStart.count)
        sampleData.appendBytes(sps.memory, length: spsLength.memory)
        sampleData.appendBytes(naluStart, length: naluStart.count)
        sampleData.appendBytes(pps.memory, length: ppsLength.memory)

        fileHandle.writeData(sampleData)
        
        sps.destroy()
        spsLength.destroy()
        spsCount.destroy()
        pps.destroy()
        ppsLength.destroy()
        ppsCount.destroy()
        
        sps.dealloc(1)
        spsLength.dealloc(1)
        spsCount.dealloc(1)
        pps.dealloc(1)
        ppsLength.dealloc(1)
        ppsCount.dealloc(1)
        
    }
    
    //
    private func sampleOutput(video sampleBuffer: CMSampleBuffer) {
        print("get slice data!")
        // todo : write to h264 file
        let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer)
        var totalLength = Int()
        var length = Int()
        var dataPointer: UnsafeMutablePointer<Int8> = nil

        let state = CMBlockBufferGetDataPointer(blockBuffer!, 0, &length, &totalLength, &dataPointer)
        
        if state == noErr {
            var bufferOffset = 0;
            let AVCCHeaderLength = 4
            
            while bufferOffset < totalLength - AVCCHeaderLength {
                var NALUnitLength:UInt32 = 0
                memcpy(&NALUnitLength, dataPointer + bufferOffset, AVCCHeaderLength)
                NALUnitLength = CFSwapInt32BigToHost(NALUnitLength)
                
                var naluStart:[UInt8] = [UInt8](count: 4, repeatedValue: 0x00)
                naluStart[3] = 0x01
                let buffer:NSMutableData = NSMutableData()
                buffer.appendBytes(&naluStart, length: naluStart.count)
                buffer.appendBytes(dataPointer + bufferOffset + AVCCHeaderLength, length: Int(NALUnitLength))
                fileHandle.writeData(buffer)
                bufferOffset += (AVCCHeaderLength + Int(NALUnitLength))
            }
 
        }
    }
    
    let defaultAttributes:[NSString: AnyObject] = [
            kCVPixelBufferPixelFormatTypeKey: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange),
            kCVPixelBufferIOSurfacePropertiesKey: [:],
            kCVPixelBufferOpenGLESCompatibilityKey: true,
        ]
    private var width:Int32!
    private var height:Int32!
    
    private var attributes:[NSString: AnyObject] {
        var attributes:[NSString: AnyObject] = defaultAttributes
        attributes[kCVPixelBufferHeightKey] = 720
        attributes[kCVPixelBufferWidthKey] = 1280
        return attributes
    }
    
    var profileLevel:String = kVTProfileLevel_H264_Baseline_3_1 as String
    private var properties:[NSString: NSObject] {
        let isBaseline:Bool = profileLevel.containsString("Baseline")
        var properties:[NSString: NSObject] = [
            kVTCompressionPropertyKey_RealTime: kCFBooleanTrue,
            kVTCompressionPropertyKey_ProfileLevel: profileLevel,
            kVTCompressionPropertyKey_AverageBitRate: Int(1280*720),
            kVTCompressionPropertyKey_ExpectedFrameRate: NSNumber(double: 30.0),
            kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration: NSNumber(double: 2.0),
            kVTCompressionPropertyKey_AllowFrameReordering: !isBaseline,
            kVTCompressionPropertyKey_PixelTransferProperties: [
                "ScalingMode": "Trim"
            ]
        ]
        if (!isBaseline) {
            properties[kVTCompressionPropertyKey_H264EntropyMode] = kVTH264EntropyMode_CABAC
        }
        return properties
    }

    
    override init() {
        super.init()
        VTCompressionSessionCreate(
            kCFAllocatorDefault,
            720, // encode height
            1280,// encode width
            kCMVideoCodecType_H264,
            nil,
            attributes,
            nil,
            callback,
            unsafeBitCast(self, UnsafeMutablePointer<Void>.self),
            &session)
        
        VTSessionSetProperties(session!, properties)
        VTCompressionSessionPrepareToEncodeFrames(session!)
        
        // init filehandle
        let documentDir = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        h264File = documentDir[0] + "/demo.h264"
        
        do {
            try NSFileManager.defaultManager().removeItemAtPath(h264File)
            try NSFileManager.defaultManager().createFileAtPath(h264File, contents: nil, attributes: nil)
            try fileHandle = NSFileHandle.init(forWritingToURL: NSURL(string: h264File)!)
        } catch let error as NSError {
            print(error)
        }
    }
    
    func encodeImageBuffer(imageBuffer:CVImageBuffer, presentationTimeStamp:CMTime, presentationDuration:CMTime) {
     
        var flags:VTEncodeInfoFlags = VTEncodeInfoFlags()
    
        VTCompressionSessionEncodeFrame(session!, imageBuffer, presentationTimeStamp, presentationDuration, nil, nil, &flags)
    }
}

