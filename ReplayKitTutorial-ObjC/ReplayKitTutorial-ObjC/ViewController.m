//
//  ViewController.m
//  ReplayKitTutorial-ObjC
//
//  Created by KyuJin Kim on 2016. 12. 27..
//  Copyright © 2016년 KyuJin Kim. All rights reserved.
//

#import "ViewController.h"
#import <ReplayKit/ReplayKit.h>

@interface ViewController () <RPScreenRecorderDelegate, RPPreviewViewControllerDelegate, RPBroadcastActivityViewControllerDelegate>
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startRecord:(id)sender
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    RPScreenRecorder *recoder = [RPScreenRecorder sharedRecorder];
    recoder.delegate = self;
    recoder.microphoneEnabled = YES;
    recoder.cameraEnabled = YES;
    
    if (recoder.available) {
        [self.indicator startAnimating];
        
        [recoder startRecordingWithHandler:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"%@", error.localizedDescription);
                return;
            }
            
            if (recoder.cameraPreviewView) {
                [self.view addSubview:recoder.cameraPreviewView];
            }
        }];
    }
}

- (IBAction)stopRecord:(id)sender
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self.indicator stopAnimating];
    
    RPScreenRecorder *recoder = [RPScreenRecorder sharedRecorder];
    
    if (recoder.recording) {
        [recoder stopRecordingWithHandler:^(RPPreviewViewController * _Nullable previewViewController, NSError * _Nullable error) {
            if (error) {
                NSLog(@"%@", error.localizedDescription);
                return;
            }
            
            if (previewViewController) {
                previewViewController.previewControllerDelegate = self;
                
                [self presentViewController:previewViewController animated:YES completion:^{
                    
                }];
            }
        }];
    }
}

- (IBAction)liveStreaming:(id)sender
{
    [RPBroadcastActivityViewController loadBroadcastActivityViewControllerWithHandler:^(RPBroadcastActivityViewController * _Nullable broadcastActivityViewController, NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error.localizedDescription);
            return;
        }
        
        broadcastActivityViewController.delegate = self;
        
        [self presentViewController:broadcastActivityViewController animated:YES completion:^{
            
        }];
    }];
}

#pragma mark - RPScreenRecoder Delegate
- (void)screenRecorder:(RPScreenRecorder *)screenRecorder didStopRecordingWithError:(NSError *)error previewViewController:(nullable RPPreviewViewController *)previewViewController
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    if (error) {
        NSLog(@"%@", error.localizedDescription);
        return;
    }
    
    if (previewViewController) {
        [self presentViewController:previewViewController animated:YES completion:^{
            
        }];
    }
}

#pragma mark - RPPreviewViewController Delegate
- (void)previewControllerDidFinish:(RPPreviewViewController *)previewController
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [previewController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)previewController:(RPPreviewViewController *)previewController didFinishWithActivityTypes:(NSSet <NSString *> *)activityTypes
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"%@", activityTypes);
    
    [previewController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

#pragma mark - RPBroadCastActivity Delegate
- (void)broadcastActivityViewController:(RPBroadcastActivityViewController *)broadcastActivityViewController didFinishWithBroadcastController:(nullable RPBroadcastController *)broadcastController error:(nullable NSError *)error
{
    
}
@end
