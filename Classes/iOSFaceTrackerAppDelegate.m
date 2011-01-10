//
//  iOSFaceTrackerAppDelegate.m
//  iOSFaceTracker
//
//  Created by James Bryan Graves on 12/12/10.
//  Copyright 2010 Sogeo. All rights reserved.
//

#import "iOSFaceTrackerAppDelegate.h"

@implementation iOSFaceTrackerAppDelegate

@synthesize cameraController;
@synthesize settingsController;
@synthesize window;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	
	[self.window addSubview:cameraController.view];
	[self.window makeKeyAndVisible];
}


- (void)applicationWillResignActive:(UIApplication *)application {
	
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
	[self.settingsController formatButtons];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
	[self.settingsController formatButtons];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
	return [settingsController.fbProcessor.facebook handleOpenURL:url];
}

- (void)dealloc {
	[window release];
	[super dealloc];
}

@end
