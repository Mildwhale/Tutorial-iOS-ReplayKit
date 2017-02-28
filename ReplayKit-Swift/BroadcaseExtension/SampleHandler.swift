//
//  SampleHandler.swift
//  BroadcaseExtension
//
//  Created by KyuJin Kim on 2017. 2. 27..
//  Copyright © 2017년 KyuJin Kim. All rights reserved.
//

import ReplayKit
import VideoToolbox
import lf

//  To handle samples with a subclass of RPBroadcastSampleHandler set the following in the extension's Info.plist file:
//  - RPBroadcastProcessMode should be set to RPBroadcastProcessModeSampleBuffer
//  - NSExtensionPrincipalClass should be set to this class

class SampleHandler: RPBroadcastSampleHandler {
    private var broadcaster:RTMPBroadcaster = RTMPBroadcaster()

    override open func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        print("broadcastStarted")
        super.broadcastStarted(withSetupInfo: setupInfo)
        guard
            let endpointURL:String = setupInfo?["endpointURL"] as? String,
            let streamName:String = setupInfo?["streamName"] as? String else {
                return
        }
        broadcaster.streamName = streamName
        broadcaster.connect(endpointURL, arguments: nil)
    }
    
    override func broadcastPaused() {
        // User has requested to pause the broadcast. Samples will stop being delivered.
    }
    
    override func broadcastResumed() {
        // User has requested to resume the broadcast. Samples delivery will resume.
    }
    
    override func broadcastFinished() {
        // User has requested to finish the broadcast.
    }
    
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case .video:
            if let description:CMVideoFormatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) {
                let dimensions:CMVideoDimensions = CMVideoFormatDescriptionGetDimensions(description)
                broadcaster.stream.videoSettings = [
                    "width": dimensions.width,
                    "height": dimensions.height,
                    "profileLevel": kVTProfileLevel_H264_Baseline_AutoLevel,
                ]
            }
            broadcaster.appendSampleBuffer(sampleBuffer, withType: .video)
        case .audioApp:
            broadcaster.appendSampleBuffer(sampleBuffer, withType: .audio)
        case .audioMic:
            break
        }
    }
}
