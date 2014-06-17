//
//  CVRViewController.m
//  CustomVideoRecording
//
//  Created by xiets on 14-1-18.
//  Copyright (c) 2014年 xietingsong. All rights reserved.
//

#import "CVRViewController.h"
#import "PostViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import <sys/stat.h>

@interface CVRViewController ()

@end

@implementation CVRViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    videoTimeLabel = [[UILabel alloc] init];
    videoTimeLabel.frame = CGRectMake(0, 100, self.view.frame.size.width, 30);
    videoTimeLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:videoTimeLabel];
    
    videoPathLabel = [[UILabel alloc] init];
    videoPathLabel.frame = CGRectMake(0, videoTimeLabel.frame.size.height+videoTimeLabel.frame.origin.y+20, self.view.frame.size.width, 30);
    videoPathLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:videoPathLabel];
    
    videoSizeLabel = [[UILabel alloc] init];
    videoSizeLabel.frame = CGRectMake(0, videoPathLabel.frame.size.height+videoPathLabel.frame.origin.y+20, self.view.frame.size.width, 30);
    videoSizeLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:videoSizeLabel];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn.frame = CGRectMake(0, 0, 150, 40);
    btn.center = self.view.center;
    [btn setTitle:@"Start Recording" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(btnPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    UIButton *playBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    playBtn.frame = CGRectMake(btn.frame.origin.x, btn.frame.origin.y+btn.frame.size.height+20, 150, 40);
    [playBtn setTitle:@"Play Video" forState:UIControlStateNormal];
    [playBtn addTarget:self action:@selector(playMovie) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:playBtn];
    
    [self configureNotification:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [self configureNotification:NO];
}

- (void)configureNotification:(BOOL)toAdd {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationTakePicture object:nil];
    if (toAdd) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callbackNotificationForFilter:) name:kNotificationTakePicture object:nil];
    }
}

- (void)callbackNotificationForFilter:(NSNotification*)noti {
    UIViewController *cameraCon = noti.object;
    if (!cameraCon) {
        return;
    }
    UIImage *finalImage = [noti.userInfo objectForKey:kImage];
    if (!finalImage) {
        return;
    }
    PostViewController *con = [[PostViewController alloc] init];
    con.postImage = finalImage;
    
    if (cameraCon.navigationController) {
        [cameraCon.navigationController pushViewController:con animated:YES];
    } else {
        [cameraCon presentViewController:con animated:YES completion:nil];
    }
}

- (void)btnPressed:(id)sender {
    CVRNavigationController *nav = [[CVRNavigationController alloc] init];
    nav.maxSecond = 8;
    nav.minSecond = 2;
    [nav showCameraWithParentController:self block:^(NSURL *fileUrl, int state, NSString *errorInfo) {
        fileURL = fileUrl;
        videoTimeLabel.text = [NSString stringWithFormat:@"视频时长 : %f",[self getVideoSecond]];
        videoPathLabel.text = [NSString stringWithFormat:@"视频时长 : %@",fileUrl];
        videoSizeLabel.text = [NSString stringWithFormat:@"视频大小 : %fM",(float)[self fileSizeAtPath:[fileURL relativePath]]/1024.0f/1024.0f];
    }];
}

#pragma mark - SCNavigationController delegate
- (void)didTakePicture:(CVRNavigationController *)navigationController image:(UIImage *)image {
    PostViewController *con = [[PostViewController alloc] init];
    con.postImage = image;
    [navigationController pushViewController:con animated:YES];
}

/**
 *  视频时长
 *
 *  @return
 */
- (float)getVideoSecond
{
    NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                                                                forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *fileAsset = [[AVURLAsset alloc] initWithURL:fileURL options:opts];
    float second = 0;
    second = (float)fileAsset.duration.value / (float)fileAsset.duration.timescale; // 获取视频总时长,单位秒
    
    return second;
}

/**
 *获取视频缩略图
 *
 */
-(UIImage *)getVideoThumbnailImage:(NSURL *)pathURL time:(float)time
{
    movie = [[MPMoviePlayerController alloc]
                                   initWithContentURL:pathURL];
    movie.movieSourceType = MPMovieSourceTypeFile;
  //  movie.shouldAutoplay = NO;
    __strong UIImage *image = [movie thumbnailImageAtTime:time
                                 timeOption:MPMovieTimeOptionNearestKeyFrame];
    [movie stop];
    movie = nil;
    return image;
}

/**
 *  获取缩略图
 *
 *  @param videoURL
 *
 *  @return
 */
+(UIImage *)getImage:(NSURL *)videoURL
{
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
    AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    gen.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMakeWithSeconds(0.0, 600);
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *thumb = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);
    return thumb;
    
}

/**
 *  文件大小
 *
 *  @param filePath
 *
 *  @return
 */
- (long long) fileSizeAtPath:(NSString*) filePath{
    struct stat st;
    NSLog(@"file status = %d",lstat([filePath cStringUsingEncoding:NSUTF8StringEncoding], &st));

    if(lstat([filePath cStringUsingEncoding:NSUTF8StringEncoding], &st) == 0){
        return st.st_size;
    }
    return 0;
}

/**
 @method 播放电影
 */
-(void)playMovie{
    
    //视频文件路径
    BOOL isFile = [fileURL isFileURL];
    
    NSURL *url = fileURL ;
    if (!isFile) {
        return;
    }
    //视频播放对象
    movie = [[MPMoviePlayerController alloc] initWithContentURL:url];
    movie.movieSourceType = MPMovieSourceTypeFile;
    movie.controlStyle = MPMovieControlStyleFullscreen;
    [movie.view setFrame:self.view.bounds];
    movie.initialPlaybackTime = -1;
    [self.view addSubview:movie.view];
    
    // 注册一个播放视频的通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(myMovieChangeCallback:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:movie];

    // 注册一个播放结束的通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(myMovieFinishedCallback:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:movie];
    [movie prepareToPlay];
    [movie play];
}

#pragma mark -------------------视频播放结束委托--------------------

- (void)myMovieChangeCallback:(NSNotification *)notification {
    MPMoviePlayerController *theMovie = (MPMoviePlayerController*)[notification object];
    
    // Remove observer
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];
    [theMovie.view removeFromSuperview];
    theMovie = nil;
}

/*
 @method 当视频播放完毕释放对象
 */
-(void)myMovieFinishedCallback:(NSNotification*)notify
{
    
    //视频播放对象
    MPMoviePlayerController* theMovie = [notify object];

    //销毁播放通知
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMoviePlayerPlaybackDidFinishNotification
                                                  object:theMovie];
    [theMovie.view removeFromSuperview];
    // 释放视频对象
    theMovie = nil;
}

@end
