//
//  IdiaMainControl.h
//  Background
//
//  Created by Igor Diakov on 6/2/18.
//  Copyright © 2018 IgorDiakov. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class IdiaImageView;

@interface IdiaMainControl : NSViewController {
    void *videoSource_;
}

@property (nonatomic, readwrite) bool isSavingToDisk;
@property (nonatomic, readwrite) bool isConnecting;
@property (nonatomic, readwrite) NSString *status;
@property (nonatomic, readwrite) NSString *address;
@property (nonatomic, readwrite) NSString *username;
@property (nonatomic, readwrite) NSString *password;
@property (weak) IBOutlet IdiaImageView *imageView;

-(IBAction)onConnect:(id)sender;
-(IBAction)onViewFaces:(id)sender;

@end
