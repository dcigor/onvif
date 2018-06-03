//
//  IdiaImageView.h
//  Background
//
//  Created by Igor Diakov on 6/2/18.
//  Copyright © 2018 IgorDiakov. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface IdiaImageView : NSView {
    CIImage *image_;
    NSArray *faces_;
}

-(void) setFaces:(NSArray*)faces image:(CIImage*)image;

@end
