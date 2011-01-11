//
//  iOSFTSettingsController.h
//  iOSFaceTracker
//
//  Created by James Bryan Graves on 12/19/10.
//  Copyright 2010 Sogeo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iOSFTFacebookProcessor.h"

@protocol iOSFTSettingsControllerDelegate <NSObject>

-(void)isDone;
-(void)clearTrainingData;

@end

@interface iOSFTSettingsController : UIViewController <iOSFTFacebookProcessorDelegate> {	
	UIActivityIndicatorView *_actView;
	UIButton *_facebookButton;
	UILabel *_statusLabel;
	
	iOSFTFacebookProcessor *_fbProcessor;
	
	id<iOSFTSettingsControllerDelegate> _delegate;
}

@property(nonatomic,retain)IBOutlet id<iOSFTSettingsControllerDelegate> delegate;
@property(nonatomic,retain)IBOutlet UIActivityIndicatorView *actView;
@property(nonatomic,retain)IBOutlet UIButton *facebookButton;
@property(nonatomic,retain)IBOutlet UILabel *statusLabel;

@property(nonatomic,retain)iOSFTFacebookProcessor *fbProcessor;

-(IBAction)clearTrainingData:(id)sender;
-(IBAction)done:(id)sender;
-(void)formatButtons;
-(IBAction)login:(id)sender;
-(IBAction)onTrainingMode:(id)sender;



@end
