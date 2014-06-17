//
//  CVRSessionManager.m
//  CustomVideoRecording
//
//  Created by xiets on 14-2-16.
//  Copyright (c) 2014年 xietingsong. All rights reserved.
//

#import "CVRSessionManager.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface CVRSessionManager ()

@property (nonatomic, strong) UIView *preview;

@end

@implementation CVRSessionManager


#pragma mark -
#pragma mark configure
- (id)init {
    self = [super init];
    if (self != nil) {
        [self deleteTempVideoFile];
    }
    return self;
}

- (void)dealloc {
    [_session stopRunning];
    fileUrlArray = nil;
    fileUrl = nil;
    self.previewLayer = nil;
    self.session = nil;
}

- (void)configureWithParentLayer:(UIView*)parent previewRect:(CGRect)preivewRect {
    
    self.preview = parent;
    
    //1、队列
    [self createQueue];
    
    //2、session
    [self addSession];
    
    //3、视频预览
    [self addVideoPreviewLayerWithRect:preivewRect];
    [parent.layer addSublayer:_previewLayer];
    
    //4、输入设备
    [self addVideoInputFrontCamera:NO];//视频输入
    [self addVideoAudioInput];//音频输入
    
    //5、输出设备
    [self addVideoAudioOutput];
    
//    //6、default flash mode
//    [self switchFlashMode:nil];
    
//    //7、default focus mode
//    [self setDefaultFocusMode];
}

/**
 *  创建一个队列，防止阻塞主线程
 */
- (void)createQueue {
	dispatch_queue_t sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
    self.sessionQueue = sessionQueue;
}

/**
 *  session
 */
- (void)addSession {
    AVCaptureSession *tmpSession = [[AVCaptureSession alloc] init];
    
    self.session = tmpSession;
    //设置质量
    _session.sessionPreset = AVCaptureSessionPreset640x480;
}

/**
 *  相机的实时预览页面
 *
 *  @param previewRect 预览页面的frame
 */
- (void)addVideoPreviewLayerWithRect:(CGRect)previewRect {
    
    AVCaptureVideoPreviewLayer *preview = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_session];
    preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    preview.frame = previewRect;
    self.previewLayer = preview;
    if(![self.session isRunning]){
        [self.session startRunning];
    }
}

/**
 *  添加饮品输入设备
 *
 */
- (void)addVideoAudioInput
{
    NSError *error = nil;
    
    AVCaptureDevice *audioDevice = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio][0];
    AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
    
    if (error)
    {
        NSLog(@"%@", error);
    }
    
    if ([_session canAddInput:audioDeviceInput])
    {
        [_session addInput:audioDeviceInput];
    }
}

/**
 *  添加输入设备
 *
 *  @param front 前或后摄像头
 */
- (void)addVideoInputFrontCamera:(BOOL)front {
    
    NSArray *devices = [AVCaptureDevice devices];
    AVCaptureDevice *frontCamera;
    AVCaptureDevice *backCamera;
    
    for (AVCaptureDevice *device in devices) {
        
        NSLog(@"Device name: %@", [device localizedName]);
        
        if ([device hasMediaType:AVMediaTypeVideo]) {
            
            if ([device position] == AVCaptureDevicePositionBack) {
                NSLog(@"Device position : back");
                backCamera = device;
                
            }  else {
                NSLog(@"Device position : front");
                frontCamera = device;
            }
        }
    }
    
    NSError *error = nil;
    
    if (front && frontCamera) {

        AVCaptureDeviceInput *frontFacingCameraDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:frontCamera error:&error];
        if (!error) {
            if ([_session canAddInput:frontFacingCameraDeviceInput]) {
                [_session addInput:frontFacingCameraDeviceInput];
                self.inputDevice = frontFacingCameraDeviceInput;
                
            } else {
                NSLog(@"Couldn't add front facing video input");
            }
        }
    } else {
        AVCaptureDeviceInput *backFacingCameraDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:backCamera error:&error];
        if (!error) {
            if ([_session canAddInput:backFacingCameraDeviceInput]) {
                [_session addInput:backFacingCameraDeviceInput];
                self.inputDevice = backFacingCameraDeviceInput;
            } else {
                NSLog(@"Couldn't add back facing video input");
            }
        }
    }
}

