//
//  CVRCameraController.h
//  CustomVideoRecording
//
//  Created by xiets on 14-2-16.
//  Copyright (c) 2014年 xietingsong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CVRSessionManager.h"
#import "CVRUtilsPalette.h"
#import "CVRNavigationController.h"

@interface CVRCameraController : UIViewController
{
    float               drawTime;//录制总时间
    NSTimer             *timer;//时间计时器
    CALayer             *layer;//闪烁的光标
    
    UIButton            *sureBtn;//确认按钮
    UIButton            *deleteBtn;//回删按钮
    UILabel             *deleteLabel;//回删title
    CGPoint             MyMovepoint;
    UIImageView         *recordImageView;//摄像按钮图像
    
    CVRUtilsPalette      *timeView;
    BOOL                isCanTouch;//是否禁用touch事件
    GetVideoBlock       block;//获取视频信息的block

}

@property (nonatomic, assign) CGRect previewRect;
@property (nonatomic, assign) BOOL isStatusBarHiddenBeforeShowCamera;
@property (nonatomic, assign) int maxSecond;//设置录制的最大秒数，默认8秒
@property (nonatomic, assign) int minSecond;//设置录制的最小秒数，默认2秒
- (id)initWithBlock:(GetVideoBlock)getblock;

@end
