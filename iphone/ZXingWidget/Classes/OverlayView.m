// -*- Mode: ObjC; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-

/**
 * Copyright 2009 Jeff Verkoeyen
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "OverlayView.h"

@interface OverlayView()
@property (nonatomic,assign) UIButton *cancelButton;
@property (nonatomic,assign) UIButton *licenseButton;
@property (nonatomic,retain) UILabel *instructionsLabel;
@end

@implementation OverlayView

@synthesize delegate, oneDMode;
@synthesize points = _points;
@synthesize cancelButton;
@synthesize licenseButton;
@synthesize cropRect;
@synthesize instructionsLabel;
@synthesize displayedMessage;
@synthesize cancelButtonTitle;
@synthesize cancelEnabled;
@synthesize fadedQR;

////////////////////////////////////////////////////////////////////////////////////////////////////

- (id) initWithFrame:(CGRect)theFrame cancelEnabled:(BOOL)isCancelEnabled oneDMode:(BOOL)isOneDModeEnabled {
    return [self initWithFrame:theFrame cancelEnabled:isCancelEnabled oneDMode:isOneDModeEnabled showLicense:YES];
}

- (id) initWithFrame:(CGRect)theFrame cancelEnabled:(BOOL)isCancelEnabled oneDMode:(BOOL)isOneDModeEnabled showLicense:(BOOL)showLicenseButton {
    return [self initWithFrame:theFrame cancelEnabled:isCancelEnabled oneDMode:isOneDModeEnabled showLicense:YES withPrompt:@""];
}

- (id) initWithFrame:(CGRect)theFrame cancelEnabled:(BOOL)isCancelEnabled oneDMode:(BOOL)isOneDModeEnabled showLicense:(BOOL)showLicenseButton withPrompt:(NSString *)p
{
    if(self = [super initWithFrame:theFrame])
    {
        self.oneDMode = NO;
        self.cancelEnabled = YES;
        self.displayedMessage = p;
        
        CGFloat cropSize = self.frame.size.width-75;
        cropRect = CGRectMake(0, self.frame.size.height/2-cropSize/2,self.frame.size.width,cropSize);
        CGFloat qrSize = self.frame.size.width-150;
        fadedQR = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"qr_nowhite.png"]];
        fadedQR.alpha = 0.4;
        fadedQR.frame = CGRectMake(self.frame.size.width/2-qrSize/2,self.frame.size.height/2-qrSize/2,qrSize,qrSize);
        [self addSubview:fadedQR];
        
        self.backgroundColor = [UIColor clearColor];

        self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        if([self.cancelButtonTitle length] > 0)
            [cancelButton setTitle:self.cancelButtonTitle forState:UIControlStateNormal];
        else
            [cancelButton setTitle:NSLocalizedStringWithDefaultValue(@"OverlayView cancel button title", nil, [NSBundle mainBundle], @"Cancel", @"Cancel") forState:UIControlStateNormal];
        self.cancelButton.backgroundColor = [UIColor colorWithRed:(214.0/255.0) green:(218.0/255.0)  blue:(211.0/255.0) alpha:1.0];
        [self.cancelButton setTitleColor:[UIColor colorWithRed:(0.0/255.0) green:(101.0/255.0) blue:(149.0/255.0) alpha:1.0] forState:UIControlStateNormal];
        [cancelButton addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:cancelButton];
    }
    return self;
}

- (void)cancel:(id)sender {
    if(delegate != nil) [delegate cancelled];
}

////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) dealloc {
    [_points release];
    [instructionsLabel release];
    [displayedMessage release];
    [cancelButtonTitle release],
    [fadedQR release];
    [super dealloc];
}

- (void)drawRect:(CGRect)rect inContext:(CGContextRef)context {
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, rect.origin.x, rect.origin.y);
    CGContextAddLineToPoint(context, rect.origin.x + rect.size.width, rect.origin.y);
    CGContextAddLineToPoint(context, rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);
    CGContextAddLineToPoint(context, rect.origin.x, rect.origin.y + rect.size.height);
    CGContextAddLineToPoint(context, rect.origin.x, rect.origin.y);
    CGContextClosePath(context);
    CGContextFillPath(context);
}

- (CGPoint)map:(CGPoint)point {
    CGPoint center;
    center.x = cropRect.size.width/2;
    center.y = cropRect.size.height/2;
    float x = point.x - center.x;
    float y = point.y - center.y;
    int rotation = 90;
    switch(rotation) {
        case 0:
            point.x = x;
            point.y = y;
            break;
        case 90:
            point.x = -y;
            point.y = x;
            break;
        case 180:
            point.x = -x;
            point.y = -y;
            break;
        case 270:
            point.x = y;
            point.y = -x;
            break;
    }
    point.x = point.x + center.x;
    point.y = point.y + center.y;
    return point;
}

#define kTextMargin 10

////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGContextRef c = UIGraphicsGetCurrentContext();
    
    
    CGFloat clearBlack[4] = {0.0f, 0.0f, 0.0f, 0.6f};
    CGContextSetFillColor(c, clearBlack);
    CGFloat white[4] = {0.0f, 0.0f, 0.0f, 0.6f};
    CGContextSetStrokeColor(c,white);
    [[UIColor whiteColor] setFill];
    
    [self drawRect:CGRectMake(0, 0, self.frame.size.width, cropRect.origin.y) inContext:c];
    [self drawRect:CGRectMake(0, cropRect.origin.y+cropRect.size.height, self.frame.size.width, self.frame.size.height-(cropRect.origin.y+cropRect.size.height)) inContext:c];
    
    CGContextSaveGState(c);

    UIFont *font = [UIFont systemFontOfSize:18];
    CGSize constraint = CGSizeMake(rect.size.width  - 2 * kTextMargin, cropRect.origin.y);
    CGSize displaySize = [self.displayedMessage sizeWithFont:font constrainedToSize:constraint];
    CGRect displayRect = CGRectMake((rect.size.width - displaySize.width)/2 , cropRect.origin.y - displaySize.height, displaySize.width, displaySize.height);
    [self.displayedMessage drawInRect:displayRect withFont:font lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentCenter];

    CGContextRestoreGState(c);
    
    if(nil != _points)
    {
        CGFloat blue[4] = {0.0f, 1.0f, 0.0f, 1.0f};
        CGContextSetStrokeColor(c, blue);
        CGContextSetFillColor(c, blue);
        CGRect smallSquare = CGRectMake(0, 0, 10, 10);
        for(NSValue* value in _points)
        {
            CGPoint point = [self map:[value CGPointValue]];
            smallSquare.origin = CGPointMake(
                                                cropRect.origin.x + point.x - smallSquare.size.width / 2,
                                                cropRect.origin.y + point.y - smallSquare.size.height / 2);
            [self drawRect:smallSquare inContext:c];
        }
    }
}


////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) setPoints:(NSMutableArray*)pnts
{
    [pnts retain];
    [_points release];
    _points = pnts;
    
    if (pnts != nil) {
        self.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.25];
    }
    [self setNeedsDisplay];
}

- (void) setPoint:(CGPoint)point
{
    if(!_points) _points = [[NSMutableArray alloc] init];
    if(_points.count > 3) [_points removeObjectAtIndex:0];
    [_points addObject:[NSValue valueWithCGPoint:point]];
    [self setNeedsDisplay];
}


- (void) layoutSubviews
{
    [super layoutSubviews];
    if(cancelButton) self.cancelButton.frame = CGRectMake(-10,self.frame.size.height-46,self.frame.size.width+20,50);
}

@end
