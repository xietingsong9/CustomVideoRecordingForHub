//
//  CVRUtilsPalette.h
//  CustomVideoRecording
//
//  Created by xiets on 14-2-23.
//  Copyright 2014 xietingsong. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface CVRUtilsPalette : UIView
{
	float x;
	float y;
	//-------------------------
	int             Intsegmentcolor;
	float           Intsegmentwidth;
	CGColorRef      segmentColor;
    BOOL            isDeleteLine;
	//-------------------------
	NSMutableArray* myallpoint;
	NSMutableArray* myallline;
	NSMutableArray* myallColor;
	NSMutableArray* myallwidth;
    NSMutableArray* myAllEndPointArr;
    NSMutableArray* myEndPointArr;
}
@property float x;
@property float y;
@property int minSecond;
@property int maxSecond;

-(void)Introductionpoint1;
-(void)Introductionpoint2;
-(void)Introductionpoint3:(CGPoint)sender;
-(void)Introductionpoint4:(int)sender;
-(void)Introductionpoint5:(int)sender;
-(void)Introductionpoint6:(CGPoint)sender;

//=====================================
-(void)myLineFinallyRemove:(BOOL)isDelete;
- (CGPoint)lastPoint;
- (void)setDelete:(BOOL)isDelete;
@end
