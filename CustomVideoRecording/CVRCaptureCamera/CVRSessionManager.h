//
//  CVRSessionManager.h
//  CustomVideoRecording
//
//  Created by xiets on 14-2-16.
//  Copyright (c) 2014年 xietingsong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "CVRDefines.h"

#define MAX_PINCH_SCALE_NUM   3.f
#define MIN_PINCH_SCALE_NUM   1.f

#define TEMP_MOVE_NAME @"temp_Video"

#undef PRODUCER_HAS_VIDEO_CAPTURE
#define PRODUCER_HAS_VIDEO_CAPTURE (__IPHONE_OS_VERSION_MIN_REQUIRED >= 40000 && TARGET_OS_EMBEDDED)

typedef void(^DidCaptureVideoBlock)(NSURL *fileUrl,int state,NSString *errorInfo);

@interface CVRSessionManager : NSObject<AVCaptureFileOutputRecordingDelegate ,AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>
{
    NSURL                       *fileUrl;
    NSMutableArray              *fileUrlArray;//保存缓存的file url
    AVCaptureSession            *m_captureSession;
    AVCaptureDevice             *m_captureDevice;
    AVCaptureMovieFileOutput    *m_captureMovieFileOutput ;
}

@property (nonatomic ,assign) BOOL isRecording;
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) AVCaptureDeviceInput *inputDevice;

- (BOOL)deleteFinalTempVideoFile;
- (void)deleteTempVideoFile;
- (void)configureWithParentLayer:(UIView*)parent previewRect:(CGRect)preivewRect;
- (void)startRecording;
- (void)stopRecording;
- (void)takePicture:(DidCaptureVideoBlock)block;
- (void)switchCamera:(BOOL)isFrontCamera;
- (void)switchFlashMode:(UIButton*)sender;

@end
