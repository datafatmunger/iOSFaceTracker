//
//  ContentView.h
//  Simple_TextureCubemap
//
//  Created by James Bryan Graves on 8/22/10.
//  Copyright 2010 Sogeo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface iOSFTContentView : UIView {
	CGRect faceRect;
	
	UIImage *_image;
	NSString *_faceName;
}

@property(assign)CGRect faceRect;
@property(nonatomic,retain)UIImage *image;
@property(nonatomic,retain)NSString *faceName;

@end
