//
//  CVRNavigationController.h
//  CustomVideoRecording
//
//  Created by xiets on 14-2-17.
//  Copyright (c) 2014年 xietingsong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CVRDefines.h"

typedef void(^GetVideoBlock)(NSURL *fileUrl,int state,NSString *errorInfo);

@protocol CVRNavigationControllerDelegate;

@interface CVRNavigationController : UINavigationController


- (void)showCameraWithParentController:(UIViewController*)parentController block:(GetVideoBlock)block;

@property (nonatomic, assign) id <CVRNavigationControllerDelegate> scNaigationDelegate;
@property (nonatomic, assign) int maxSecond;//设置录制的最大秒数，默认8秒
@property (nonatomic, assign) int minSecond;//设置录制的最小秒数，默认2秒
@property (nonatomic, copy) GetVideoBlock getBlock;

@end

@protocol CVRNavigationControllerDelegate <NSObject>
@optional
- (BOOL)willDismissNavigationController:(CVRNavigationController*)navigatonController;

- (void)didTakePicture:(CVRNavigationController*)navigationController image:(UIImage*)image;

@end