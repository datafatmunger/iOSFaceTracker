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
-(NSInteger)loadTrainingData:(CvMat**)pTrainPersonNumMat;

@end


@implementation iOSFTEigenfaceRecognizer

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
		
		// load the saved training data
		NSAssert([self loadTrainingData:&trainPersonNumMat],
				 @"Training data load FAIL.");
	}
	return self;
}

-(void)recognize:(IplImage*)face {

	float *projectedTestFace = 0;
	
	// project the test images onto the PCA subspace
	projectedTestFace = (float *)cvAlloc( nEigens*sizeof(float) );

	int iNearest, nearest, truth;
	
	// project the test image onto the PCA subspace
	cvEigenDecomposite(face,
					   nEigens,
					   eigenVectArr,
					   0, 0,
					   pAvgTrainImg,
					   projectedTestFace);
	
	iNearest = [self findNearestNeighbor:projectedTestFace];
	truth    = personNumTruthMat->data.i[0];
	nearest  = trainPersonNumMat->data.i[iNearest];
	
	printf("nearest = %d, Truth = %d\n", nearest, truth);

}

#pragma mark -
#pragma mark iOSFTEigenfaceRecognizer (Private)

-(NSInteger)findNearestNeighbor:(float*)projectedTestFace {
	//double leastDistSq = 1e12;
	double leastDistSq = DBL_MAX;
	int i, iTrain, iNearest = 0;
	
	for(iTrain=0; iTrain<nTrainFaces; iTrain++)
	{
		double distSq=0;
		
		for(i=0; i<nEigens; i++)
		{
			float d_i =
			projectedTestFace[i] -
			projectedTrainFaceMat->data.fl[iTrain*nEigens + i];
			//distSq += d_i*d_i / eigenValMat->data.fl[i];  // Mahalanobis
			distSq += d_i*d_i; // Euclidean
		}
		
		if(distSq < leastDistSq)
		{
			leastDistSq = distSq;
			iNearest = iTrain;
		}
	}
	
	return iNearest;
}

-(NSInteger)loadTrainingData:(CvMat**)pTrainPersonNumMat {
	CvFileStorage * fileStorage;
	int i;
	
	// create a file-storage interface
	fileStorage = cvOpenFileStorage( "facedata.xml", 0, CV_STORAGE_READ );
	if( !fileStorage )
	{
		fprintf(stderr, "Can't open facedata.xml\n");
		return 0;
	}
	
	nEigens = cvReadIntByName(fileStorage, 0, "nEigens", 0);
	nTrainFaces = cvReadIntByName(fileStorage, 0, "nTrainFaces", 0);
	*pTrainPersonNumMat = (CvMat *)cvReadByName(fileStorage, 0, "trainPersonNumMat", 0);
	eigenValMat  = (CvMat *)cvReadByName(fileStorage, 0, "eigenValMat", 0);
	projectedTrainFaceMat = (CvMat *)cvReadByName(fileStorage, 0, "projectedTrainFaceMat", 0);
	pAvgTrainImg = (IplImage *)cvReadByName(fileStorage, 0, "avgTrainImg", 0);
	eigenVectArr = (IplImage **)cvAlloc(nTrainFaces*sizeof(IplImage *));
	for(i=0; i<nEigens; i++)
	{
		char varname[200];
		sprintf( varname, "eigenVect_%d", i );
		eigenVectArr[i] = (IplImage *)cvReadByName(fileStorage, 0, varname, 0);
	}
	
	// release the file-storage interface
	cvReleaseFileStorage( &fileStorage );
	
	return 1;
}

@end
