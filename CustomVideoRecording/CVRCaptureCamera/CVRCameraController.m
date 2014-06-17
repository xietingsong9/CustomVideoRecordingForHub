//
//  CVRCameraController.m
//  CustomVideoRecording
//
//  Created by xiets on 14-2-16.
//  Copyright (c) 2014年 xietingsong. All rights reserved.
//

#import "CVRCameraController.h"
#import "CVRUtilsAttributedLabel.h"
#import "CVRNavigationController.h"
#import <AssetsLibrary/AssetsLibrary.h>

//height
#define CAMERA_TOPVIEW_HEIGHT   44  //title
#define CAMERA_MENU_VIEW_HEIGH  44  //menu

//color
#define bottomContainerView_UP_COLOR     [UIColor colorWithRed:51/255.0f green:51/255.0f blue:51/255.0f alpha:1.f]       //bottomContainerView的上半部分
#define bottomContainerView_DOWN_COLOR   [UIColor colorWithRed:68/255.0f green:68/255.0f blue:68/255.0f alpha:1.f]       //bottomContainerView的下半部分
#define DARK_GREEN_COLOR        [UIColor colorWithRed:10/255.0f green:107/255.0f blue:42/255.0f alpha:1.f]    //深绿色
#define LIGHT_GREEN_COLOR       [UIColor colorWithRed:143/255.0f green:191/255.0f blue:62/255.0f alpha:1.f]    //浅绿色
#define TEXT_COLOR       [UIColor colorWithRed:30/255.0f green:185/255.0f blue:204/255.0f alpha:1.f]

@interface CVRCameraController () {
}

@property (nonatomic, strong) CVRSessionManager *captureManager;
@property (nonatomic, strong) UIView *topContainerView;//顶部view
@property (nonatomic, strong) UILabel *topLbl;//顶部的标题
@property (nonatomic, strong) UIView *bottomContainerView;//除了顶部标题、拍照区域剩下的所有区域

@end

@implementation CVRCameraController

#pragma mark -------------life cycle---------------
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        if (self.maxSecond<=0) {
            self.maxSecond = 8;
        }
        if (self.minSecond<=0) {
            self.minSecond = 2;
        }
    }
    return self;
}

