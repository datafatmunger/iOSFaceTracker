//
//  iOSFTCameraViewController.m
//  iOSFaceTracker
//
//  Created by James Bryan Graves on 12/23/10.
//  Copyright 2010 Sogeo. All rights reserved.
//

#import "iOSFaceTrackerAppDelegate.h"
#import "iOSFTCameraViewController.h"
#import "iOSFTSettingsController.h"
#import "iOSFTUtils.h"

#define NUM_TRAINING_FACES 10

@implementation iOSFTCameraViewController

@synthesize contentView;
#if TARGET_OS_EMBEDDED
@synthesize session;
#endif
@synthesize trainingMode = _trainingMode;

-(void)process:(uint8_t*)readblePixels width:(size_t)width height:(size_t)height {
	IplImage *iplimage = cvCreateImage(cvSize(width, height), IPL_DEPTH_8U, 4);
	iplimage->imageData = (char*)readblePixels;
	//		iplimage->widthStep = bytesPerRow;
	
	IplImage *image = cvCreateImage(cvGetSize(iplimage), IPL_DEPTH_8U, 3);
	cvCvtColor(iplimage, image, CV_BGRA2BGR);
	cvReleaseImage(&iplimage);
	
	// Scaling down
	int scale = 2;
	IplImage *small_image = cvCreateImage(cvSize(image->width/scale,
												 image->height/scale),
										  IPL_DEPTH_8U,
										  3);
	cvPyrDown(image, small_image, CV_GAUSSIAN_5x5);
	cvReleaseImage(&image);
	
	// Detect faces and draw rectangle on them
	CvSeq* faces = cvHaarDetectObjects(small_image,
									   cascade,
									   storage,
									   1.2f,
									   3,
									   CV_HAAR_DO_CANNY_PRUNING,
									   cvSize(small_image->width/3, small_image->height/2));
	
	
	// Draw results on the image
	NSLog(@"found %d faces", faces->total);
	
	if(faces->total > 0) {
		CvRect cvrect = *(CvRect*)cvGetSeqElem(faces, 0);
		
		//START - Crop and process - JBG
		cvSetImageROI(small_image, cvrect);
		IplImage *cropped_image = cvCreateImage(cvGetSize(small_image),
												small_image->depth,
												small_image->nChannels);
		cvCopy(small_image, cropped_image, NULL);
		
		IplImage *grey_image = nil;
		grey_image = cvCreateImage(cvGetSize(cropped_image), IPL_DEPTH_8U, 1);
		cvCvtColor(cropped_image, grey_image, CV_BGR2GRAY);
		
		IplImage *sized_image = nil;
		sized_image = cvCreateImage(cvSize(92, 112), IPL_DEPTH_8U, 1);
		cvResize(grey_image, sized_image, 1);
		
		
		if(!_trainingMode) {
			if(recognizer.nTrainFaces > 0) {
				NSLog(@"Recogging. . .");
				//Recognize this face bitch - JBG
				[recognizer recognize:sized_image];
			}
		} else {
			NSLog(@"Gathering training faces. . .image %d (%d, %d)",
				  trainer.nTrainFaces,
				  sized_image->width,
				  sized_image->height);
			trainer.faceImgArr[trainer.nTrainFaces] = sized_image;
			trainer.nTrainFaces++;
			if(trainer.nTrainFaces == NUM_TRAINING_FACES) {
				NSLog(@"Training. . .");
				[trainer learn];
				_trainingMode = NO;
				[recognizer reloadTrainingData];
			}
		}
		
		//Show results on the screen - JBG
		CGRect cvrect2scale = CGRectMake(cvrect.x * scale,
										 cvrect.y * scale,
										 cvrect.width * scale,
										 cvrect.height * scale);
		
		NSInteger centerX = cvrect2scale.origin.x + (cvrect2scale.size.width / 2);
		NSInteger centerY = cvrect2scale.origin.y + (cvrect2scale.size.height / 2);
		cvrect2scale.size.width = ((cvrect2scale.size.width / (float) height) * 320);
		cvrect2scale.size.height = ((cvrect2scale.size.height / (float) width) * 480);
		cvrect2scale.origin.x  = ((centerY / (float) height) * 320) - cvrect2scale.size.width / 2;
		cvrect2scale.origin.y  = ((centerX / (float) width) * 480) - cvrect2scale.size.height / 2;
		
		contentView.faceRect = cvrect2scale;
		
		contentView.image = [iOSFTUtils createUIImageFromIplImage:sized_image];
		
		cvResetImageROI(small_image);
		cvReleaseImage(&cropped_image);
		cvReleaseImage(&grey_image);
		if(!_trainingMode)
			cvReleaseImage(&sized_image);
		else
			;//TODO : training array leaks here - JBG
		//END - Crop and process - JBG
		
	}
	cvReleaseImage(&small_image);
	
	[contentView performSelectorOnMainThread:@selector(setNeedsDisplay)
								  withObject:nil
							   waitUntilDone:YES];
}

