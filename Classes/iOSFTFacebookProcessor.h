//
//  iOSFTFacebookProcessor.h
//  iOSFaceTracker
//
//  Created by James Bryan Graves on 1/10/11.
//  Copyright 2011 Sogeo. All rights reserved.
//

#import "FBConnect.h"
#import <Foundation/Foundation.h>
#import "iOSFTEigenfaceTrainer.h"
#import <opencv/cv.h>

@protocol iOSFTFacebookProcessorDelegate <NSObject>

-(void)fbDidLogin;
-(void)fbDidLogout;
-(void)fbProcessStatus:(NSString*)message;

@end

@interface iOSFTFacebookProcessor : NSObject <FBRequestDelegate, FBSessionDelegate> {
	Facebook *_facebook;
	NSArray *_permissions;
	
	NSInteger _requestNumber;
	
	CvHaarClassifierCascade* cascade;
	CvMemStorage* storage;
	
	iOSFTEigenfaceTrainer *_trainer;
	BOOL _failed;
	
	NSMutableArray *_faces;
	
	id<iOSFTFacebookProcessorDelegate> _delegate;
}

@property(nonatomic,retain)Facebook *facebook;
@property(nonatomic,retain)id<iOSFTFacebookProcessorDelegate> delegate;;

-(void)login;

@end
