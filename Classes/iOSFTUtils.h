//
//  iOSFTUtils.h
//  iOSFaceTracker
//
//  Created by James Bryan Graves on 12/23/10.
//  Copyright 2010 Sogeo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <opencv/cv.h>

@interface iOSFTUtils : NSObject {

}

+(IplImage*)createIplImageFromUIImage:(UIImage *)image;

@end
