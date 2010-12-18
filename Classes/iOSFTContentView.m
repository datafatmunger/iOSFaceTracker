//
//  ContentView.m
//  Simple_TextureCubemap
//
//  Created by James Bryan Graves on 8/22/10.
//  Copyright 2010 Sogeo. All rights reserved.
//

#import "iOSFTContentView.h"

@implementation iOSFTContentView

@synthesize faceRect;

-(id)initWithFrame:(CGRect)frame {
	if(self = [super initWithFrame:frame]) {
		self.backgroundColor = [UIColor clearColor];
		faceRect = CGRectZero;
	}
	return self;
}

-(void)layoutSubviews {
	[super layoutSubviews];
}

-(void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGContextSetRGBStrokeColor(ctx, 0, 0, 1.0, 1);
	CGContextStrokeRect(ctx, faceRect);
	CGContextStrokePath(ctx);
	faceRect = CGRectZero;
}


@end