#if TARGET_OS_EMBEDDED
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
	   fromConnection:(AVCaptureConnection *)connection {
	
	CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	CVPixelBufferLockBaseAddress(imageBuffer, 0);
	
	//size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
	size_t width = CVPixelBufferGetWidth(imageBuffer); 
	size_t height = CVPixelBufferGetHeight(imageBuffer);
	uint8_t *readblePixels = (uint8_t*)CVPixelBufferGetBaseAddress(imageBuffer);
	
	//	NSLog(@"bytesPerRow: %d, width %d, height %d", bytesPerRow, width, height);
	
	if (readblePixels) {
		[self process:readblePixels width:width height:height];
	}
	
	CVPixelBufferUnlockBaseAddress(imageBuffer,0);
}
#endif

-(void)viewDidLoad {
	_processedImage = nil;
	
	recognizer = [[iOSFTEigenfaceRecognizer alloc] init];
	
	trainer = [[iOSFTEigenfaceTrainer alloc] init];
	trainer.faceImgArr = (IplImage **)cvAlloc(NUM_TRAINING_FACES * sizeof(IplImage *));
	
	for(NSInteger i = 0; i < NUM_TRAINING_FACES; i++)
		trainer.faceImgArr[i] = nil;
	
#if TARGET_OS_EMBEDDED
	// Load XML
	NSString *path = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_default" ofType:@"xml"];
	cascade = (CvHaarClassifierCascade*)cvLoad([path cStringUsingEncoding:NSASCIIStringEncoding], NULL, NULL, NULL);
	storage = cvCreateMemStorage(0);
	
	NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
	
	AVCaptureDevice *camera;
	for(AVCaptureDevice *cameraDevice in cameras) {
		if(cameraDevice.position == AVCaptureDevicePositionFront)
			camera = cameraDevice;
	}
	
	NSError *error;
	captureInput = [AVCaptureDeviceInput deviceInputWithDevice:camera error:&error]; 
	dataOutput = [[AVCaptureVideoDataOutput alloc] init];
	[dataOutput setAlwaysDiscardsLateVideoFrames:YES];
	[dataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
															 forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
	dispatch_queue_t my_queue = dispatch_queue_create("com.jamesbryangraves.sandbox", NULL);
	[dataOutput setSampleBufferDelegate:self queue:my_queue];
	
	self.session = [[AVCaptureSession alloc] init];
	if ([self.session canAddInput:captureInput])
		[self.session addInput:captureInput];
	if ([self.session canAddOutput:dataOutput])
		[self.session addOutput:dataOutput];
	
	AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
	previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	
	CGRect layerRect = self.view.layer.bounds;
	previewLayer.bounds = layerRect;
	previewLayer.position = CGPointMake(CGRectGetMidX(layerRect), CGRectGetMidY(layerRect));
	[self.view.layer addSublayer:previewLayer];
	[self.session startRunning];
#endif
	
	[self.view addSubview:contentView];
	
	[previewLayer release];
	
}

-(IBAction)onInfo:(id)sender {
#if TARGET_OS_EMBEDDED
	[self.session stopRunning];
#endif
	
	iOSFaceTrackerAppDelegate *appDelegate = (iOSFaceTrackerAppDelegate*)[[UIApplication sharedApplication] delegate];
	appDelegate.settingsController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self presentModalViewController:appDelegate.settingsController animated:YES];
}

- (void)dealloc {
	[recognizer release], recognizer = nil;
	[trainer release], trainer = nil;
#if TARGET_OS_EMBEDDED
	cvReleaseMemStorage(&storage);
	cvReleaseHaarClassifierCascade(&cascade);
#endif
	[super dealloc];
}

#pragma mark -
#pragma mark FBRequestDelegate

-(void)isDone {
#if TARGET_OS_EMBEDDED
	[self.session startRunning];
#endif
	
}

@end
