//
//  SampleHandler.m
//  BroadcastUploadExtension
//
//  Created by KyuJin Kim on 2016. 12. 28..
//  Copyright © 2016년 KyuJin Kim. All rights reserved.
//


#import "SampleHandler.h"

//  To handle samples with a subclass of RPBroadcastSampleHandler set the following in the extension's Info.plist file:
//  - RPBroadcastProcessMode should be set to RPBroadcastProcessModeSampleBuffer
//  - NSExtensionPrincipalClass should be set to this class

@implementation SampleHandler

- (void)broadcastStartedWithSetupInfo:(NSDictionary<NSString *,NSObject *> *)setupInfo {
    // User has requested to start the broadcast. Setup info from the UI extension will be supplied.
}

- (void)broadcastPaused {
    // User has requested to pause the broadcast. Samples will stop being delivered.
}

- (void)broadcastResumed {
    // User has requested to resume the broadcast. Samples delivery will resume.
}

- (void)broadcastFinished {
    // User has requested to finish the broadcast.
}

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType {
    
    switch (sampleBufferType) {
        case RPSampleBufferTypeVideo:
            // Handle audio sample buffer
            NSLog(@"Video");
            break;
        case RPSampleBufferTypeAudioApp:
            // Handle audio sample buffer for app audio
            NSLog(@"Audio");
            break;
        default:
            break;
    }
}

@end