- (id)initWithBlock:(GetVideoBlock)getblock
{
    self = [super init];
    if (self) {
        if (self.maxSecond<=0) {
            self.maxSecond = 8;
        }
        if (self.minSecond<=0) {
            self.minSecond = 2;
        }
        block = getblock;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    
    if (!self.navigationController) {
        if ([UIApplication sharedApplication].statusBarHidden != _isStatusBarHiddenBeforeShowCamera) {
            [[UIApplication sharedApplication] setStatusBarHidden:_isStatusBarHiddenBeforeShowCamera withAnimation:UIStatusBarAnimationSlide];
        }
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationOrientationChange object:nil];
    
    timeView = nil;
    timer  = nil;
    layer = nil;
    drawTime = 0;
    MyMovepoint = CGPointMake(0, 4);
    
    _captureManager = nil;
    _topContainerView = nil;
    _bottomContainerView = nil;
    deleteLabel = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    //navigation bar
    if (self.navigationController && !self.navigationController.navigationBarHidden) {
        self.navigationController.navigationBarHidden = YES;
    }
    
    //status bar
    if (!self.navigationController) {
        _isStatusBarHiddenBeforeShowCamera = [UIApplication sharedApplication].statusBarHidden;
        if ([UIApplication sharedApplication].statusBarHidden == NO) {
            //iOS7，需要plist里设置 View controller-based status bar appearance 为NO
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
        }
    }
    
    
    [self addTopView];//顶部菜单栏
    [self addbottomContainerView];//底部功能栏
    [self addCameraMenuView];//拍照菜单栏
    
    //设置session manager
    CVRSessionManager *manager = [[CVRSessionManager alloc] init];
    
    //设置录制的区域
    if (CGRectEqualToRect(_previewRect, CGRectZero)) {
        self.previewRect = CGRectMake(0, _topContainerView.frame.size.height+8, SN_APP_SIZE.width, SN_APP_SIZE.width);
        NSLog(@"x = %f , y = %f, w = %f, h = %f",self.previewRect.origin.x,self.previewRect.origin.y,self.previewRect.size.width,self.previewRect.size.height);
    }
    [manager configureWithParentLayer:self.view previewRect:_previewRect];
    
    self.captureManager = manager;
    
    [_captureManager.session startRunning];
    
    //录制时间的提示
    [self addAlertView];
    
    //设置光标
    if (layer==nil) {
        [self initLayer:(CGPoint){0,4}];
    }
}

/**
 *设置闪烁光标
 *
 *@pragma point：光标的位置
 */
- (void)initLayer:(CGPoint)point
{
    layer = [CALayer layer];
    layer.contents = (id)[self createImageWithColor:[UIColor greenColor]].CGImage;
	layer.bounds = CGRectMake(0, 0, 4, 8);
	layer.position = CGPointMake(point.x, point.y);
	[timeView.layer addSublayer:layer];
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
	animation.toValue = [NSNumber numberWithFloat:0.0];
	animation.fromValue = [NSNumber numberWithFloat:layer.opacity];
	animation.duration = 1.0;
    // animation.repeatDuration = 1.0f;
    animation.repeatCount = HUGE_VALF;
	layer.opacity = 0.0; // This is required to update the model's value.  Comment out to see what happens.
	[layer addAnimation:animation forKey:@"animateOpacity"];
}

/**
 *创建录制条的底色
 *
 *
 */
- (UIImage *) createImageWithColor: (UIColor *) color
{
    CGRect rect = CGRectMake(0.0f,0.0f,1.0f,1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context =UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *theImage =UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return theImage;
}

#pragma mark -------------UI---------------
/**
 *顶部标题
 *
 */
- (void)addTopView
{
    if (!_topContainerView) {
        CGRect topFrame = CGRectMake(0, 0, SN_APP_SIZE.width, CAMERA_TOPVIEW_HEIGHT);
        
        UIView *tView = [[UIView alloc] initWithFrame:topFrame];
        tView.backgroundColor = [UIColor blackColor];
        
        [self.view addSubview:tView];
        self.topContainerView = tView;
        
        //取消按钮
        UIButton * cancelBtn = [self buildButton:CGRectMake(5, 8, 50, 29)
                              normalImgStr:@"取消.png"
                           highlightImgStr:nil
                            selectedImgStr:nil
                                    action:@selector(dismissBtnPressed:)
                                parentView:self.topContainerView];

        
        //使用按钮
        sureBtn = [self buildButton:CGRectMake(SN_APP_SIZE.width-55, 8, 50, 29)
                                    normalImgStr:@"使用1.png"
                                 highlightImgStr:nil
                                  selectedImgStr:@"使用2.png"
                                          action:@selector(takePictureBtnPressed:)
                                      parentView:self.topContainerView];
        
        UILabel *switchCameraLabel = [[UILabel alloc] initWithFrame:CGRectMake(SN_APP_SIZE.width/2-18, CAMERA_TOPVIEW_HEIGHT/2-13, 36, 25)];
        switchCameraLabel.text = @"拍摄";
        switchCameraLabel.textAlignment = NSTextAlignmentCenter;
        switchCameraLabel.textColor = [UIColor whiteColor];
        switchCameraLabel.font = [UIFont boldSystemFontOfSize:18.0f];
        switchCameraLabel.backgroundColor = [UIColor clearColor];
        [self.topContainerView addSubview:switchCameraLabel];
        
        timeView = [[CVRUtilsPalette alloc] initWithFrame:(CGRect){_topContainerView.frame.origin.x,CAMERA_TOPVIEW_HEIGHT,SN_APP_FRAME.size.width,8}];
        timeView.backgroundColor = [UIColor blackColor];
        timeView.maxSecond = self.maxSecond;
        timeView.minSecond = self.minSecond;
        
        [self.view addSubview:timeView];
    }
}

//bottomContainerView，总体
- (void)addbottomContainerView {
    
    CGRect bottomFrame = CGRectMake(0, SN_APP_SIZE.height-109, SN_APP_SIZE.width, 109);//SC_APP_SIZE.height - bottomY);
    
    UIView *view = [[UIView alloc] initWithFrame:bottomFrame];
    
    view.backgroundColor = [UIColor blackColor];//bottomContainerView_UP_COLOR;
    [self.view addSubview:view];
    self.bottomContainerView = view;
}

//拍照菜单栏
- (void)addCameraMenuView {
    
    //屏幕的提示文字
    CVRUtilsAttributedLabel *lbl = [[CVRUtilsAttributedLabel alloc] initWithFrame:CGRectMake(0, 10, SN_APP_SIZE.width, 30)];
    lbl.text = @"按住屏幕任何位置拍摄,松手暂停!";
    
    [lbl setColor:TEXT_COLOR fromIndex:0 length:2];
    [lbl setFont:[UIFont boldSystemFontOfSize:20] fromIndex:0 length:2];

    [lbl setColor:[UIColor grayColor] fromIndex:2 length:9];
    [lbl setFont:[UIFont systemFontOfSize:18] fromIndex:2 length:9];
    
    [lbl setColor:TEXT_COLOR fromIndex:11 length:2];
    [lbl setFont:[UIFont boldSystemFontOfSize:20] fromIndex:11 length:2];

    [lbl setColor:[UIColor grayColor] fromIndex:13 length:3];
    [lbl setFont:[UIFont systemFontOfSize:18] fromIndex:13 length:3];
    
    lbl.backgroundColor = [UIColor clearColor];
    [_bottomContainerView addSubview:lbl];

    //反拍按钮
    UIButton * switchCameraBtn =[self buildButton:((CGRect){SN_APP_SIZE.width/2-20,lbl.frame.origin.y+lbl.frame.size.height+10,39,27}) normalImgStr:@"反拍-大.png" highlightImgStr:nil selectedImgStr:nil action:@selector(switchCameraBtnPressed:) parentView:_bottomContainerView];
    
    UILabel *switchCameraLabel = [[UILabel alloc] initWithFrame:(CGRect){switchCameraBtn.frame.origin.x-10,switchCameraBtn.frame.origin.y+switchCameraBtn.frame.size.height+3,switchCameraBtn.frame.size.width+20,switchCameraBtn.frame.size.height}];
    switchCameraLabel.text = @"自拍";
    switchCameraLabel.textAlignment = NSTextAlignmentCenter;
    switchCameraLabel.textColor = [UIColor whiteColor];
    switchCameraLabel.font = [UIFont boldSystemFontOfSize:14.0f];
    switchCameraLabel.backgroundColor = [UIColor clearColor];
    [_bottomContainerView addSubview:switchCameraLabel];
    
    //闪光灯功能
    UIButton * flashBtn =[self buildButton:((CGRect){50,lbl.frame.origin.y+lbl.frame.size.height+10,27,27}) normalImgStr:@"闪光-默认.png" highlightImgStr:@"闪光.png" selectedImgStr:nil action:@selector(flashBtnPressed:) parentView:_bottomContainerView];
    
    UILabel *flashLabel = [[UILabel alloc] initWithFrame:(CGRect){flashBtn.frame.origin.x-10,flashBtn.frame.origin.y+flashBtn.frame.size.height+3,flashBtn.frame.size.width+20,flashBtn.frame.size.height}];
    flashLabel.text = @"闪光";
    flashLabel.textAlignment = NSTextAlignmentCenter;
    flashLabel.textColor = [UIColor whiteColor];
    flashLabel.font = [UIFont boldSystemFontOfSize:14.0f];
    flashLabel.backgroundColor = [UIColor clearColor];
    
    [_bottomContainerView addSubview:flashLabel];
    
    //回删视频功能
    deleteBtn = [self buildButton:((CGRect){SN_APP_SIZE.width-50-45,lbl.frame.origin.y+lbl.frame.size.height+10,45,27}) normalImgStr:@"删除-默认.png" highlightImgStr:nil selectedImgStr:@"删除.png" action:@selector(LineFinallyRemove:) parentView:_bottomContainerView];
    deleteBtn.enabled = NO;
    deleteLabel.alpha = 0.7;
    
    deleteLabel = [[UILabel alloc] initWithFrame:(CGRect){deleteBtn.frame.origin.x+15,deleteBtn.frame.origin.y+deleteBtn.frame.size.height+3,deleteBtn.frame.size.width,deleteBtn.frame.size.height}];
    deleteLabel.text = @"删除";
    deleteLabel.textAlignment = NSTextAlignmentLeft;
    deleteLabel.textColor = [UIColor whiteColor];
    deleteLabel.font = [UIFont boldSystemFontOfSize:14.0f];
    deleteLabel.backgroundColor = [UIColor clearColor];
    deleteLabel.alpha = 0.7;
    
    [_bottomContainerView addSubview:deleteLabel];
}

/**
 *关于录制时间的提示
 *
 */
- (void)addAlertView
{
    /*******布局后空出来的view********/
    UIView *otherBjView = [[UIView alloc] initWithFrame:(CGRect){0,self.previewRect.origin.y+self.previewRect.size.height,SN_APP_SIZE.width,_bottomContainerView.frame.origin.y-self.previewRect.origin.y-self.previewRect.size.height}];
    otherBjView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:otherBjView];
    otherBjView = nil;
    /***************/
    
    UIView *bjView = [[UIView alloc] init];
    bjView.frame = (CGRect){SN_APP_SIZE.width*self.minSecond/self.maxSecond-76/2,timeView.frame.origin.y+timeView.frame.size.height,76,27};
    bjView.backgroundColor = [UIColor clearColor];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:(CGRect){0,0,76,27}];
    imageView.image = [UIImage imageNamed:@"提示.png"];
    [bjView addSubview:imageView];
    imageView = nil;
    
    UILabel *alertLabel = [[UILabel alloc] initWithFrame:(CGRect){0,2,76,25}];
    alertLabel.text = [NSString stringWithFormat:@"至少录%d秒",self.minSecond];
    alertLabel.textAlignment = NSTextAlignmentCenter;
    alertLabel.backgroundColor = [UIColor clearColor];
    alertLabel.font = [UIFont systemFontOfSize:13.0f];
    [bjView addSubview:alertLabel];
    alertLabel = nil;

    [self.view addSubview:bjView];
    
    [UIView animateWithDuration:2.15
                          delay:1
                        options:UIViewAnimationCurveEaseIn | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         bjView.alpha = 0;
                     }
                     completion:^(BOOL finished){
                         [bjView removeFromSuperview];
                     }];
}

