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
@synthesize faceName = _faceName;

-(id)init {
	if(self = [super init]) {
		nTrainFaces = 0; // the number of training images
		nEigens = 0; // the number of eigenvalues
		pAvgTrainImg = 0; // the average image
		eigenVectArr = 0; // eigenvectors
		eigenValMat = 0; // eigenvalues
		projectedTrainFaceMat = 0; // projected training faces
		trainPersonNumMat = 0;  // the person numbers during training
		faceImgArr = 0; // array of face images
		eigenNameArr = 0;
	}
	return self;
}

-(CvMat*)concatCvMat:(CvMat*)mat1
		   withCvMat:(CvMat*)mat2 {
	NSAssert(mat1->cols == mat2->cols,
			 @"ERROR: concatCvMat requires the 2 CvMats to have the same # of cols");
	NSAssert(mat1->type == mat2->type,
			 @"ERROR: concatCvMat requires the 2 CvMats to have the same type");
	
	CvMat *mat = cvCreateMat(mat1->rows + mat2->rows, mat1->cols, mat1->type);
	
	NSInteger i;
	
	for(i = 0; i < mat1->rows; i++) {
		mat->data.fl[i] = mat1->data.fl[i];
	}
	
	for(NSInteger j = 0; j < mat2->rows; j++) {
		mat->data.fl[i + j] = mat2->data.fl[j];
	}
	
	return mat;
}

-(void)learn:(iOSFTEigenfaceRecognizer*)recognizer {
	int i, offset;
	
	eigenNameArr = (char**)cvAlloc(nTrainFaces*sizeof(char*));
	
	if(recognizer)
		pAvgTrainImg = recognizer.pAvgTrainImg;
	
	NSAssert(nTrainFaces > 1,
			 @"Need at least 2 faces to run the trainer");
	
	// do PCA on the training faces
	[self doPCA];
	
	// project the training images onto the PCA subspace
	projectedTrainFaceMat = cvCreateMat(nTrainFaces, nEigens, CV_32FC1 );
	offset = projectedTrainFaceMat->step / sizeof(float);
	for(i=0; i<nTrainFaces; i++)
	{
		IplImage *image = faceImgArr[i];
		NSLog(@"Decompositing image (%d, %d)", image->width, image->height);
		//int offset = i * nEigens;
		cvEigenDecomposite(
						   image,
						   nEigens,
						   eigenVectArr,
						   0, 0,
						   pAvgTrainImg,
						   //projectedTrainFaceMat->data.fl + i*nEigens);
						   projectedTrainFaceMat->data.fl + i*offset);
		
		eigenNameArr[i] = (char*)[_faceName cStringUsingEncoding:NSUTF8StringEncoding];
	}
	
	if(recognizer) {
		//TODO : Shit leaks like a bitch. . . - JBG
		
		NSLog(@"Blowin' stuff up with the recognizer. . .");
		
		IplImage** concatedEigenVectArr = (IplImage**)cvAlloc(sizeof(IplImage*) * (nEigens + recognizer.nEigens));
		NSInteger i;
		for(i = 0; i < nEigens; i++) {
			concatedEigenVectArr[i] = eigenVectArr[i];
		}
		
		for(NSInteger j = 0; j < recognizer.nEigens; j++) {
			concatedEigenVectArr[i + j] = recognizer.eigenVectArr[j];
		}
		
		eigenVectArr = concatedEigenVectArr;
		
		char** concatedEigenNameArr = (char**)malloc((nEigens + recognizer.nEigens) * sizeof(char*));
		for(i = 0; i < nEigens; i++) {
			concatedEigenNameArr[i] = eigenNameArr[i];
		}
		
		for(NSInteger j = 0; j < recognizer.nEigens; j++) {
			concatedEigenNameArr[i + j] = recognizer.eigenNameArr[j];
		}
		
		eigenNameArr = concatedEigenNameArr;
		
		nTrainFaces += recognizer.nTrainFaces;
		nEigens += recognizer.nEigens;
		
		eigenValMat = [self concatCvMat:recognizer.eigenValMat
							  withCvMat:eigenValMat];
		
		projectedTrainFaceMat = [self concatCvMat:recognizer.projectedTrainFaceMat
										withCvMat:projectedTrainFaceMat];
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

-(void)clearTrainingData {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
	basePath = [basePath stringByAppendingString:@"/facedata.xml"];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	[fileManager removeItemAtPath:basePath error:NULL];
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
	cvWrite(fileStorage, "eigenValMat", eigenValMat, cvAttrList(0,0));
	cvWrite(fileStorage, "projectedTrainFaceMat", projectedTrainFaceMat, cvAttrList(0,0));
	cvWrite(fileStorage, "avgTrainImg", pAvgTrainImg, cvAttrList(0,0));
	for(i=0; i<nEigens; i++) {
		char varname[200];
		sprintf( varname, "eigenVect_%d", i );
		cvWrite(fileStorage, varname, eigenVectArr[i], cvAttrList(0,0));
	}
	
	for(i=0; i<nEigens; i++) {
		char varname[200];
		sprintf( varname, "eigenName_%d", i );
		cvWriteString(fileStorage, varname, eigenNameArr[i], 1);
	}
	
	// release the file-storage interface
	cvReleaseFileStorage( &fileStorage );
}

@end
