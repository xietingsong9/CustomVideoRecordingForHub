//
//  CVRUtilsPalette.m
//  CustomVideoRecording
//
//  Created by xiets on 14-2-23.
//  Copyright 2014 xietingsong. All rights reserved.
//

#import "CVRUtilsPalette.h"
#import "CVRDefines.h"


@implementation CVRUtilsPalette
@synthesize x;
@synthesize y;

static BOOL allline=NO;

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        if (self.minSecond<=0) {
            self.minSecond = 2;
        }
        // Initialization code.
    }
    return self;
	
}
-(void)IntsegmentColor
{
	switch (Intsegmentcolor)
	{
		case 0:
			segmentColor=[[UIColor blackColor] CGColor];
			break;
		case 1:
			segmentColor=[[UIColor redColor] CGColor];
			break;
		case 2:
			segmentColor=[[UIColor blueColor] CGColor];

			break;
		case 3:
			segmentColor=[[UIColor greenColor] CGColor];
			break;
		case 4:
			segmentColor=[[UIColor yellowColor] CGColor];
			break;
		case 5:
			segmentColor=[LINE_COLOR CGColor];
			break;
		case 6:
			segmentColor=[[UIColor grayColor] CGColor];
			break;
		case 7:
			segmentColor=[[UIColor purpleColor]CGColor];
			break;
		case 8:
			
			segmentColor=[[UIColor brownColor]CGColor];
			break;
		case 9:
			segmentColor=[[UIColor magentaColor]CGColor];
			break;
		case 10:
			segmentColor=[[UIColor whiteColor]CGColor];
			break;

		default:
			break;
	}
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect 
{
	//获取上下文
	CGContextRef context=UIGraphicsGetCurrentContext();
	//设置笔冒
	CGContextSetLineCap(context, kCGLineCapButt);
	//设置画线的连接处　拐点圆滑
	CGContextSetLineJoin(context, kCGLineJoinRound);
	//第一次时候个myallline开辟空间
	if (allline==NO)
	{
		myallline=[[NSMutableArray alloc] initWithCapacity:10];
        myAllEndPointArr=[[NSMutableArray alloc] initWithCapacity:10];

		myallColor=[[NSMutableArray alloc] initWithCapacity:10];
		myallwidth=[[NSMutableArray alloc] initWithCapacity:10];
        
		allline=YES;
	}
    CGContextBeginPath(context);
    CGPoint myStartPoint= (CGPoint){SN_APP_SIZE.width*self.minSecond/self.maxSecond,4};
    CGContextMoveToPoint(context, myStartPoint.x, myStartPoint.y);
    CGPoint myEndPoint=(CGPoint){SN_APP_SIZE.width*self.minSecond/self.maxSecond+1,4};
    //--------------------------------------------------------
    CGContextAddLineToPoint(context, myEndPoint.x,myEndPoint.y);
    
    Intsegmentcolor = 5;
    Intsegmentwidth = 8;
    [self IntsegmentColor];
    CGContextSetStrokeColorWithColor(context, segmentColor);
    //-------------------------------------------------------
    CGContextSetLineWidth(context, Intsegmentwidth);
    CGContextStrokePath(context);
    
	//画之前线
	if ([myallline count]>0)
	{
		for (int i=0; i<[myallline count]; i++)
		{
			NSArray* tempArray=[NSArray arrayWithArray:[myallline objectAtIndex:i]];
            Intsegmentcolor = 5;//[[myallColor lastObject] intValue];
            Intsegmentwidth = 8;//[[myallwidth lastObject]floatValue]+1;

			if ([tempArray count]>1)
			{
				CGContextBeginPath(context);
				CGPoint myStartPoint=[[tempArray objectAtIndex:0] CGPointValue];
				CGContextMoveToPoint(context, myStartPoint.x, myStartPoint.y);
				
				for (int j=0; j<[tempArray count]-1; j++)
				{
					CGPoint myEndPoint=[[tempArray objectAtIndex:j+1] CGPointValue];
					CGContextAddLineToPoint(context, myEndPoint.x,myEndPoint.y);
				}
				[self IntsegmentColor];
				CGContextSetStrokeColorWithColor(context, segmentColor);
				CGContextSetLineWidth(context, Intsegmentwidth);
				CGContextStrokePath(context);
			}
		}
	}
    
	//画当前的线
	if ([myallpoint count]>1)
	{
		CGContextBeginPath(context);
		//-------------------------
		//起点
		//------------------------
		CGPoint myStartPoint=[[myallpoint objectAtIndex:0]   CGPointValue];
		CGContextMoveToPoint(context, myStartPoint.x, myStartPoint.y);
		//把move的点全部加入　数组
		for (int i=0; i<[myallpoint count]-1; i++)
		{
			CGPoint myEndPoint=  [[myallpoint objectAtIndex:i+1] CGPointValue];
			CGContextAddLineToPoint(context, myEndPoint.x,   myEndPoint.y);
		}
		//在颜色和画笔大小数组里面取不相应的值
		Intsegmentcolor = 5;//[[myallColor lastObject] intValue];
		Intsegmentwidth = 8;//[[myallwidth lastObject]floatValue]+1;
		
		//-------------------------------------------
		//绘制画笔颜色
		[self IntsegmentColor];
		CGContextSetStrokeColorWithColor(context, segmentColor);
		CGContextSetFillColorWithColor (context,  segmentColor);
		//-------------------------------------------
		//绘制画笔宽度
		CGContextSetLineWidth(context, Intsegmentwidth);
		//把数组里面的点全部画出来
		CGContextStrokePath(context);
	}
    //画即将删除的线
    if (isDeleteLine) {
        if ([[myallline lastObject] count]>1)
        {
            CGContextBeginPath(context);
            //-------------------------
            //起点
            //------------------------
            CGPoint myEndPoint=[[[myallline lastObject] objectAtIndex:0]   CGPointValue];
            CGContextMoveToPoint(context,    myEndPoint.x, myEndPoint.y);
            //把move的点全部加入　数组
            for (int i=0; i<[[myallline lastObject] count]-1; i++)
            {
                CGPoint myStartPoint=  [[[myallline lastObject] objectAtIndex:i+1] CGPointValue];
                CGContextAddLineToPoint(context, myStartPoint.x,   myStartPoint.y);
            }
            //在颜色和画笔大小数组里面取不相应的值
            Intsegmentcolor = 1;//[[myallColor lastObject] intValue];
            Intsegmentwidth = 8;//[[myallwidth lastObject]floatValue]+1;
            
            //-------------------------------------------
            //绘制画笔颜色
            [self IntsegmentColor];
            CGContextSetStrokeColorWithColor(context, segmentColor);
            CGContextSetFillColorWithColor (context,  segmentColor);
            //-------------------------------------------
            //绘制画笔宽度
            CGContextSetLineWidth(context, Intsegmentwidth);
            //把数组里面的点全部画出来
            CGContextStrokePath(context);
        }
    }
	
    //画分界点
	if ([myAllEndPointArr count]>0)
	{
		for (int i=0; i<[myAllEndPointArr count]; i++)
		{
			NSArray* tempArray=[NSArray arrayWithArray:[myAllEndPointArr objectAtIndex:i]];

            Intsegmentcolor=0;//[[myallColor objectAtIndex:i] intValue];
            Intsegmentwidth= 8;//[[myallwidth objectAtIndex:i]floatValue]+1;
            
			//-----------------------------------------------------------------
			if ([tempArray count]>1)
			{
				CGContextBeginPath(context);
				CGPoint myStartPoint=[[tempArray objectAtIndex:0] CGPointValue];
				CGContextMoveToPoint(context, myStartPoint.x, myStartPoint.y);
				
				for (int j=0; j<[tempArray count]-1; j++)
				{
					CGPoint myEndPoint=[[tempArray objectAtIndex:j+1] CGPointValue];
                    if (myEndPoint.x< [[UIScreen mainScreen] applicationFrame].size.width) {
                        CGContextAddLineToPoint(context, myEndPoint.x,myEndPoint.y);

                    }
					//--------------------------------------------------------
				}
				[self IntsegmentColor];
				CGContextSetStrokeColorWithColor(context, segmentColor);
				//-------------------------------------------------------
				CGContextSetLineWidth(context, Intsegmentwidth);
				CGContextStrokePath(context);
			}
		}
	}
    
    
}

/**
 *  初始化
 */
-(void)Introductionpoint1
{
	myallpoint=[[NSMutableArray alloc] initWithCapacity:10];
    myEndPointArr=[[NSMutableArray alloc] initWithCapacity:10];

}

/**
 *  把画过的当前线放入　存放线的数组
 */
-(void)Introductionpoint2
{
    [myAllEndPointArr addObject:myEndPointArr];
	[myallline addObject:myallpoint];
}
-(void)Introductionpoint3:(CGPoint)sender
{
	NSValue* pointvalue=[NSValue valueWithCGPoint:sender];
	[myallpoint addObject:[pointvalue retain]];
	[pointvalue release];
}

-(void)Introductionpoint6:(CGPoint)sender
{
	NSValue* pointvalue=[NSValue valueWithCGPoint:sender];
	[myEndPointArr addObject:[pointvalue retain]];
	[pointvalue release];
}

/**
 *  接收颜色segement反过来的值
 *
 *  @param sender
 */
-(void)Introductionpoint4:(int)sender
{
	NSLog(@"Palette sender:%i", sender);
	NSNumber* Numbersender= [NSNumber numberWithInt:sender];
	[myallColor addObject:Numbersender];
}

/**
 *  接收线条宽度按钮反回来的值
 *
 *  @param sender
 */
-(void)Introductionpoint5:(int)sender
{
	NSNumber* Numbersender= [NSNumber numberWithInt:sender];
	[myallwidth addObject:Numbersender];
}

/**
 *  撤销
 *
 *  @param isDelete
 */
-(void)myLineFinallyRemove:(BOOL)isDelete
{
    isDeleteLine = isDelete;
    if (isDeleteLine) {
      //  NSLog(@"是否删除");
        [self setNeedsDisplay];
        return;

    }
	if ([myallline count]>0)
	{
		[myallline  removeLastObject];
		[myallColor removeLastObject];
		[myallwidth removeLastObject];
		[myallpoint removeAllObjects];
        [myAllEndPointArr removeLastObject];
	}
	[self setNeedsDisplay];	
}

- (CGPoint)lastPoint
{
    if ([[myallline lastObject] count]) {
        return [[[myallline lastObject] lastObject] CGPointValue];
    }
    return (CGPoint){0,100};
}

- (void)setDelete:(BOOL)isDelete
{
    isDeleteLine = isDelete;
}

- (void)dealloc 
{
    allline = NO;
    [myallpoint release];
    myallpoint = nil;
    [myallColor release];
    myallColor = nil;
    [myAllEndPointArr release];
    myAllEndPointArr = nil;
    [myEndPointArr release];
    myEndPointArr = nil;
    [myallline release];
    myallline = nil;
    [myallwidth release];
    myallwidth = nil;
    isDeleteLine = NO;
    x = 0;
    y = 0;
    self.minSecond = 0;
    self.maxSecond = 0;
    
    [super dealloc];
}

@end