/**
 *回删功能实现
 *
 *
 */
-(void)LineFinallyRemove:(id)sender
{
    UIButton *delBtn  = (UIButton*)sender;
    [timeView myLineFinallyRemove:!delBtn.selected];
    
    if (delBtn.selected) {
        delBtn.selected = NO;
      //  ....删除单个文件时的bug。。。。url的问题
        BOOL isDeleteSuccess = [_captureManager deleteFinalTempVideoFile];
        NSLog(@" is delete success = %d",isDeleteSuccess);

       MyMovepoint = [timeView lastPoint];
        if (MyMovepoint.x<=0) {
            MyMovepoint = CGPointMake(0, 4);
        }
        [self initLayer:(CGPoint){MyMovepoint.x+2,MyMovepoint.y}];
        drawTime = (float)MyMovepoint.x/SN_APP_SIZE.width*self.maxSecond;
        if (drawTime<self.minSecond)
        {
            sureBtn.selected = NO;
        }
        if (layer.position.x<=2)
        {
            deleteBtn.enabled = NO;
            deleteLabel.alpha = 0.7f;
        }
    }
    else
    {
        [layer removeFromSuperlayer];
        layer = nil;
        delBtn.selected = YES;
    }
}

- (UIButton*)buildButton:(CGRect)frame
            normalImgStr:(NSString*)normalImgStr
         highlightImgStr:(NSString*)highlightImgStr
          selectedImgStr:(NSString*)selectedImgStr
                  action:(SEL)action
              parentView:(UIView*)parentView {
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = frame;
    if (normalImgStr.length > 0) {
        [btn setImage:[UIImage imageNamed:normalImgStr] forState:UIControlStateNormal];
    }
    if (highlightImgStr.length > 0) {
        [btn setImage:[UIImage imageNamed:highlightImgStr] forState:UIControlStateHighlighted];
    }
    if (selectedImgStr.length > 0) {
        [btn setImage:[UIImage imageNamed:selectedImgStr] forState:UIControlStateSelected];
    }
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [parentView addSubview:btn];
    
    return btn;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if (isCanTouch) {
        return;
    }
    
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view];

    if (point.y<(timeView.frame.origin.y+timeView.frame.size.height) || point.y > (_bottomContainerView.frame.origin.y)) {
        return;
    }

    if (deleteBtn.selected) {
        return;
    }
    
    if (MyMovepoint.x<=0) {
        MyMovepoint = CGPointMake(0, 4);
    }
    
    if (drawTime>=self.maxSecond) {
        //To 使用可点
        return;
    }
    
    timer = [NSTimer scheduledTimerWithTimeInterval:0.05f target:self selector:@selector(drawLine) userInfo:nil
                                            repeats:YES];
    
	[(CVRUtilsPalette*)timeView Introductionpoint1];
	[(CVRUtilsPalette*)timeView Introductionpoint3:MyMovepoint];
    
    [_captureManager startRecording];
    
    //NSLog(@"=================start touch=====================");

}

