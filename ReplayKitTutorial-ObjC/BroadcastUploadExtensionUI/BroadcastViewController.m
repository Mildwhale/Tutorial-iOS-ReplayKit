//
//  BroadcastViewController.m
//  BroadcastUploadExtensionUI
//
//  Created by KyuJin Kim on 2016. 12. 28..
//  Copyright © 2016년 KyuJin Kim. All rights reserved.
//

#import "BroadcastViewController.h"

@implementation BroadcastViewController
- (IBAction)finish:(id)sender
{
    [self userDidFinishSetup:@"http://mildwhale.iptime.org:7081/upload.php"];
}

- (IBAction)finish2:(id)sender
{
    [self userDidFinishSetup:@"http://10.10.22.60/service/upload"];
}

// Called when the user has finished interacting with the view controller and a broadcast stream can start
- (void)userDidFinishSetup:(NSString *)serverURL {
    
    // Broadcast url that will be returned to the application
    NSURL *broadcastURL = [NSURL URLWithString:@"http://broadcastURL_example/stream1"];
     
    // Service specific broadcast data example which will be supplied to the process extension during broadcast
    NSString *userID = @"user1";
    NSDictionary *setupInfo = @{ @"userID" : userID, @"endpointURL" : serverURL };
    
    // Set broadcast settings
    RPBroadcastConfiguration *broadcastConfig = [[RPBroadcastConfiguration alloc] init];
    broadcastConfig.clipDuration = 5.0; // deliver movie clips every 5 seconds
    
    // Tell ReplayKit that the extension is finished setting up and can begin broadcasting
    [self.extensionContext completeRequestWithBroadcastURL:broadcastURL broadcastConfiguration:broadcastConfig setupInfo:setupInfo];
}

- (void)userDidCancelSetup {
    // Tell ReplayKit that the extension was cancelled by the user
    [self.extensionContext cancelRequestWithError:[NSError errorWithDomain:@"YourAppDomain" code:-1     userInfo:nil]];
}

@end
