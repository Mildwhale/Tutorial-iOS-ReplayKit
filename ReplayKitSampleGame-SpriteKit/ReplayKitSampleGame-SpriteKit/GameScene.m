//
//  GameScene.m
//  ReplayKitSampleGame-SpriteKit
//
//  Created by KyuJin Kim on 2016. 12. 27..
//  Copyright © 2016년 KyuJin Kim. All rights reserved.
//

#import "GameScene.h"
#import <ReplayKit/ReplayKit.h>
@interface GameScene () <RPScreenRecorderDelegate, RPPreviewViewControllerDelegate, RPBroadcastActivityViewControllerDelegate, RPBroadcastControllerDelegate>
@property (weak, nonatomic) UIViewController *topVC;
@property (strong, nonatomic) RPBroadcastController *broadcastController;
@property (strong, nonatomic) RPPreviewViewController *previewController;
@property (strong, nonatomic) AVAudioPlayer *musicPlayer;
@end

@implementation GameScene {
    SKShapeNode *_spinnyNode;
    SKLabelNode *_label;
}

- (void)didMoveToView:(SKView *)view {
    // Setup your scene here
    
    // Get label node from scene and store it for use later
    _label = (SKLabelNode *)[self childNodeWithName:@"//helloLabel"];
    
    _label.alpha = 0.0;
    [_label runAction:[SKAction fadeInWithDuration:2.0]];
    
    CGFloat w = (self.size.width + self.size.height) * 0.1;
    
    // Create shape node to use during mouse interaction
    _spinnyNode = [SKShapeNode shapeNodeWithRectOfSize:CGSizeMake(w, w) cornerRadius:w * 0.3];
    _spinnyNode.lineWidth = 2.5;
    
    [_spinnyNode runAction:[SKAction repeatActionForever:[SKAction rotateByAngle:M_PI duration:1]]];
    [_spinnyNode runAction:[SKAction sequence:@[
                                                [SKAction waitForDuration:0.5],
                                                [SKAction fadeOutWithDuration:0.5],
                                                [SKAction removeFromParent],
                                                ]]];
}

- (void)startRecord
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    RPScreenRecorder *recoder = [RPScreenRecorder sharedRecorder];
    recoder.delegate = self;
    recoder.microphoneEnabled = YES;
    
    self.topVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    if (recoder.available && !recoder.recording) {
        [recoder startRecordingWithHandler:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"%@", error.localizedDescription);
                return;
            }
        }];
    }
}

- (void)stopRecord
{
    NSLog(@"%s", __PRETTY_FUNCTION__);

    RPScreenRecorder *recoder = [RPScreenRecorder sharedRecorder];
    
    if (recoder.recording) {
        [recoder stopRecordingWithHandler:^(RPPreviewViewController * _Nullable previewViewController, NSError * _Nullable error) {
            if (error) {
                NSLog(@"%@", error.localizedDescription);
                return;
            }
            
            self.previewController = previewViewController;
            
            if (previewViewController) {
                previewViewController.previewControllerDelegate = self;
                
                [self.topVC presentViewController:previewViewController animated:YES completion:^{
                    
                }];
            }
        }];
    }
}