- (void)drawLine
{
   // NSLog(@"time = %f",drawTime);
    if (drawTime>=self.maxSecond) {
        [timer invalidate];
        timer = nil;
        [_captureManager stopRecording];
        
        CGPoint MyEndPoint = CGPointMake(MyMovepoint.x-1,MyMovepoint.y);
        
        [timeView Introductionpoint6:MyEndPoint];
        [timeView Introductionpoint6:MyMovepoint];
        [timeView Introductionpoint2];
        [timeView setNeedsDisplay];
        
        return;
    }
    if (drawTime>=self.minSecond) {
        sureBtn.selected = YES;
    }
    deleteBtn.enabled = NO;
    deleteLabel.alpha = 0.7f;
    
    drawTime+=0.05f;
    
  //  NSLog(@"my movepoint x= %f,y = %f",MyMovepoint.x,MyMovepoint.y);
    MyMovepoint = CGPointMake(MyMovepoint.x+2,MyMovepoint.y);
    layer.position = CGPointMake(MyMovepoint.x+6, MyMovepoint.y);
    
	[timeView Introductionpoint3:MyMovepoint];
    //  [timeView Introductionpoint2];
    recordImageView.highlighted = YES;

    
	[timeView setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (isCanTouch) {
        return;
    }
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view];
    if (point.y<(timeView.frame.origin.y+timeView.frame.size.height) || point.y > (_bottomContainerView.frame.origin.y)) {
        return;
    }
    
    [_captureManager stopRecording];

    deleteBtn.enabled = YES;
    deleteLabel.alpha = 1.0f;
    
    if (deleteBtn.selected) {
        deleteBtn.selected = NO;
        [timeView setDelete:deleteBtn.selected];
        [self initLayer:(CGPoint){MyMovepoint.x+2,MyMovepoint.y}];
        
        [timeView setNeedsDisplay];
        return;
    }
    if (drawTime>self.maxSecond) {
        [timer invalidate];
        timer = nil;
        //To 使用可点
        return;
    }
    [timer invalidate];
    timer = nil;
    
    //设置结束时光标的位置
    CGPoint MyEndPoint = CGPointMake(MyMovepoint.x-1,MyMovepoint.y);
    layer.position = CGPointMake(MyEndPoint.x+3, MyEndPoint.y);
    
    [timeView Introductionpoint6:MyEndPoint];
    [timeView Introductionpoint6:MyMovepoint];
	[timeView Introductionpoint2];
	[timeView setNeedsDisplay];
    
    recordImageView.highlighted = NO;
    
    NSLog(@"=================end touch=====================");
}

