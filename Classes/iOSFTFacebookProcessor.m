//
//  iOSFTFacebookProcessor.m
//  iOSFaceTracker
//
//  Created by James Bryan Graves on 1/10/11.
//  Copyright 2011 Sogeo. All rights reserved.
//

#import "iOSFTFacebookProcessor.h"
#import "iOSFTUtils.h"

static NSString* kAppId = @"149922748392801";

@implementation iOSFTFacebookProcessor

@synthesize delegate = _delegate;
@synthesize facebook = _facebook;

-(id)init {
	if(self = [super init]) {
		_facebook = [[Facebook alloc] initWithAppId:kAppId];
		_permissions = [[NSArray arrayWithObjects:
						 @"read_stream",
						 @"offline_access",
						 @"user_photo_video_tags",
						 @"user_photos",
						 @"friends_photos",
						 nil] retain];
		
		NSString *path = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_default" ofType:@"xml"];
		cascade = (CvHaarClassifierCascade*)cvLoad([path cStringUsingEncoding:NSASCIIStringEncoding], NULL, NULL, NULL);
		storage = cvCreateMemStorage(0);
		_trainer = [[iOSFTEigenfaceTrainer alloc] init];
	}
	return self;
}

-(void)getAlbums {
	[_delegate fbProcessStatus:@"Getting Facebook Albums. . ."];
	[_facebook requestWithGraphPath:@"me/albums"
						andDelegate:self];
}

-(void)getAlbumPics:(NSString*)albumId {
	[_delegate fbProcessStatus:[NSString stringWithFormat:@"Getting %@ Pics. . .", albumId]];
	[_facebook requestWithGraphPath:[NSString stringWithFormat:@"%@/photos", albumId]
						andDelegate:self];
}

-(void)login {
	if(![_facebook isSessionValid])
		[_facebook authorize:_permissions delegate:self];
	else
		[_facebook logout:self];
}

-(void)processAlbumList:(NSArray*)albums {
	for(NSDictionary *album in albums) {
		//NSString *type = [album objectForKey:@"type"];
		[self getAlbumPics:[album objectForKey:@"id"]];
	}
}

