//
//  iOSFTSettingsController.h
//  iOSFaceTracker
//
//  Created by James Bryan Graves on 12/19/10.
//  Copyright 2010 Sogeo. All rights reserved.
//

#import "FBConnect.h"
#import <Foundation/Foundation.h>
#import "iOSFTEigenfaceTrainer.h"
#import <opencv/cv.h>

@protocol iOSFTSettingsControllerDelegate

-(void)isDone;

@end



@interface iOSFTSettingsController : UIViewController <FBRequestDelegate, FBSessionDelegate> {
	Facebook *_facebook;
	NSArray *_permissions;
	
	UIActivityIndicatorView *_actView;
	UIButton *_facebookButton;
	UILabel *_statusLabel;
	
	id<iOSFTSettingsControllerDelegate> _delegate;
	
	NSInteger _requestNumber;
	
	NSString *_profileAlbumId;
	
	CvHaarClassifierCascade* cascade;
	CvMemStorage* storage;
	
	iOSFTEigenfaceTrainer *_trainer;
	BOOL _failed;
}

@property(nonatomic,retain)IBOutlet id<iOSFTSettingsControllerDelegate> delegate;
@property(nonatomic,retain)Facebook *facebook;
@property(nonatomic,retain)IBOutlet UIActivityIndicatorView *actView;
@property(nonatomic,retain)IBOutlet UIButton *facebookButton;
@property(nonatomic,retain)IBOutlet UILabel *statusLabel;

-(IBAction)done:(id)sender;
-(void)formatButtons;
-(IBAction)login:(id)sender;

@end
