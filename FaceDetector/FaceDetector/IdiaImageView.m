//
//  IdiaImageView.m
//  Background
//
//  Created by Igor Diakov on 6/2/18.
//  Copyright © 2018 IgorDiakov. All rights reserved.
//

#import "IdiaImageView.h"
#import <Vision/Vision.h>

@implementation IdiaImageView

-(void) setFaces:(NSArray*)faces image:(CIImage*)image {
    image_ = image;
    faces_ = faces;

    [self setNeedsDisplay:true];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    [image_ drawInRect:self.bounds fromRect:image_.extent operation:NSCompositingOperationCopy fraction:1];
    
    const double dx = self.bounds.size.width;
    const double dy = self.bounds.size.height;
    for (VNFaceObservation *face in faces_) {
        const CGRect r = CGRectMake(
            face.boundingBox.origin.x*dx,
            face.boundingBox.origin.y*dy,
            face.boundingBox.size.width*dx,
            face.boundingBox.size.height*dy);

        NSBezierPath *path = [NSBezierPath bezierPathWithRect:r];
        [[NSColor greenColor] setStroke];
        [path setLineWidth:4];
        [path stroke];
    }
}

@end
