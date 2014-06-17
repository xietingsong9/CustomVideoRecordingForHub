//
//  CVRUtilsAttributedLabel.m
//  CustomVideoRecording
//
//  Created by xiets on 14-2-19.
//  Copyright (c) 2014年 xietingsong. All rights reserved.
//

#import "CVRUtilsAttributedLabel.h"
#import <QuartzCore/QuartzCore.h>

@interface CVRUtilsAttributedLabel(){

}
@property (nonatomic,retain)NSMutableAttributedString          *attString;
@end

@implementation CVRUtilsAttributedLabel
@synthesize attString = _attString;

- (void)dealloc{
    [_attString release];
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)drawRect:(CGRect)rect{
    
    CATextLayer *textLayer = [CATextLayer layer];
    textLayer.string = _attString;
    textLayer.alignmentMode = @"center";
    textLayer.transform = CATransform3DMakeScale(0.5,0.5,1);
    textLayer.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    [self.layer addSublayer:textLayer];
}

- (void)setText:(NSString *)text{
    [super setText:text];
    if (text == nil) {
        self.attString = nil;
    }else{
        self.attString = [[[NSMutableAttributedString alloc] initWithString:text] autorelease];
    }
}

// 设置某段字的颜色
- (void)setColor:(UIColor *)color fromIndex:(NSInteger)location length:(NSInteger)length{
    if (location < 0||location>self.text.length-1||length+location>self.text.length) {
        return;
    }
    [_attString addAttribute:(NSString *)kCTForegroundColorAttributeName
                        value:(id)color.CGColor
                        range:NSMakeRange(location, length)];
}

// 设置某段字的字体
- (void)setFont:(UIFont *)font fromIndex:(NSInteger)location length:(NSInteger)length{
    if (location < 0||location>self.text.length-1||length+location>self.text.length) {
        return;
    }
    [_attString addAttribute:(NSString *)kCTFontAttributeName
                        value:(id)CTFontCreateWithName((CFStringRef)font.fontName,
                                                       font.pointSize*2,
                                                       NULL)
                        range:NSMakeRange(location, length)];
}

// 设置某段字的风格
- (void)setStyle:(CTUnderlineStyle)style fromIndex:(NSInteger)location length:(NSInteger)length{
    if (location < 0||location>self.text.length-1||length+location>self.text.length) {
        return;
    }
    [_attString addAttribute:(NSString *)kCTUnderlineStyleAttributeName
                        value:(id)[NSNumber numberWithInt:style]
                        range:NSMakeRange(location, length)];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
