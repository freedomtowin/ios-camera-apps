//
//  OpenCVWrapper.h
//  Graph-Swift
//
//  Created by Rohan Kotwani on 6/25/17.
//  Copyright © 2017 Rohan Kotwani. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <stdio.h>


@interface OpenCVWrapper : NSObject

+ (NSArray *) phaseshiftImageWithOpenCV:(UIImage*)inputImage pastImg:(UIImage*)pastImage rotation_array:(NSMutableArray*)rotation_matrix;

- (UIImage*) squareImageWithOpenCV:(UIImage*)inputImage pastImg:(UIImage*)pastImage y_shift:(double)y_ x_shift:(double)x_ rotation_array:(NSMutableArray*)rotation_matrix;


+ (UIImage*) blackImageWithOpenCV:(UIImage*)inputImage;
    

+ (int) get_image_width:(UIImage*)inputImage;

+ (int) get_image_height:(UIImage*)inputImage;

- (void)max:(int)num1 andNum2:(int)num2;

+ (int*) getRandom;

//struct float3CPP {
//    float x;
//    float y;
//    float z;
//};

//struct float3CPP fcpp(const float **);
//
//extern "C" struct float3CPP fc(const float ** p) {
//    return fcpp(p);
//};

@end