#pragma mark - RPScreenRecoder Delegate
- (void)screenRecorder:(RPScreenRecorder *)screenRecorder didStopRecordingWithError:(NSError *)error previewViewController:(nullable RPPreviewViewController *)previewViewController
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    if (error) {
        NSLog(@"%@", error.localizedDescription);
        return;
    }
    
    self.previewController = previewViewController;
    
    if (previewViewController) {
        [self.topVC presentViewController:previewViewController animated:YES completion:^{
            
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

- (void)broadcast
{
    [RPBroadcastActivityViewController loadBroadcastActivityViewControllerWithHandler:^(RPBroadcastActivityViewController * _Nullable broadcastActivityViewController, NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error.localizedDescription);
            return;
        }
        
        broadcastActivityViewController.delegate = self;
        
        self.topVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        
        [self.topVC presentViewController:broadcastActivityViewController animated:YES completion:^{
            
        }];
    }];
}

- (void)broadcastActivityViewController:(RPBroadcastActivityViewController *)broadcastActivityViewController didFinishWithBroadcastController:(nullable RPBroadcastController *)broadcastController error:(nullable NSError *)error
{
    NSLog(@"%@, %@, %@", broadcastActivityViewController, broadcastController, error.localizedDescription);
    
    [self.topVC dismissViewControllerAnimated:broadcastActivityViewController completion:^{

    }];
    
    self.broadcastController = broadcastController;
    
    broadcastController.delegate = self;
    
    if (!broadcastController.broadcasting) {
        [broadcastController startBroadcastWithHandler:^(NSError * _Nullable error) {
            if (!error) {
                // Broadcasting Started.
                SKNode *node = [self childNodeWithName:@"broadcastNode"];
                
                [node runAction:[SKAction repeatActionForever:[SKAction sequence:@[
                                                                                   [SKAction scaleTo:1.1f duration:0.5],
                                                                                   [SKAction scaleTo:0.9f duration:0.5]
                                                                                   ]]]];
             
                [self playMusic];
            }
        }];
    }
}

- (void)broadcastController:(RPBroadcastController *)broadcastController didFinishWithError:(NSError * __nullable)error
{
    NSLog(@"[%s] %@", __PRETTY_FUNCTION__, error.localizedDescription);
    SKNode *node = [self childNodeWithName:@"broadcastNode"];
    
    [node removeAllActions];
    [node setScale:1.0f];
    
    [self stopMusic];
}

- (void)playMusic
{
    NSError *error = nil;
    NSURL *audioURL = [[NSBundle mainBundle] URLForResource:@"music" withExtension:@"mp3"];
    self.musicPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioURL error:&error];
    self.musicPlayer.numberOfLoops = -1;
    
    [self.musicPlayer play];
}

- (void)stopMusic
{
    [self.musicPlayer stop];
    self.musicPlayer = nil;
}

- (void)touchDownAtPoint:(CGPoint)pos {
    SKShapeNode *n = [_spinnyNode copy];
    n.position = pos;
    n.strokeColor = [SKColor greenColor];
    [self addChild:n];
}

- (void)touchMovedToPoint:(CGPoint)pos {
    SKShapeNode *n = [_spinnyNode copy];
    n.position = pos;
    n.strokeColor = [SKColor blueColor];
    [self addChild:n];
}

- (void)touchUpAtPoint:(CGPoint)pos {
    SKShapeNode *n = [_spinnyNode copy];
    n.position = pos;
    n.strokeColor = [SKColor redColor];
    [self addChild:n];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    // Run 'Pulse' action from 'Actions.sks'
    [_label runAction:[SKAction actionNamed:@"Pulse"] withKey:@"fadeInOut"];
    
    SKNode *node = [self nodeAtPoint:[[touches anyObject] locationInNode:self]];
    
    if ([node.name isEqualToString:@"broadcastNode"]) {
        if (!self.broadcastController.broadcasting) {
            [self broadcast];
        } else {
            [self.broadcastController finishBroadcastWithHandler:^(NSError * _Nullable error) {
                // Broadcasting Ended.
                [node removeAllActions];
                [node runAction:[SKAction scaleTo:1.0f duration:0.2]];
            }];
        }
    } else if ([node.name isEqualToString:@"recStart"]) {
        [self startRecord];
    } else if ([node.name isEqualToString:@"recStop"]) {
        [self stopRecord];
    }
    
    for (UITouch *t in touches) {[self touchDownAtPoint:[t locationInNode:self]];}
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    for (UITouch *t in touches) {[self touchMovedToPoint:[t locationInNode:self]];}
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *t in touches) {[self touchUpAtPoint:[t locationInNode:self]];}
}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *t in touches) {[self touchUpAtPoint:[t locationInNode:self]];}
}


-(void)update:(CFTimeInterval)currentTime {
    // Called before each frame is rendered
}

@end
