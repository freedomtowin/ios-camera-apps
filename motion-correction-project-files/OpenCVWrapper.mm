//
//  OpenCVWrapper.m
//  Graph-Swift
//
//  Created by Rohan Kotwani on 6/25/17.
//  Copyright © 2017 Rohan Kotwani. All rights reserved.
//
#include <opencv2/opencv.hpp>
#include "OpenCVWrapper.h"
#import "UIImage+OpenCV.h" // See below to create this


//#import <opencv2/imgcodecs/ios.h>

using namespace cv;
using namespace cv::dnn;
using namespace std;

#include <iterator>
#include <vector>

@implementation OpenCVWrapper{
    }




/* method returning the max between two numbers */
- (void)max:(int)num1 andNum2:(int)num2{
    /* local variable declaration */
    int result;
    
    if (num1 > num2)
    {
        result = num1;
    }
    else
    {
        result = num2;
    }
    
}


+ (int *) getRandom {
    
    static int  r[10];
    int i;
    
    /* set the seed */
    srand( (unsigned)time( NULL ) );
    
    for ( i = 0; i < 10; ++i) {
        r[i] = rand();
        printf( "r[%d] = %d\n", i, r[i]);
    }
    
    return r;
}

//+ UIImage* MatToUIImage(const cv::Mat& image);
//- void UIImageToMat(const UIImage* image,
//                    cv::Mat& m, bool alphaExist = false);


+ (NSArray *) phaseshiftImageWithOpenCV:(UIImage*)inputImage pastImg:(UIImage*)pastImage rotation_array:(NSMutableArray*)rotation_matrix{
    
    Mat mat = [inputImage CVMat];
    Mat past = [pastImage CVMat];
    
    
    
    cv::resize(mat, mat, cv::Size(), 1./3., 1./3.);
    cv::resize(past, past, cv::Size(), 1./3., 1./3.);
    
    Mat crotation_vector(3,1,CV_64F);
    Mat crotation_matrix(3,3,CV_64F);
    // Fill C-array with ints
    int count = 0;
    
    for (int i = 0; i < 3; ++i) {
        for( int j = 0; j < 3; ++j){
            
            crotation_matrix.at<double>(i,j) = [[rotation_matrix objectAtIndex:count] doubleValue];
            count = count + 1;
        }
    }
    
    
    struct X { // struct's as good as class
        
        static void phase_correlate(double  * return_arr, cv::Mat past, cv::Mat mat){
            
            
            past.convertTo(past, CV_64F);
            mat.convertTo(mat, CV_64F);
            
            cv::subtract(mat, mean(mat).val[0], mat);
            cv::subtract(past, mean(past).val[0], past);
            
            
            // rearrange the quadrants of Fourier image  so that the origin is at the image center
            cv::Point2d result = cv::phaseCorrelate(past,mat);
            
//            cout << int(result.x) << " " << int(result.y) << endl;
            
            return_arr[0] = double(result.x);
            return_arr[1] = double(result.y);
            
            if(abs(return_arr[0]) > mat.cols/2) {
                return_arr[0] = 0;
                return_arr[1] = 0;
            }
            
            if(abs(return_arr[1]) > mat.rows/2) {
                return_arr[0] = 0;
                return_arr[1] = 0;
            }
            
        }};
    
    
    cv::cvtColor(mat, mat, cv::COLOR_BGR2GRAY);
    cv::cvtColor(past, past, cv::COLOR_BGR2GRAY);
    
    
    double return_arr[2];
    
    X::phase_correlate(return_arr,past,mat);
    
    NSMutableArray *arr = [NSMutableArray array];
    
    for (int i = 0; i < 2; i++) {
        [arr addObject:[[NSNumber numberWithDouble:return_arr[i]] init]];
    }

    
    return arr;
//    return (shift[1]>=0)*10000000+abs(shift[1])*10000 + (shift[0]>=0)*1000+ abs(shift[0]);
    
}

cv::Mat cvMatMakeRgb(UIImage const* uiImage) {
    cv::Mat cvMat;
//    UIImageToMat(uiImage, cvMat, true);
    cvMat = [uiImage  CVMat];
    if (cvMat.channels() == 4) cvtColor(cvMat, cvMat, CV_BGRA2BGR);
    
    return cvMat;
}

- (UIImage*) squareImageWithOpenCV:(UIImage*)inputImage pastImg:(UIImage*)pastImage y_shift:(double)y_  x_shift:(double)x_ rotation_array:rotation_matrix {
    
    Mat mat = [inputImage CVMat];
    Mat past = [pastImage CVMat];

    x_ = x_*1.0;
    y_ = y_*1.0;

    if(x_ > mat.cols/2) {
        cout << "Error" << endl;
    }
    
    if(y_ > mat.rows/2) {
        cout << "Error" << endl;
    }
    
//    int y_mid = int((mat.cols & -2)/2);
//    int x_mid = int((mat.rows & -2)/2);
    
    float top_left_y = 0.0;
    float top_left_x = 0.0;
    float bottom_right_y = mat.cols;
    float bottom_right_x = mat.rows;
    
    float top_left_y_prime = 0.0;
    float top_left_x_prime = 0.0;
    float bottom_right_y_prime = mat.cols;
    float bottom_right_x_prime = mat.rows;
    
    if( x_ >= 0 ){
        top_left_y = 0+x_;
        bottom_right_y_prime = mat.cols-x_;
    }
    else{
        bottom_right_y = mat.cols+x_;
        top_left_y_prime = 0-x_;
    }
    
    if( y_ >= 0 ){
        top_left_x = 0+y_;
        bottom_right_x_prime =  mat.rows-y_;
    }
    else{
        top_left_x_prime = 0-y_;
        bottom_right_x =  mat.rows+y_;
    }
    
    
    cv::Mat pout = cv::Mat::zeros(mat.size(), mat.type());

    past(cv::Rect(top_left_y_prime,top_left_x_prime, bottom_right_y_prime-top_left_y_prime,bottom_right_x_prime-top_left_x_prime)).copyTo(pout(cv::Rect(top_left_y_prime,top_left_x_prime, bottom_right_y_prime-top_left_y_prime,bottom_right_x_prime-top_left_x_prime)));

    return [UIImage imageWithCVMat:pout];
    
}


+ (UIImage*) blackImageWithOpenCV:(UIImage*)inputImage {
    
    Mat mat = [inputImage CVMat];
    
    cv::rectangle(mat,cv::Point( mat.cols-1, 0),cv::Point( 0, mat.rows-1),Scalar( 0, 0, 0 ),-1,8 );
    
    return [UIImage imageWithCVMat:mat];
}

+ (int) get_image_width:(UIImage*)inputImage {
    
    //create file handle
    
    Mat mat = [inputImage CVMat];

    cout << "Width : " << mat.cols << endl;
    cout << "Height: " << mat.rows << endl;
    
    return mat.cols;
}

+ (int) get_image_height:(UIImage*)inputImage {
    
    //create file handle
    
    Mat mat = [inputImage CVMat];
    
    cout << "Width : " << mat.cols << endl;
    cout << "Height: " << mat.rows << endl;
    
    return mat.rows;
}


@end