#pragma mark -------------button actions---------------
//拍照页面，拍照按钮
- (void)takePictureBtnPressed:(UIButton*)sender {
    if (drawTime<self.minSecond) {
        return;
    }
    
    isCanTouch = YES;
    sureBtn.enabled = NO;
    
    __block UIView *bjView = [[UIView alloc] init];
    bjView.frame = (CGRect){timeView.frame.origin.x,timeView.frame.origin.y,timeView.frame.size.width,SN_APP_SIZE.height-timeView.frame.origin.y};
    bjView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:bjView];
    
    __block UIView *activeBjView = [[UIView alloc] init];
    activeBjView.frame = (CGRect){SN_APP_SIZE.width/2-50,SN_APP_SIZE.height/2-50,100,100};
    activeBjView.center = CGPointMake(self.view.center.x, self.view.center.y - CAMERA_TOPVIEW_HEIGHT);
    activeBjView.backgroundColor = [UIColor blackColor];
    activeBjView.alpha = .7f;
    activeBjView.layer.cornerRadius = 5;
    [self.view addSubview:activeBjView];
    
    __block UIActivityIndicatorView *actiView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    actiView.center = CGPointMake(self.view.center.x, self.view.center.y - CAMERA_TOPVIEW_HEIGHT - 10);
    [actiView startAnimating];
    [self.view addSubview:actiView];
    
    __block UILabel *actiLabel = [[UILabel alloc] initWithFrame:(CGRect){0,actiView.frame.size.height+actiView.frame.origin.y,60,20}];
    actiLabel.center = CGPointMake(self.view.center.x, self.view.center.y - 15);
    actiLabel.text = @"处理中";
    actiLabel.textColor = [UIColor whiteColor];
    actiLabel.textAlignment = NSTextAlignmentCenter;
    actiLabel.backgroundColor = [UIColor clearColor];
    actiLabel.font = [UIFont systemFontOfSize:18.0f];
    [self.view addSubview:actiLabel];
    
    [_captureManager takePicture:^(NSURL *fileUrl,int state,NSString *errorInfo) {
        NSLog(@"-----file url = %@--,state = %d,errorinfo = %@",fileUrl,state,errorInfo);

        [actiView stopAnimating];
        [actiView removeFromSuperview];
        actiView = nil;
        [bjView removeFromSuperview];
        bjView = nil;
        [activeBjView removeFromSuperview];
        activeBjView = nil;
        [actiLabel removeFromSuperview];
        actiLabel = nil;
        
        sureBtn.enabled = YES;
        isCanTouch = NO;
        
        if (state == 3) {
            block(fileUrl,state,errorInfo);

//            ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
//            [library writeVideoAtPathToSavedPhotosAlbum:fileUrl
//                                        completionBlock:^(NSURL *assetURL, NSError *error) {
//                                        }];
            [_captureManager deleteTempVideoFile];
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        }
        //将视频数据传递回去
        block(fileUrl,state,errorInfo);
    }];
}

//拍照页面，"取消"按钮
- (void)dismissBtnPressed:(id)sender
{
    //若已经开始录制，则弹出提示，否则，清除本地缓存，然后退出
    if (drawTime>0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"确认放弃本次录制的视频吗?" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        alertView.delegate = self;
        [alertView show];
    }
    else
    {
        [_captureManager deleteTempVideoFile];
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex)
    {
        [_captureManager deleteTempVideoFile];
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
}

//拍照页面，切换前后摄像头按钮按钮
- (void)switchCameraBtnPressed:(UIButton*)sender {
    sender.selected = !sender.selected;
    [_captureManager switchCamera:sender.selected];
}

//拍照页面，闪光灯按钮
- (void)flashBtnPressed:(UIButton*)sender {
    [_captureManager switchFlashMode:sender];
}

#pragma mark ---------rotate(only when this controller is presented, the code below effect)-------------
//<iOS6
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationOrientationChange object:nil];
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_6_0
//iOS6+
- (BOOL)shouldAutorotate
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationOrientationChange object:nil];
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    //    return [UIApplication sharedApplication].statusBarOrientation;
	return UIInterfaceOrientationPortrait;
}
#endif

@end
