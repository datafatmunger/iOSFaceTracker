//
//  iOSFaceTrackerAppDelegate.h
//  iOSFaceTracker
//
//  Created by James Bryan Graves on 12/12/10.
//  Copyright 2010 Sogeo. All rights reserved.
//


#import "iOSFTCameraViewController.h"
#import "iOSFTSettingsController.h"

@interface iOSFaceTrackerAppDelegate : NSObject <UIApplicationDelegate> {

	iOSFTCameraViewController *cameraController;
	iOSFTSettingsController *settingsController;
    UIWindow *window;

}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet iOSFTCameraViewController *cameraController;
@property (nonatomic, retain) IBOutlet iOSFTSettingsController *settingsController;

@end

