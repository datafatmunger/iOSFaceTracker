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
	char **eigenNameArr;
	
	NSString *_faceName;
}

@property(nonatomic,readonly)int nTrainFaces;
@property(nonatomic,readonly)int nEigens;
@property(nonatomic,readonly)IplImage *pAvgTrainImg;
@property(nonatomic,readonly)IplImage **eigenVectArr;
@property(nonatomic,readonly)CvMat *eigenValMat;
@property(nonatomic,readonly)CvMat *projectedTrainFaceMat;
@property(nonatomic,readonly)char **eigenNameArr;
@property(nonatomic,retain)NSString *faceName;

-(void)recognize:(IplImage*)face;
-(void)reloadTrainingData;

@end
