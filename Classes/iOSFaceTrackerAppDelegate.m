//
//  iOSFaceTrackerAppDelegate.m
//  iOSFaceTracker
//
//  Created by James Bryan Graves on 12/12/10.
//  Copyright 2010 Sogeo. All rights reserved.
//

#import "iOSFaceTrackerAppDelegate.h"

@implementation iOSFaceTrackerAppDelegate

@synthesize window;
#if TARGET_OS_EMBEDDED
@synthesize session;
#endif

#if TARGET_OS_EMBEDDED
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
	CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	CVPixelBufferLockBaseAddress(imageBuffer, 0);
	
	//size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
	size_t width = CVPixelBufferGetWidth(imageBuffer); 
	size_t height = CVPixelBufferGetHeight(imageBuffer);
	uint8_t *readblePixels = (uint8_t*)CVPixelBufferGetBaseAddress(imageBuffer);
	
	//	NSLog(@"bytesPerRow: %d, width %d, height %d", bytesPerRow, width, height);
	
	if (readblePixels) {
		IplImage *iplimage = cvCreateImage(cvSize(width, height), IPL_DEPTH_8U, 4);
		iplimage->imageData = (char*)readblePixels;
		//		iplimage->widthStep = bytesPerRow;
		
		IplImage *image = cvCreateImage(cvGetSize(iplimage), IPL_DEPTH_8U, 3);
		cvCvtColor(iplimage, image, CV_BGRA2BGR);
		cvReleaseImage(&iplimage);
		
		// Scaling down
		int scale = 2;
		IplImage *small_image = cvCreateImage(cvSize(image->width/scale,image->height/scale), IPL_DEPTH_8U, 3);
		cvPyrDown(image, small_image, CV_GAUSSIAN_5x5);
		cvReleaseImage(&image);
		
		// Detect faces and draw rectangle on them
		CvSeq* faces = cvHaarDetectObjects(small_image, cascade, storage, 1.2f, 3, CV_HAAR_DO_CANNY_PRUNING, cvSize(small_image->width/3, small_image->height/2));
		
		
		// Draw results on the image
		NSLog(@"found %d faces", faces->total);
		
		if(faces->total > 0) {
			CvRect cvrect = *(CvRect*)cvGetSeqElem(faces, 0);
			
			//START - Crop and process - JBG
			cvSetImageROI(small_image, cvrect);
			IplImage *cropped_image = cvCreateImage(cvGetSize(small_image), small_image->depth, small_image->nChannels);
			cvCopy(small_image, cropped_image, NULL);
			//TODO - Add Eigenface processing/searching here. - JBG
			cvResetImageROI(small_image);
			cvReleaseImage(&cropped_image);
			//END - Crop and process - JBG
			
			
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
			
			if(prevRect.size.width != 0 && prevRect.size.height != 0) {
				contentView.faceRect = cvrect2scale;
				[contentView performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:YES];
			}
			
			prevRect = cvrect2scale;
		}
		cvReleaseImage(&small_image);
	}
	
	CVPixelBufferUnlockBaseAddress(imageBuffer,0);
}
#endif

- (void)applicationDidFinishLaunching:(UIApplication *)application {	
	
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
	
	CGRect layerRect = self.window.layer.bounds;
	previewLayer.bounds = layerRect;
	previewLayer.position = CGPointMake(CGRectGetMidX(layerRect), CGRectGetMidY(layerRect));
	[self.window.layer addSublayer:previewLayer];
	[self.session startRunning];
#endif
	contentView = [[iOSFTContentView alloc] initWithFrame:window.frame];
	[self.window addSubview:contentView];
	
	[self.window makeKeyAndVisible];
}


- (void)applicationWillResignActive:(UIApplication *)application {
	
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
	
}

- (void)dealloc {
#if TARGET_OS_EMBEDDED
	cvReleaseMemStorage(&storage);
	cvReleaseHaarClassifierCascade(&cascade);
#endif
	
	[window release];
	[super dealloc];
}

@end