/**
 *  添加输出设备
 */
- (void)addVideoAudioOutput {
    
    m_captureMovieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    if ([self.session canAddOutput:m_captureMovieFileOutput])
    [self.session addOutput:m_captureMovieFileOutput];
    
    if (![self recordsVideo]) {
    }
}

-(BOOL)recordsVideo
{
    AVCaptureConnection *videoConnection = [CVRSessionManager connectionWithMediaType:AVMediaTypeVideo fromConnections:m_captureMovieFileOutput.connections];
    
    return [videoConnection isActive];
}

+ (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections
{
    for ( AVCaptureConnection *connection in connections ) {
        for ( AVCaptureInputPort *port in [connection inputPorts] ) {
            if ( [[port mediaType] isEqual:mediaType] ) {
                return connection;
            }
        }
    }
    return nil;
}


/**
 *缓存文件的地址
 *
 */
- (NSURL*)tempFileURL {

    if (fileUrl) {
        return fileUrl;
    }
    int i = 0;
    NSFileManager *fm = [[NSFileManager alloc] init];
    do {
        fileUrl = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@%d.mp4", NSTemporaryDirectory(), TEMP_MOVE_NAME,i++]];

    } while ([fm fileExistsAtPath:[fileUrl path]]);

    return fileUrl;
}

-(void)startRecording
{
    if ([m_captureMovieFileOutput isRecording]) {
        [m_captureMovieFileOutput stopRecording];
    }
    
    AVCaptureConnection *videoConnection = [CVRSessionManager connectionWithMediaType:AVMediaTypeVideo fromConnections:m_captureMovieFileOutput.connections] ;
    // if ([videoConnection isVideoOrientationSupported])
    // 此处保存的视频可以更换宽高AVCaptureVideoOrientationPortrait||AVCaptureVideoOrientationLandscapeRight
    [videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    
    NSURL *outputFileUrl = [self tempFileURL] ;
    // 生成缓存文件
    if (fileUrlArray==nil) {
        fileUrlArray = [[NSMutableArray alloc] init];
        [fileUrlArray addObject:outputFileUrl];
    }
    else
    {
        if ([fileUrlArray containsObject:outputFileUrl]) {
            [fileUrlArray removeObject:outputFileUrl];
            [fileUrlArray addObject:[NSNull null]];
        }
        [fileUrlArray addObject:outputFileUrl];
    }
    
     NSLog(@"start recordeing file url = %@ ",outputFileUrl);
    
    [m_captureMovieFileOutput startRecordingToOutputFileURL:outputFileUrl recordingDelegate:self];
    fileUrl = nil;
    
}

-(void)stopRecording
{
    if (m_captureMovieFileOutput.isRecording) {
        [m_captureMovieFileOutput stopRecording];
        NSLog(@"stop recording");
    }
}

#pragma mark -
#pragma mark AVCaptureFileOutputRecordingDelegate
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections {
    NSLog(@"begin");
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    //存入相册
//    [[[ALAssetsLibrary alloc] init] writeVideoAtPathToSavedPhotosAlbum:outputFileURL completionBlock:^(NSURL *assetURL, NSError *error) {
//		if (error)
//			NSLog(@"%@", error);
//		}];
    NSLog(@"finish");
}

#pragma mark - actions

/**
 *删除最后一段临时文件
 *
 */
- (BOOL)deleteFinalTempVideoFile
{
    NSLog(@"file url last object = %@",[fileUrlArray lastObject]);
    if (fileUrlArray.count) {
        NSURL *tempFileUrl = [fileUrlArray lastObject];
        NSFileManager *fm = [[NSFileManager alloc] init];
        NSError *error = nil;

        NSLog(@"delete file url array = %@,error = %@",fileUrlArray,[error localizedDescription]);

        if (![tempFileUrl isEqual:[NSNull null]] && [fm fileExistsAtPath:[tempFileUrl path]]) {
            BOOL isDeleteOk = [fm removeItemAtURL:tempFileUrl error:&error];
            if (isDeleteOk) {
                [fileUrlArray removeLastObject];
            }

            return isDeleteOk;
        }
        else
        {
            [fileUrlArray removeLastObject];
        }
    }
    
    NSLog(@"there is no file");
    return NO;
}

/**
 *删除所有视频临时文件
 *
 */
- (void)deleteTempVideoFile
{
    NSFileManager *fm = [[NSFileManager alloc] init];
    
    NSURL *tempFileUrl;
    
    NSArray *tempFileArray = [fm contentsOfDirectoryAtPath:NSTemporaryDirectory() error:nil];
    for (NSString *strTempFile in tempFileArray) {
        NSRange rang = [strTempFile rangeOfString:TEMP_MOVE_NAME options:NSCaseInsensitiveSearch];
        
        if (rang.length>0) {
            tempFileUrl = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(),strTempFile]];
            BOOL isDeleteOk = [fm removeItemAtURL:tempFileUrl error:nil];
            NSLog(@"删除缓存 %d",isDeleteOk);
        }
    }
}

