//
//  iOSFTEigenfaceRecognizer.m
//  iOSFaceTracker
//
//  Created by James Bryan Graves on 12/18/10.
//  Copyright 2010 Sogeo. All rights reserved.
//

#import "iOSFTEigenfaceRecognizer.h"

@interface iOSFTEigenfaceRecognizer (Private)

-(NSInteger)findNearestNeighbor:(float*)projectedTestFace;
-(NSInteger)loadTrainingData;

@end


@implementation iOSFTEigenfaceRecognizer

@synthesize nTrainFaces;
@synthesize nEigens;
@synthesize pAvgTrainImg;
@synthesize eigenVectArr;
@synthesize eigenValMat;
@synthesize projectedTrainFaceMat;

-(id)init {
	if(self = [super init]) {		
		// load the saved training data
		[self reloadTrainingData];
	}
	return self;
}

-(void)recognize:(IplImage*)face {

	float *projectedTestFace = 0;
	
	// project the test images onto the PCA subspace
	projectedTestFace = (float*)cvAlloc(nEigens * sizeof(float));

	int iNearest = 0;//, nearest = 0, truth = 0;
	
	// project the test image onto the PCA subspace
	cvEigenDecomposite(face,
					   nEigens,
					   eigenVectArr,
					   0, 0,
					   pAvgTrainImg,
					   projectedTestFace);
	
	iNearest = [self findNearestNeighbor:projectedTestFace];
	
	//This would be the id of the person. . .if I stored that shit - JBG
	//nearest  = trainPersonNumMat->data.i[iNearest];
	if(iNearest > -1) {
		printf("nearest = %d\n");
		printf("name = %s\n", eigenNameArr[iNearest]);
	} else
		printf("match FAIL!");

}

-(void)reloadTrainingData {
	nTrainFaces = 0; // the number of training images
	nEigens = 0; // the number of eigenvalues
	pAvgTrainImg = 0; // the average image
	eigenVectArr = 0; // eigenvectors
	eigenValMat = 0; // eigenvalues
	projectedTrainFaceMat = 0; // projected training faces
	eigenNameArr = 0;  // the person numbers during training
	
	if(![self loadTrainingData])
		NSLog(@"No training data");
}

#pragma mark -
#pragma mark iOSFTEigenfaceRecognizer (Private)

-(NSInteger)findNearestNeighbor:(float*)projectedTestFace {
	//double leastDistSq = 1e12;
	double leastDistSq = DBL_MAX;
	int i, iTrain, iNearest = -1;
	
	for(iTrain=0; iTrain<nTrainFaces; iTrain++) {
		double distSq=0;
		
		for(i=0; i<nEigens; i++) {
			float d_i =
			projectedTestFace[i] -
			projectedTrainFaceMat->data.fl[iTrain*nEigens + i];
			//distSq += d_i*d_i / eigenValMat->data.fl[i];  // Mahalanobis
			distSq += d_i*d_i; // Euclidean
		}
		
		if(distSq < leastDistSq) {
			leastDistSq = distSq;
			iNearest = iTrain;
		}
	}
	
	return iNearest;
}

-(NSInteger)loadTrainingData {
	
	CvFileStorage * fileStorage;
	int i;
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
	basePath = [basePath stringByAppendingString:@"/facedata.xml"];
	
	// create a file-storage interface
	fileStorage = cvOpenFileStorage([basePath cStringUsingEncoding:NSUTF8StringEncoding], 0, CV_STORAGE_READ );
	if( !fileStorage ) {
		fprintf(stderr, "Can't open facedata.xml\n");
		return 0;
	}
	
	nEigens = cvReadIntByName(fileStorage, 0, "nEigens", 0);
	nTrainFaces = cvReadIntByName(fileStorage, 0, "nTrainFaces", 0);
	eigenValMat  = (CvMat*)cvReadByName(fileStorage, 0, "eigenValMat", 0);
	projectedTrainFaceMat = (CvMat *)cvReadByName(fileStorage, 0, "projectedTrainFaceMat", 0);
	pAvgTrainImg = (IplImage*)cvReadByName(fileStorage, 0, "avgTrainImg", 0);
	eigenVectArr = (IplImage**)cvAlloc(nTrainFaces * sizeof(IplImage*));
	for(i=0; i < nEigens; i++) {
		char varname[200];
		sprintf( varname, "eigenVect_%d", i );
		eigenVectArr[i] = (IplImage *)cvReadByName(fileStorage, 0, varname, 0);
	}
	
	eigenNameArr = (char**)malloc(nEigens * sizeof(char*));
	for(i=0; i< nEigens; i++) {
		char varname[200];
		sprintf( varname, "eigenName_%d", i );
		char *eigenName = (char*)cvReadStringByName(fileStorage, 0, varname, 0);
		int eigenNameLen = strlen(eigenName);
		eigenNameArr[i] = malloc(eigenNameLen + 1);
		memcpy(eigenNameArr[i],
			   eigenName,
			   eigenNameLen);
		eigenNameArr[i][eigenNameLen] = '\0';
	}
	
	// release the file-storage interface
	cvReleaseFileStorage( &fileStorage );
	
	return 1;
}

@end