-(void)processAlbum:(NSArray*)pics {
	_faces = [[NSMutableArray alloc] init];
	
	for(NSDictionary *pic in pics) {		
		NSArray *images = [pic objectForKey:@"images"];
		NSDictionary *image = [images objectAtIndex:0];
		NSString *imageUrl = [image objectForKey:@"source"];
		UIImage *uiImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageUrl]]];
		IplImage *iplImage = [iOSFTUtils createIplImageFromUIImage:uiImage];
		
		IplImage *processed_image = nil;
		
		IplImage *bgr_image = cvCreateImage(cvGetSize(iplImage), IPL_DEPTH_8U, 3);
		cvCvtColor(iplImage, bgr_image, CV_BGRA2BGR);
		cvReleaseImage(&iplImage);
		
		// Scaling down
		double scale = 0.5;
		IplImage *small_image = cvCreateImage(cvSize(bgr_image->width/scale,bgr_image->height/scale), IPL_DEPTH_8U, 3);
		cvPyrUp(bgr_image, small_image, CV_GAUSSIAN_5x5);
		cvReleaseImage(&bgr_image);
		
		// Detect faces and draw rectangle on them
		CvSeq* faces = cvHaarDetectObjects(small_image, cascade, storage, 1.2f, 3, CV_HAAR_DO_CANNY_PRUNING, cvSize(small_image->width/3, small_image->height/2));
		
		NSDictionary *tags = [pic objectForKey:@"tags"];
		NSArray *tagData = [tags objectForKey:@"data"];
		
		// Draw results on the image
		NSLog(@"found %d faces, photo contains %d tags, image: %@",
			  faces->total,
			  tagData.count,
			  imageUrl);
		
		for(NSInteger i = 0; i < faces->total; i++) {
			CvRect cvrect = *(CvRect*)cvGetSeqElem(faces, i);
			
			CvPoint2D32f midPoint = cvPoint2D32f(cvrect.x + (cvrect.width / 2.0),
												 cvrect.y + (cvrect.width / 2.0));
			
			NSString *winningName = nil;
			double distance = MAXFLOAT;
			for(NSDictionary *tag in tagData) {
				NSString *name = [NSString stringWithFormat:@"%@", [tag objectForKey:@"name"]];
				NSLog(@"Checking tag: %@", name);
				CvPoint2D32f tagPoint = cvPoint2D32f([[tag objectForKey:@"x"] doubleValue],
													 [[tag objectForKey:@"y"] doubleValue]);
				
				double currentDistance = sqrt(pow(fabs(tagPoint.x - midPoint.x), 2) + pow(fabs(tagPoint.y - midPoint.y), 2));
				if(currentDistance < distance) {
					winningName = [name retain];
					distance = currentDistance;
				}
			}
			
			NSLog(@"Face at %f, %f is probably %@",
				  midPoint.x,
				  midPoint.y,
				  winningName ? winningName : @"Unknown");
			
			//START - Crop and process - JBG
			cvSetImageROI(small_image, cvrect);
			
			IplImage *cropped_image = nil;
			cropped_image = cvCreateImage(cvGetSize(small_image), IPL_DEPTH_8U, 1);
			cvCvtColor(small_image, cropped_image, CV_BGR2GRAY);
			
			processed_image = cvCreateImage(cvSize(92, 112), IPL_DEPTH_8U, 1);
			cvResize(cropped_image, processed_image, 1);
			
			//TODO : Do something with processed_image - JBG
			
			cvReleaseImage(&cropped_image);
			
			cvResetImageROI(small_image);
			
		}
		cvReleaseImage(&small_image);
		
	}
	
	//	NSMutableArray *imageUrls = [[NSMutableArray alloc] init];
	//	for(NSDictionary *pic in pics) {
	//		NSArray *images = [pic objectForKey:@"images"];
	//		NSDictionary *image = [images objectAtIndex:0];
	//		NSString *imageUrl = [image objectForKey:@"source"];
	//		NSLog(@"%@", imageUrl);
	//		[imageUrls addObject:imageUrl];
	//	}
	
	//	_trainer.faceImgArr = (IplImage **)cvAlloc(imageUrls.count*sizeof(IplImage *));
	//	
	//	_statusLabel.text = @"Loading/cropping for trainer. . .";
	//	[_statusLabel performSelectorOnMainThread:@selector(setNeedsDisplay)
	//								   withObject:nil
	//								waitUntilDone:YES];
	//	
	//	for(int iFace = 0; iFace < imageUrls.count; iFace++) {
	//		UIImage *uiImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[imageUrls objectAtIndex:iFace]]]];
	//		IplImage *iplImage = [iOSFTUtils createIplImageFromUIImage:uiImage];
	//		
	//		IplImage *cropped_image = [self makeProcessable:iplImage];
	//		
	//		//TODO : cropped Images are probably leaking here.
	//		
	//		if(cropped_image != nil) {
	//			_trainer.faceImgArr[_trainer.nTrainFaces] = cropped_image;
	//			_trainer.nTrainFaces++;
	//		}
	//	
	//		cvReleaseImage(&iplImage);
	//	}
	//	
	//	if(_trainer.nTrainFaces < 2) {
	//		[_actView stopAnimating];
	//		_statusLabel.text = @"Error: need to detect at least 2 faces to train.";
	//		[_statusLabel performSelectorOnMainThread:@selector(setNeedsDisplay)
	//									   withObject:nil
	//									waitUntilDone:YES];
	//		_failed = YES;
	//		
	//	} else {
	//		_statusLabel.text = @"Training. . .";
	//		[_statusLabel performSelectorOnMainThread:@selector(setNeedsDisplay)
	//									   withObject:nil
	//									waitUntilDone:YES];
	//		[_trainer learn];
	//	}
	
}

-(void)dealloc {
	[_delegate release], _delegate = nil;
	[_facebook release], _facebook = nil;
	[_permissions release], _permissions = nil;
	[super dealloc];
}

#pragma mark -
#pragma mark FBSessionDelegate

- (void)fbDidLogin {
	NSLog(@"token: %@", _facebook.accessToken);
	
	_requestNumber = 0;
	[_delegate fbDidLogin];
	[self getAlbums];
}

-(void)fbDidNotLogin:(BOOL)cancelled {
}

- (void)fbDidLogout {
	[_delegate fbDidLogout];
}

#pragma mark -
#pragma mark FBRequestDelegate

- (void)request:(FBRequest *)request didReceiveResponse:(NSURLResponse *)response {
	NSLog(@"received response. . .");
};

- (void)request:(FBRequest *)request didLoad:(id)result {
	if([result isKindOfClass:[NSArray class]]) {
		NSLog(@"Facebook sent an array");
	} else if([result isKindOfClass:[NSDictionary class]]) {
		NSLog(@"Facebook sent a dictionary");
	}  else {
		NSLog(@"Facebook sent a %@", NSStringFromClass([result class]));
	}
	
	if(_requestNumber == 0) {
		NSLog(@"%@", [result description]);
		[self processAlbumList:[result objectForKey:@"data"]];
	} else
		[self processAlbum:[result objectForKey:@"data"]];
	
	_requestNumber++;
};

- (void)request:(FBRequest *)request didFailWithError:(NSError *)error {
	NSLog(@"Facebook Error: %@", [error localizedDescription]);
};

@end