/**
 *  录制视频
 */
- (void)takePicture:(DidCaptureVideoBlock)block {
    NSLog(@"start export");
    // 1 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    // 2 - Video track
    AVMutableCompositionTrack *firstTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];

    BOOL isFirst = YES;
    AVURLAsset *firstAsset = [[AVURLAsset alloc] init];
    
    NSFileManager *fm = [[NSFileManager alloc] init];
    
    NSMutableArray *timeArray = [[NSMutableArray alloc] init];
    NSMutableArray *trackArray = [[NSMutableArray alloc] init];
    NSMutableArray *audioArray = [[NSMutableArray alloc] init];
    
    NSMutableArray *fileTrackArray = [[NSMutableArray alloc] init];
    for (NSURL *fileURL in fileUrlArray)
    {
        if (![fileURL isEqual:[NSNull null]] && [fm fileExistsAtPath:[fileURL path]] && [[NSData dataWithContentsOfURL:fileURL] length])
        {

            AVURLAsset *fileAsset = [[AVURLAsset alloc] initWithURL:fileURL options:nil];
            [fileTrackArray addObject:fileAsset];
            NSLog(@"export fileUrl = %@,",fileURL);

        }
    }
    for (AVURLAsset *fileAsset in fileTrackArray)
    {
        NSArray *track = [fileAsset tracksWithMediaType:AVMediaTypeVideo];
        NSArray *audioTrackArray = [fileAsset tracksWithMediaType:AVMediaTypeAudio];
        
        if (track.count && audioTrackArray.count)
        {
            if ([track objectAtIndex:0] && [audioTrackArray objectAtIndex:0])
            {
                if (isFirst) {
                    [firstTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, fileAsset.duration)
                                        ofTrack:[[fileAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:nil];
                    [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, fileAsset.duration)
                                        ofTrack:[[fileAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil];
                    isFirst = NO;
                    firstAsset = fileAsset;
                }
                else
                {
                    [timeArray addObject:[NSValue valueWithCMTimeRange:(CMTimeRange){kCMTimeZero,fileAsset.duration}]];
                    [trackArray addObject:track[0]];
                    [audioArray addObject:audioTrackArray[0]];
                }
                
            }
        }
    }
    NSLog(@"%@",timeArray);
    if (trackArray.count) {
        [firstTrack insertTimeRanges:timeArray ofTracks:trackArray atTime:firstAsset.duration error:nil];
    }
    if (audioArray.count) {
        [audioTrack insertTimeRanges:timeArray ofTracks:audioArray atTime:firstAsset.duration error:nil];
    }

    // 3 - Audio track
//    if (audioAsset!=nil){
//        AVMutableCompositionTrack *AudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
//                                                                            preferredTrackID:kCMPersistentTrackID_Invalid];
//        [AudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeAdd(firstAsset.duration, secondAsset.duration))
//                            ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil];
//    }
    // 4 - Get path
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *myPathDocs =  [documentsDirectory stringByAppendingPathComponent:
                             [NSString stringWithFormat:@"mergeVideo-%d.mp4",arc4random() % 10000000]];
    NSURL *url = [NSURL fileURLWithPath:myPathDocs];
    
    // 5 - Create exporter
    AVMutableVideoComposition *avMutableVideoComposition = [AVMutableVideoComposition videoComposition];
    avMutableVideoComposition.frameDuration = CMTimeMake(1,30);
    avMutableVideoComposition.renderSize = CGSizeMake(480.0f, 480.0f);
    
    AVMutableVideoCompositionInstruction *avMutableVideoCompositionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    [avMutableVideoCompositionInstruction setTimeRange:CMTimeRangeMake(kCMTimeZero, kCMTimeIndefinite)];
    AVMutableVideoCompositionLayerInstruction *avMutableVideoCompositionLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:firstTrack];
    
    CGAffineTransform rotationTransform1 = CGAffineTransformMakeRotation(M_PI_2);
    float assetScaleToFitRatio = 480 / firstTrack.naturalSize.height;
    CGAffineTransform assetScaleFactor = CGAffineTransformMakeScale(assetScaleToFitRatio,assetScaleToFitRatio);
    CGAffineTransform rotationTransform = CGAffineTransformConcat(CGAffineTransformConcat(rotationTransform1, assetScaleFactor),CGAffineTransformMakeTranslation(480, -52));
 
    [avMutableVideoCompositionLayerInstruction setTransform:rotationTransform atTime:kCMTimeZero];
    avMutableVideoCompositionInstruction.layerInstructions = [NSArray arrayWithObject:avMutableVideoCompositionLayerInstruction];
    avMutableVideoComposition.instructions = [NSArray arrayWithObject:avMutableVideoCompositionInstruction];
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                                      presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL=url;
    exporter.videoComposition = avMutableVideoComposition;
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.shouldOptimizeForNetworkUse = YES;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (exporter.status) {
                case AVAssetExportSessionStatusUnknown:
                    block(url,exporter.status,[[exporter error] localizedDescription]);
                    break;
                case AVAssetExportSessionStatusWaiting:
                    block(url,exporter.status,[[exporter error] localizedDescription]);
                    break;
                case AVAssetExportSessionStatusExporting:
                    block(url,exporter.status,[[exporter error] localizedDescription]);
                    break;
                case AVAssetExportSessionStatusFailed:
                    block(url,exporter.status,[[exporter error] localizedDescription]);
                break;
                case AVAssetExportSessionStatusCompleted:
                    block(url,exporter.status,@"exporting completed");
                break;
                    case AVAssetExportSessionStatusCancelled:
                    block(url,exporter.status,@"exporting cancelled");
                break;
            }
        });
    }];
}


