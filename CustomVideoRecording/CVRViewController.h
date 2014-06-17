//
//  CVRViewController.h
//  CustomVideoRecording
//
//  Created by xiets on 14-1-18.
//  Copyright (c) 2014年 xietingsong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CVRNavigationController.h"
#import <MediaPlayer/MediaPlayer.h>

@interface CVRViewController : UIViewController <CVRNavigationControllerDelegate>
{
    NSURL                   *fileURL;
    MPMoviePlayerController *movie;
    UILabel                 *videoTimeLabel;
    UILabel                 *videoPathLabel;
    UILabel                 *videoSizeLabel;

}
@end
