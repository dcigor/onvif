//
//  AppDelegate.m
//  Background
//
//  Created by Igor Diakov on 6/2/18.
//  Copyright © 2018 IgorDiakov. All rights reserved.
//

#import "AppDelegate.h"
#import "IdiaMainControl.h"

@interface AppDelegate ()
@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

-(void) applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    mainControl = [[IdiaMainControl alloc] initWithNibName:@"IdiaMainControl" bundle:nil];
    mainControl.view.frame = self.window.contentView.bounds;
    [self.window.contentView addSubview:mainControl.view];
}

-(void) applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
