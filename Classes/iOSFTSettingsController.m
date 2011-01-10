//
//  iOSFTSettingsController.m
//  iOSFaceTracker
//
//  Created by James Bryan Graves on 12/19/10.
//  Copyright 2010 Sogeo. All rights reserved.
//

#import "iOSFTEigenfaceTrainer.h"
#import "iOSFTSettingsController.h"

@implementation iOSFTSettingsController

@synthesize delegate = _delegate;
@synthesize actView = _actView;
@synthesize facebookButton = _facebookButton;
@synthesize fbProcessor = _fbProcessor;
@synthesize statusLabel = _statusLabel;

-(void)formatButtons {
	if(![_fbProcessor.facebook isSessionValid])
		[_facebookButton setImage:[UIImage imageNamed:@"FBConnect.bundle/images/LoginWithFacebookNormal.png"]
						 forState:UIControlStateNormal];
	else
		[_facebookButton setImage:[UIImage imageNamed:@"FBConnect.bundle/images/LogoutNormal.png"]
						 forState:UIControlStateNormal];
}

-(void)viewDidLoad {	
	_fbProcessor = [[iOSFTFacebookProcessor alloc] init];
	_fbProcessor.delegate = self;
}

-(void)viewWillAppear:(BOOL)animated {
	[self formatButtons];
}

-(IBAction)done:(id)sender {
	[_delegate isDone];
	[self dismissModalViewControllerAnimated:YES];
}

-(IBAction)login:(id)sender {
	[_fbProcessor login];
}

-(void)dealloc {
	[_delegate release], _delegate = nil;
	[_fbProcessor release], _fbProcessor = nil;
	[super dealloc];
}

#pragma mark -
#pragma mark iOSFTFacebookProcessorDelegate

-(void)fbDidLogin {
	[_actView startAnimating];
	[_facebookButton setImage:[UIImage imageNamed:@"FBConnect.bundle/images/LogoutNormal.png"]
					 forState:UIControlStateNormal];
}

-(void)fbDidLogout {
	[_facebookButton setImage:[UIImage imageNamed:@"FBConnect.bundle/images/LoginWithFacebookNormal.png"]
					 forState:UIControlStateNormal];
}

-(void)fbProcessStatus:(NSString*)message {
	_statusLabel.text = message;
}

@end
