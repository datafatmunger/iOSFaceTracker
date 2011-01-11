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
@synthesize faceName = _faceName;
@synthesize image = _image;

-(id)initWithFrame:(CGRect)frame {
	if(self = [super initWithFrame:frame]) {
		_image = nil;
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
	
	[_image drawAtPoint:CGPointMake(10, rect.size.height - 112 - 10)];
	
	[[UIColor blueColor] set];
	
	if(_faceName) {
		UIFont *font = [UIFont systemFontOfSize:17];
		CGSize size = [_faceName sizeWithFont:font
							constrainedToSize:faceRect.size
								lineBreakMode:UILineBreakModeTailTruncation];
		
		[_faceName drawAtPoint:CGPointMake(faceRect.origin.x + (faceRect.size.width/2) - (size.width / 2),
										   faceRect.origin.y + (faceRect.size.height/2) - (size.height / 2))
					  withFont:font];
	}
	
	faceRect = CGRectZero;
	self.faceName = nil;
}

-(void)dealloc {
	self.image = nil;
	[super dealloc];
}
	


@end
