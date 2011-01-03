//
//  iOSFTEigenfaceTrainer.m
//  iOSFaceTracker
//
//  Created by James Bryan Graves on 12/19/10.
//  Copyright 2010 Sogeo. All rights reserved.
//

#import "iOSFTEigenfaceTrainer.h"

@interface iOSFTEigenfaceTrainer (Private)

-(void)doPCA;
-(void)storeTrainingData;

@end

@implementation iOSFTEigenfaceTrainer

@synthesize faceImgArr;
@synthesize nTrainFaces;

-(id)init {
	if(self = [super init]) {
		personNumTruthMat = cvCreateMat( 1, 1, CV_32SC1 ); // array of person numbers
		nTrainFaces = 0; // the number of training images
		nEigens = 0; // the number of eigenvalues
		pAvgTrainImg = 0; // the average image
		eigenVectArr = 0; // eigenvectors
		eigenValMat = 0; // eigenvalues
		projectedTrainFaceMat = 0; // projected training faces
		trainPersonNumMat = 0;  // the person numbers during training
		faceImgArr = 0; // array of face images
	}
	return self;
}

-(void)learn {
	int i, offset;
	
	NSAssert(nTrainFaces > 1,
			 @"Need at least 2 faces to run the trainer");
	
	// do PCA on the training faces
	[self doPCA];
	
	// project the training images onto the PCA subspace
	projectedTrainFaceMat = cvCreateMat( nTrainFaces, nEigens, CV_32FC1 );
	offset = projectedTrainFaceMat->step / sizeof(float);
	for(i=0; i<nTrainFaces; i++)
	{
		//int offset = i * nEigens;
		cvEigenDecomposite(
						   faceImgArr[i],
						   nEigens,
						   eigenVectArr,
						   0, 0,
						   pAvgTrainImg,
						   //projectedTrainFaceMat->data.fl + i*nEigens);
						   projectedTrainFaceMat->data.fl + i*offset);
	}
	
	// store the recognition data as an xml file
	[self storeTrainingData];
}

#pragma mark -
#pragma mark iOSFTEigenfaceTrainer (Private)

-(void)doPCA {
	int i;
	CvTermCriteria calcLimit;
	CvSize faceImgSize;
	
	// set the number of eigenvalues to use
	nEigens = nTrainFaces-1;
	
	// allocate the eigenvector images
	faceImgSize.width  = faceImgArr[0]->width;
	faceImgSize.height = faceImgArr[0]->height;
	eigenVectArr = (IplImage**)cvAlloc(sizeof(IplImage*) * nEigens);
	for(i=0; i<nEigens; i++)
		eigenVectArr[i] = cvCreateImage(faceImgSize, IPL_DEPTH_32F, 1);
	
	// allocate the eigenvalue array
	eigenValMat = cvCreateMat( 1, nEigens, CV_32FC1 );
	
	// allocate the averaged image
	pAvgTrainImg = cvCreateImage(faceImgSize, IPL_DEPTH_32F, 1);
	
	// set the PCA termination criterion
	calcLimit = cvTermCriteria( CV_TERMCRIT_ITER, nEigens, 1);
	
	// compute average image, eigenvalues, and eigenvectors
	cvCalcEigenObjects(
					   nTrainFaces,
					   (void*)faceImgArr,
					   (void*)eigenVectArr,
					   CV_EIGOBJ_NO_CALLBACK,
					   0,
					   0,
					   &calcLimit,
					   pAvgTrainImg,
					   eigenValMat->data.fl);
	
	cvNormalize(eigenValMat, eigenValMat, 1, 0, CV_L1, 0);
}

-(void)storeTrainingData {
	CvFileStorage * fileStorage;
	int i;
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
	basePath = [basePath stringByAppendingString:@"/facedata.xml"];
	
	// create a file-storage interface
	fileStorage = cvOpenFileStorage([basePath cStringUsingEncoding:NSUTF8StringEncoding], 0, CV_STORAGE_WRITE );
	
	// store all the data
	cvWriteInt( fileStorage, "nEigens", nEigens );
	cvWriteInt( fileStorage, "nTrainFaces", nTrainFaces );
	cvWrite(fileStorage, "trainPersonNumMat", personNumTruthMat, cvAttrList(0,0));
	cvWrite(fileStorage, "eigenValMat", eigenValMat, cvAttrList(0,0));
	cvWrite(fileStorage, "projectedTrainFaceMat", projectedTrainFaceMat, cvAttrList(0,0));
	cvWrite(fileStorage, "avgTrainImg", pAvgTrainImg, cvAttrList(0,0));
	for(i=0; i<nEigens; i++)
	{
		char varname[200];
		sprintf( varname, "eigenVect_%d", i );
		cvWrite(fileStorage, varname, eigenVectArr[i], cvAttrList(0,0));
	}
	
	// release the file-storage interface
	cvReleaseFileStorage( &fileStorage );
}

@end