/**
 *  切换前后摄像头
 *
 *  @param isFrontCamera YES:前摄像头  NO:后摄像头
 */
- (void)switchCamera:(BOOL)isFrontCamera {
    if (!_inputDevice) {
        return;
    }
    [_session beginConfiguration];
    
    [_session removeInput:_inputDevice];
    
    [self addVideoInputFrontCamera:isFrontCamera];
    
    [_session commitConfiguration];
}

/**
 *  切换闪光灯模式
 *  （切换顺序：最开始是auto，然后是off，最后是on，一直循环）
 *  @param sender: 闪光灯按钮
 */
- (void)switchFlashMode:(UIButton*)sender {
  
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (!captureDeviceClass) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示信息" message:@"您的设备没有拍照功能" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
        [alert show];
        return;
    }
    
    NSString *imgStr = @"";
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [device lockForConfiguration:nil];
    if ([device hasFlash])
    {
        if (device.flashMode == AVCaptureFlashModeOff)
        {
            device.flashMode = AVCaptureFlashModeOn;
            [device setTorchMode:AVCaptureTorchModeOn];

            imgStr = @"闪光.png";
            
        } else if (device.flashMode == AVCaptureFlashModeOn)
        {
            device.flashMode = AVCaptureFlashModeOff;
            [device setTorchMode:AVCaptureTorchModeOff];

            imgStr = @"闪光-默认.png";
            
        } else if (device.flashMode == AVCaptureFlashModeAuto) {
            device.flashMode = AVCaptureFlashModeOn;
            [device setTorchMode:AVCaptureTorchModeOn];

            imgStr = @"闪光.png";
        }
        
        if (sender) {
            [sender setImage:[UIImage imageNamed:imgStr] forState:UIControlStateNormal];
        }
        
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示信息" message:@"您的设备没有闪光灯功能" delegate:nil cancelButtonTitle:@"噢T_T" otherButtonTitles: nil];
        [alert show];
    }
    [device unlockForConfiguration];
}

@end
