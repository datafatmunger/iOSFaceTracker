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
#import "iOSFTEigenfaceRecognizer.h"
#import "iOSFTSettingsController.h"
#import "iOSFTEigenfaceTrainer.h"
#import <opencv/cv.h>

@interface iOSFTCameraViewController : UIViewController <
#if TARGET_OS_EMBEDDED
AVCaptureVideoDataOutputSampleBufferDelegate,
#endif
iOSFTSettingsControllerDelegate,
UITextFieldDelegate> {
	
	//Training stuff - JBG
	BOOL _trainingMode;
	
#if TARGET_OS_EMBEDDED
	AVCaptureSession *session;
	AVCaptureVideoDataOutput *dataOutput;
	AVCaptureDeviceInput *captureInput;
	CvHaarClassifierCascade* cascade;
	CvMemStorage* storage;
#endif
	
	iOSFTContentView *contentView;
	iOSFTEigenfaceRecognizer *recognizer;
	iOSFTEigenfaceTrainer *trainer;
	
	UIImage *_processedImage;
	
	UIView *_promptView;
	UITextField *_nameField;
	UIActivityIndicatorView *_actView;

}

#if TARGET_OS_EMBEDDED
@property(retain) AVCaptureSession *session;
#endif
@property(nonatomic,retain)IBOutlet iOSFTContentView *contentView;
@property(nonatomic,retain)IBOutlet UIView *promptView;
@property(nonatomic,retain)IBOutlet UITextField *nameField;
@property(nonatomic,retain)IBOutlet UIActivityIndicatorView *actView;
@property(nonatomic,assign)BOOL trainingMode;

-(void)clearTrainingData;
-(IBAction)onInfo:(id)sender;

@end
