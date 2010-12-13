//
//  iOSFaceTrackerAppDelegate.h
//  iOSFaceTracker
//
//  Created by James Bryan Graves on 12/12/10.
//  Copyright 2010 Sogeo. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "ContentView.h"
#import <opencv/cv.h>
#import <UIKit/UIKit.h>

@interface iOSFaceTrackerAppDelegate : NSObject <UIApplicationDelegate
#if TARGET_OS_EMBEDDED
, AVCaptureVideoDataOutputSampleBufferDelegate
#endif
> {
	
#if TARGET_OS_EMBEDDED
	AVCaptureSession *session;
	AVCaptureVideoDataOutput *dataOutput;
	AVCaptureDeviceInput *captureInput;
	CvHaarClassifierCascade* cascade;
	CvMemStorage* storage;
#endif
    UIWindow *window;
	ContentView *contentView;
	
	CGRect prevRect;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
#if TARGET_OS_EMBEDDED
@property(retain) AVCaptureSession *session;
#endif

@end

