//
//  iOSFTEigenfaceTrainer.h
//  iOSFaceTracker
//
//  Created by James Bryan Graves on 12/19/10.
//  Copyright 2010 Sogeo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iOSFTEigenfaceRecognizer.h"
#import <opencv/cv.h>
#import <opencv/cvaux.h>

@interface iOSFTEigenfaceTrainer : NSObject {
	
	int nTrainFaces; // the number of training images
	int nEigens; // the number of eigenvalues
	IplImage *pAvgTrainImg; // the average image
	IplImage **eigenVectArr; // eigenvectors
	CvMat *eigenValMat; // eigenvalues
	CvMat *projectedTrainFaceMat; // projected training faces
	CvMat *trainPersonNumMat;  // the person numbers during training
	IplImage **faceImgArr; // array of face images
	
	char **eigenNameArr; // array of names
	
	NSString *_faceName;
	

}

@property(nonatomic,assign)int nTrainFaces;
@property(nonatomic,assign)IplImage **faceImgArr;
@property(nonatomic,retain)NSString *faceName;

-(void)clearTrainingData;
-(void)learn:(iOSFTEigenfaceRecognizer*)recognizer;

@end
