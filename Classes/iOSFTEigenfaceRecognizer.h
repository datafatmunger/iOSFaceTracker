//
//  iOSFTEigenfaceRecognizer.h
//  iOSFaceTracker
//
//  Created by James Bryan Graves on 12/18/10.
//  Copyright 2010 Sogeo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <opencv/cv.h>
#import <opencv/cvaux.h>

@interface iOSFTEigenfaceRecognizer : NSObject {

	int nTrainFaces; // the number of training images
	int nEigens; // the number of eigenvalues
	IplImage *pAvgTrainImg; // the average image
	IplImage **eigenVectArr; // eigenvectors
	CvMat *eigenValMat; // eigenvalues
	CvMat *projectedTrainFaceMat; // projected training faces
	CvMat *trainPersonNumMat;  // the person numbers during training
}

@property(readonly)int nTrainFaces;

-(void)recognize:(IplImage*)face;
-(void)reloadTrainingData;

@end
