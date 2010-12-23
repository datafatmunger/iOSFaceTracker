//
//  iOSFTCameraViewController.h
//  iOSFaceTracker
//
//  Created by James Bryan Graves on 12/23/10.
//  Copyright 2010 Sogeo. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import "iOSFTContentView.h"
#import "iOSFTSettingsController.h"
#import <opencv/cv.h>

@interface iOSFTCameraViewController : UIViewController <
#if TARGET_OS_EMBEDDED
AVCaptureVideoDataOutputSampleBufferDelegate,
#endif
iOSFTSettingsControllerDelegate> {
	
#if TARGET_OS_EMBEDDED
	AVCaptureSession *session;
	AVCaptureVideoDataOutput *dataOutput;
	AVCaptureDeviceInput *captureInput;
	CvHaarClassifierCascade* cascade;
	CvMemStorage* storage;
#endif
	
	iOSFTContentView *contentView;

}

#if TARGET_OS_EMBEDDED
@property(retain) AVCaptureSession *session;
#endif
@property(nonatomic,retain)IBOutlet iOSFTContentView *contentView;

-(IBAction)onInfo:(id)sender;

@end
