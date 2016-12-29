//
//  GameScene.m
//  ReplayKitSampleGame-SpriteKit
//
//  Created by KyuJin Kim on 2016. 12. 27..
//  Copyright © 2016년 KyuJin Kim. All rights reserved.
//

#import "GameScene.h"
#import <ReplayKit/ReplayKit.h>
@interface GameScene () <RPBroadcastActivityViewControllerDelegate, RPBroadcastControllerDelegate>
@property (weak, nonatomic) UIViewController *topVC;
@property (strong, nonatomic) RPBroadcastController *broadcastController;
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
                SKNode *node = [self childNodeWithName:@"recNode"];
                
                [node runAction:[SKAction repeatActionForever:[SKAction sequence:@[
                                                                                   [SKAction scaleTo:1.1f duration:0.5],
                                                                                   [SKAction scaleTo:0.9f duration:0.5]
                                                                                   ]]]];
            }
        }];
    }
}

- (void)broadcastController:(RPBroadcastController *)broadcastController didFinishWithError:(NSError * __nullable)error
{
    NSLog(@"[%s] %@", __PRETTY_FUNCTION__, error.localizedDescription);
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
    
    if ([node.name isEqualToString:@"recNode"]) {
        if (!self.broadcastController.broadcasting) {
            [self broadcast];
        } else {
            [self.broadcastController finishBroadcastWithHandler:^(NSError * _Nullable error) {
                // Broadcasting Ended.
                [node removeAllActions];
                [node runAction:[SKAction scaleTo:1.0f duration:0.2]];
            }];
        }
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
