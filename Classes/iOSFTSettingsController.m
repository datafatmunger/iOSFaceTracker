//
//  iOSFTSettingsController.m
//  iOSFaceTracker
//
//  Created by James Bryan Graves on 12/19/10.
//  Copyright 2010 Sogeo. All rights reserved.
//

#import "iOSFTEigenfaceTrainer.h"
#import "iOSFTSettingsController.h"
#import "iOSFTUtils.h"

static NSString* kAppId = @"149922748392801";

@implementation iOSFTSettingsController

@synthesize delegate = _delegate;
@synthesize facebook = _facebook;
@synthesize actView = _actView;
@synthesize facebookButton = _facebookButton;
@synthesize statusLabel = _statusLabel;

-(IplImage*)makeProcessable:(IplImage*)iplImage {
	IplImage *processed_image = nil;
	
	IplImage *image = cvCreateImage(cvGetSize(iplImage), IPL_DEPTH_8U, 3);
	cvCvtColor(iplImage, image, CV_BGRA2BGR);
	
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
		
		IplImage *cropped_image = nil;
		cropped_image = cvCreateImage(cvGetSize(small_image), IPL_DEPTH_8U, 1);
		cvCvtColor(small_image, cropped_image, CV_BGR2GRAY);
		
		processed_image = cvCreateImage(cvSize(92, 112), IPL_DEPTH_8U, 1);
		cvResize(cropped_image, processed_image, 1);
		
		cvReleaseImage(&cropped_image);
		
		cvResetImageROI(small_image);
		
	}
	cvReleaseImage(&small_image);
	
	return processed_image;
	
}

-(void)processAlbumList:(NSArray*)albums {
	for(NSDictionary *album in albums) {
		NSString *type = [album objectForKey:@"type"];
		if([type isEqualToString:@"profile"])
			_profileAlbumId = [[album objectForKey:@"id"] copy];
	}
}

-(void)processProfilePics:(NSArray*)pics {
	
	NSMutableArray *imageUrls = [[NSMutableArray alloc] init];
	for(NSDictionary *pic in pics) {
		NSArray *images = [pic objectForKey:@"images"];
		NSDictionary *image = [images objectAtIndex:0];
		NSString *imageUrl = [image objectForKey:@"source"];
		NSLog(@"%@", imageUrl);
		[imageUrls addObject:imageUrl];
	}
	
	_trainer.faceImgArr = (IplImage **)cvAlloc(imageUrls.count*sizeof(IplImage *));
	
	_statusLabel.text = @"Loading/cropping for trainer. . .";
	[_statusLabel performSelectorOnMainThread:@selector(setNeedsDisplay)
								   withObject:nil
								waitUntilDone:YES];
	
	for(int iFace = 0; iFace < imageUrls.count; iFace++) {
		UIImage *uiImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[imageUrls objectAtIndex:iFace]]]];
		IplImage *iplImage = [iOSFTUtils createIplImageFromUIImage:uiImage];
		
		IplImage *cropped_image = [self makeProcessable:iplImage];
		
		//TODO : cropped Images are probably leaking here.
		
		if(cropped_image != nil) {
			_trainer.faceImgArr[_trainer.nTrainFaces] = cropped_image;
			_trainer.nTrainFaces++;
		}
	
		cvReleaseImage(&iplImage);
	}
	
	if(_trainer.nTrainFaces < 2) {
		[_actView stopAnimating];
		_statusLabel.text = @"Error: need to detect at least 2 faces to train.";
		[_statusLabel performSelectorOnMainThread:@selector(setNeedsDisplay)
									   withObject:nil
									waitUntilDone:YES];
		_failed = YES;
		
	} else {
		_statusLabel.text = @"Training. . .";
		[_statusLabel performSelectorOnMainThread:@selector(setNeedsDisplay)
									   withObject:nil
									waitUntilDone:YES];
		[_trainer learn];
	}
		
	
	
}

-(void)formatButtons {
	if(![_facebook isSessionValid])
		[_facebookButton setImage:[UIImage imageNamed:@"FBConnect.bundle/images/LoginWithFacebookNormal.png"]
						 forState:UIControlStateNormal];
	else
		[_facebookButton setImage:[UIImage imageNamed:@"FBConnect.bundle/images/LogoutNormal.png"]
						 forState:UIControlStateNormal];
}

-(void)viewDidLoad {	
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

-(void)viewWillAppear:(BOOL)animated {
	[self formatButtons];
}

-(IBAction)done:(id)sender {
	[_delegate isDone];
	[self dismissModalViewControllerAnimated:YES];
}

-(void)getAlbums {
	_statusLabel.text = @"Getting Facebook Albums. . .";
	[_facebook requestWithGraphPath:@"me/albums"
						andDelegate:self];
}

-(void)getProfilePics {
	_statusLabel.text = @"Getting Profile Pics. . .";
	[_facebook requestWithGraphPath:[NSString stringWithFormat:@"%@/photos", _profileAlbumId]
						andDelegate:self];
}

-(IBAction)login:(id)sender {
	if(![_facebook isSessionValid])
		[_facebook authorize:_permissions delegate:self];
	else
		[_facebook logout:self];
		
}

-(void)dealloc {
	[_facebook release], _facebook = nil;
	[_permissions release], _permissions = nil;
	[super dealloc];
}

#pragma mark -
#pragma mark FBSessionDelegate

- (void)fbDidLogin {
	NSLog(@"token: %@", _facebook.accessToken);
	
	_requestNumber = 0;
	[_actView startAnimating];
	
	[_facebookButton setImage:[UIImage imageNamed:@"FBConnect.bundle/images/LogoutNormal.png"]
					 forState:UIControlStateNormal];
	
	[self getAlbums];
}

-(void)fbDidNotLogin:(BOOL)cancelled {
}

- (void)fbDidLogout {
	[_facebookButton setImage:[UIImage imageNamed:@"FBConnect.bundle/images/LoginWithFacebookNormal.png"]
					 forState:UIControlStateNormal];
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
	
	switch (_requestNumber) {
		case 0:
			[self processAlbumList:[result objectForKey:@"data"]];
			[self getProfilePics];
			break;
		case 1:
			[self processProfilePics:[result objectForKey:@"data"]];
			if(!_failed) {
				[_actView stopAnimating];
				_statusLabel.text = @"Done.";
			}
			break;
		default:
			NSLog(@"Unknown request state: %d", _requestNumber); 
			break;
	}
	_requestNumber++;
};

- (void)request:(FBRequest *)request didFailWithError:(NSError *)error {
	NSLog(@"Facebook Error: %@", [error localizedDescription]);
};

@end
