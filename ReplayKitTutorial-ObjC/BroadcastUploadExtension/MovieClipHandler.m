//
//  MovieClipHandler.m
//  BroadcastUploadExtension
//
//  Created by KyuJin Kim on 2016. 12. 28..
//  Copyright © 2016년 KyuJin Kim. All rights reserved.
//

#import "MovieClipHandler.h"
#import <MobileCoreServices/MobileCoreServices.h>

@implementation MovieClipHandler

- (void)processMP4ClipWithURL:(NSURL *)mp4ClipURL setupInfo:(NSDictionary<NSString *,NSObject *> *)setupInfo finished:(BOOL)finished {
   
   NSURL *endpointURL = [NSURL URLWithString:(NSString *)setupInfo[@"endpointURL"]];
//   [endpointURL URLByAppendingPathComponent:(NSString *)setupInfo[@"userID"]];
   
   // the boundary string : a random string, that will not repeat in post data, to separate post data fields.
   NSString *BoundaryConstant = @"----------V2ymHFg03ehbqgZCaKO6jy";
   
   // string constant for the post parameter 'file'. My server uses this name: `file`. Your's may differ
   NSString* FileParamConstant = @"userfile";
   
   // create request
   NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
   [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
   [request setHTTPShouldHandleCookies:NO];
   [request setTimeoutInterval:30];
   [request setHTTPMethod:@"POST"];
   
   // set Content-Type in HTTP header
   NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", BoundaryConstant];
   [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
   
   NSString *fileExtension = [mp4ClipURL pathExtension];
   NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)fileExtension, NULL);
   NSString *fileContentType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
   
   // post body
   NSMutableData *body = [NSMutableData data];
   
   [body appendData:[[NSString stringWithFormat:@"--%@\r\n", BoundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
   [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", FileParamConstant, mp4ClipURL.lastPathComponent] dataUsingEncoding:NSUTF8StringEncoding]];
   [body appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", fileContentType] dataUsingEncoding:NSUTF8StringEncoding]];
   [body appendData:[NSData dataWithContentsOfURL:mp4ClipURL]];
   [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
   
   [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", BoundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
   
   // setting the body of the post to the reqeust
   [request setHTTPBody:body];
   
   // set the content-length
   NSString *postLength = [NSString stringWithFormat:@"%ld", [body length]];
   [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
   
   // set URL
   [request setURL:endpointURL];

   NSURLSession *session = [NSURLSession sharedSession];
   [[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
      if (error) {
         // Handle the error locally
         NSLog(@"%@", error.localizedDescription);
      }
      
      // Update broadcast settings
      RPBroadcastConfiguration *broadcastConfiguration = [[RPBroadcastConfiguration alloc] init];
      broadcastConfiguration.clipDuration = 5;
      
      // Tell ReplayKit that processing is complete for thie clip
      [self finishedProcessingMP4ClipWithUpdatedBroadcastConfiguration:broadcastConfiguration error:nil];
   }] resume];
}

@end
