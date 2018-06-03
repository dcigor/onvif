//
//  IdiaMainControl.m
//  Background
//
//  Created by Igor Diakov on 6/2/18.
//  Copyright © 2018 IgorDiakov. All rights reserved.
//

#import "IdiaMainControl.h"
#import "IdiaVideoSource.hpp"
#import "IdiaImageView.h"
#import "FaceDetector-Swift.h"
#import <algorithm>
#import <vector>
#import <Vision/Vision.h>

#define SOURCE ((IdiaVideoSource*)videoSource_)

class IdiaVideoDelegate;

@interface IdiaMainControl()
-(void) onError:(NSString*)error;
-(void) onImage:(CIImage*)image;
@property (nonatomic, readwrite) bool isWorking;
@property (nonatomic, readwrite) IdiaVideoDelegate *delegate;
@end

class IdiaVideoDelegate : public IIdiaVideoDelegate {
public:
    IdiaVideoDelegate(IdiaMainControl *owner) : owner_(owner) {}

    virtual void onError(const char*s) {
        [owner_ performSelectorOnMainThread:@selector(onError:) withObject:[NSString stringWithUTF8String:s] waitUntilDone:FALSE];
    }

    virtual void onImage(const uint8_t *in_bytes, const int w, const int h, const int bytesPerRow) {
        if (owner_.isWorking) {
            return;
        }

        static time_t start = time(nullptr);
        time_t now = time(nullptr);
        if (now-start < 1) {
            return;
        }
        start = now;
        static uint8_t *bytes = new uint8_t[h*bytesPerRow];
        memcpy(bytes, in_bytes, h*bytesPerRow);

        CVPixelBufferRef pb = nullptr;
        if (const CVReturn res = CVPixelBufferCreateWithBytes(0, w, h, kCVPixelFormatType_24RGB, bytes, bytesPerRow, 0, 0, 0, &pb)) {
            return;
        }

        owner_.isWorking = true;
        dispatch_async(dispatch_get_main_queue(), ^{
            CIImage *cii = [CIImage imageWithCVPixelBuffer:pb];
            CVPixelBufferRelease(pb);
            [owner_ performSelector:@selector(onImage:) withObject:cii afterDelay:1];
        });
    }
    
private:
    IdiaMainControl *owner_ = nil;
};

@implementation IdiaMainControl

@synthesize status;

-(void)viewDidLoad {
    [super viewDidLoad];

    self.status = @"Enter camera address, port and credentials and click Connect";
}

-(void) viewWillDisappear {
    [super viewWillDisappear];

    if (SOURCE) {
        SOURCE->stop();
        delete SOURCE;
    }

    delete self.delegate;
    self.delegate = nil;
}

-(IBAction)onConnect:(id)sender {
    self.status       = @"Connecting...";
    self.isConnecting = true;

    IdiaOnvifParser *p = [IdiaOnvifParser new];
    [p parseUrlWithUrl:self.address username:self.username password:self.password block:^(NSString * _Nullable url, NSString * _Nullable error) {
        if (error) {
            self.status = error;
            return;
        }
        [self startVideo:url username:self.username password:self.password];
    }];
}

- (IBAction)onViewFaces:(id)sender {
    [NSWorkspace.sharedWorkspace openURL:[NSURL fileURLWithPath:self.folder]];
}

#pragma mark implementation
-(void) startVideo:(NSString*)url username:(NSString*)username password:(NSString*)password {
    if (SOURCE) {
        SOURCE->stop();
        delete SOURCE;
    }
    self.delegate = new IdiaVideoDelegate(self);
    videoSource_  = new IdiaVideoSource(self.delegate);
    SOURCE->open(url.UTF8String, username.UTF8String, password.UTF8String);
}

-(void) onError:(NSString*)error {
    self.status       = error;
    self.isConnecting = false;
}

-(void) onImage:(CIImage*)ciimage {
    self.isConnecting = false;

    static NSDictionary<VNImageOption, id> *options = [NSDictionary<VNImageOption, id> new];
    VNImageRequestHandler *requestHandler = [[VNImageRequestHandler alloc] initWithCIImage:ciimage options:options];

    // perform face detection
    NSError *error = nil;
    VNDetectFaceRectanglesRequest *request = [[VNDetectFaceRectanglesRequest alloc] init];
    [requestHandler performRequests:@[request] error:&error];

    if (request.results.count) {
        // faces detected
        if (self.isSavingToDisk) {
            [self saveFace:ciimage];
        }   else {
            self.status = @"Face Detected";
        }
    }   else {
        self.status = @"Looking for faces...";
    }
    [self.imageView setFaces:request.results image:ciimage];
    self.isWorking = false;
}

-(NSString*) folder {
    NSArray  *picturePaths = NSSearchPathForDirectoriesInDomains(NSPicturesDirectory, NSUserDomainMask, YES);
    return [NSString stringWithFormat:@"%@/Faces/", picturePaths.firstObject];
}

-(void) saveFace:(CIImage*)ciimage {
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSError *error             = nil;
    if (const BOOL isCreated   = [fileManager createDirectoryAtPath:self.folder withIntermediateDirectories:YES attributes:nil error:&error]) {
        CIContext *ctx         = [CIContext new];
        NSDateFormatter *f     = [[NSDateFormatter alloc] init];
        f.dateFormat           = @"yyyy-MM-dd-HH-mm-ss";
        NSURL *url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@.jpg", self.folder, [f stringFromDate:[NSDate date]]]];
        if ([ctx writeJPEGRepresentationOfImage:ciimage toURL:url colorSpace:CGColorSpaceCreateWithName(kCGColorSpaceSRGB) options:@{} error:&error]) {
            self.status = @"Face is saved to disk";
        }   else {
            self.status = error.localizedFailureReason;
        }
    }   else {
        self.status = error.localizedFailureReason;
    }
}

@end
