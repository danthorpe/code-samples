//
//  ImageWell.m
//  InPrimroseHill
//
//  Created by Daniel Thorpe on 06/04/2012.
//  Copyright (c) 2012 Blinding Skies Limited. All rights reserved.
//

#import "RoundedRectViewContainer.h"

const RoundedRectViewContainerStyle defaultContainerStyle = {
    .radius = 16.f,
    .color = {"#FFFFFF", 1.f},
    .metrics = {
        .margin = {0.f, 0.f},
        .padding = {10.f, 10.f}
    },
    .shadow = {
        .offset = {0.f, 0.f},
        .radius = 3.f,
        .opacity = 0.5f,
        .color = {"#000000", 0.75f}
    }
};

@interface InnerShadowViewContainer : UIView
@property (nonatomic) RoundedRectViewContainerStyle style;

- (id)initWithFrame:(CGRect)frame style:(RoundedRectViewContainerStyle)style;

@end

@implementation InnerShadowViewContainer

@synthesize style = _style;

- (id)initWithFrame:(CGRect)frame style:(RoundedRectViewContainerStyle)style {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {

    // Call the super draw rect
    [super drawRect:rect];
    
    // Draw an inner shadow
    CGRect b = self.bounds;
    CGFloat minY = CGRectGetMinY(b);
    CGFloat maxY = CGRectGetMaxY(b);
    CGFloat minX = CGRectGetMinX(b);    
    CGFloat maxX = CGRectGetMaxX(b);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGFloat outsideOffset = 40.f;
    
    // Create the "visible" path, which will be the shape that gets the inner shadow
    // In this case it's just a rounded rect, but could be as complex as your want
    CGMutablePathRef visiblePath = CGPathCreateMutable();
    
    // Create the rounded rect using Beziers
    UIBezierPath *bezier = [UIBezierPath bezierPath];
    
    // Move to the top of the left side
    [bezier moveToPoint:CGPointMake(minX, minY + _style.radius)];
    
    // Draw the left edge
    [bezier addLineToPoint:CGPointMake(minX, maxY - _style.radius)];
    
    // Draw the bottom left arc
    [bezier addArcWithCenter:CGPointMake(minX + _style.radius, maxY - _style.radius) radius:_style.radius startAngle:M_PI endAngle:M_PI_2 clockwise:NO];
    
    // Draw the bottom edge
    [bezier addLineToPoint:CGPointMake(maxX - _style.radius, maxY)];
    
    // Draw the bottom right arc
    [bezier addArcWithCenter:CGPointMake(maxX - _style.radius, maxY - _style.radius) radius:_style.radius startAngle:M_PI_2 endAngle:0.f clockwise:NO];
    
    // Draw the right edge
    [bezier addLineToPoint:CGPointMake(maxX, minY + _style.radius)];
    
    // Draw the top right arc
    [bezier addArcWithCenter:CGPointMake(maxX - _style.radius, minY + _style.radius) radius:_style.radius startAngle:0.f endAngle:3.f*M_PI_2 clockwise:NO];
    
    // Draw the top edge
    [bezier addLineToPoint:CGPointMake(minX + _style.radius, minY)];
    
    // Draw the top left arc
    [bezier addArcWithCenter:CGPointMake(minX + _style.radius, minY + _style.radius) radius:_style.radius startAngle:3.f*M_PI_2 endAngle:M_PI clockwise:NO];
    
    // Add the bezier path
    CGPathAddPath(visiblePath, NULL, bezier.CGPath);
    
    // Close
    CGPathCloseSubpath(visiblePath);
        
    // Now create a larger rectangle, which we subtract the visible path from
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, -outsideOffset, -outsideOffset);
    CGPathAddLineToPoint(path, NULL, b.size.width+outsideOffset, -outsideOffset);
    CGPathAddLineToPoint(path, NULL, b.size.width+outsideOffset, b.size.height+outsideOffset);
    CGPathAddLineToPoint(path, NULL, -outsideOffset, b.size.height+outsideOffset);
    
    // Add the visible path (so that it gets subtracted, leaving a hole)
    CGPathAddPath(path, NULL, visiblePath);
    CGPathCloseSubpath(path);
    
    // Set the clipping path to the visisble path, so that we don't draw outside of it.
//    CGContextAddPath(context, visiblePath);
//    CGContextClip(context);
    
    // Save the context
    CGContextSaveGState(context);
    
    // Set the shadow
    CGContextSetShadowWithColor(context, _style.shadow.offset, _style.shadow.radius, UIColorFromTHNHexColor(_style.shadow.color).CGColor);
    
    // Fill the rectangle with the hole in it
    [UIColorFromTHNHexColor(_style.color) setFill];
    CGContextSaveGState(context);
    CGContextAddPath(context, path);
    CGContextFillPath(context);
    
    // Release memory
    CGPathRelease(visiblePath);
    CGPathRelease(path);
}

@end


@interface RoundedRectViewContainer (/* Private */)

@property (weak, nonatomic) InnerShadowViewContainer *innerShadow;

@end

@implementation RoundedRectViewContainer

@synthesize composite = _composite;
@synthesize innerShadow = _innerShadow;
@synthesize style = _style;

+ (const RoundedRectViewContainerStyle)defaultStyle {
    return defaultContainerStyle;
}

- (id)initWithFrame:(CGRect)frame composite:(UIView *)composite {
    self = [super initWithFrame:frame];
    if (self) {

        // Initialization code
        self.backgroundColor = [UIColor whiteColor];

        // Set the style
        _style = [RoundedRectViewContainer defaultStyle];

        // Create a rect
        CGRect rect = CGRectInset(self.bounds, _style.metrics.padding.width, _style.metrics.padding.height);
        [composite setFrame:rect];
        _composite = composite;
        [self addSubview:composite];
        
        // Create an inner shadow view
        InnerShadowViewContainer *aView = [[InnerShadowViewContainer alloc] initWithFrame:CGRectInset(rect, _style.metrics.margin.width, _style.metrics.margin.height) style:_style];
        [self insertSubview:aView aboveSubview:composite];
        _innerShadow = aView;

    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    // Initialization code
    self.backgroundColor = [UIColor whiteColor];
    
    // Set the style
    _style = [RoundedRectViewContainer defaultStyle];

    
}


- (void)setStyle:(RoundedRectViewContainerStyle)style {
    // Set the style
    _style = style;
    _innerShadow.style = style;
    
    CGRect rect = CGRectInset(self.bounds, _style.metrics.padding.width, _style.metrics.padding.height);
    [_composite setFrame:rect];
    [_innerShadow setFrame:CGRectInset(rect, _style.metrics.margin.width, _style.metrics.margin.height)];
    
    [self setNeedsDisplay];
}

- (void)setComposite:(UIView *)composite {
    if (![_composite isEqual:composite]) {
        [self willChangeValueForKey:@"composite"];

        // Remove the old composite
        [_composite removeFromSuperview];

        // Create a rect
        CGRect rect = CGRectInset(self.bounds, _style.metrics.padding.width, _style.metrics.padding.height);        
        
        // Create an inner shadow view
        if (!_innerShadow) {
            InnerShadowViewContainer *aView = [[InnerShadowViewContainer alloc] initWithFrame:CGRectInset(rect, _style.metrics.margin.width, _style.metrics.margin.height) style:_style];
            [self addSubview:aView];
            _innerShadow = aView;
        }
                
        [composite setFrame:rect];
        _composite = composite;
        [self insertSubview:composite belowSubview:_innerShadow];
                
        // Set display
        [self setNeedsDisplay];
        
        [self didChangeValueForKey:@"composite"];
    }
}

@end
