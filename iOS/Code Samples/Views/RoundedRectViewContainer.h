//
//  ImageWell.h
//  InPrimroseHill
//
//  Created by Daniel Thorpe on 06/04/2012.
//  Copyright (c) 2012 Blinding Skies Limited. All rights reserved.
//

#import "THNStyleUtilities.h"

typedef struct {
    CGFloat radius;    
    THNViewMetrics metrics;
    THNHexColor color;
    THNViewShadowStyle shadow;    
} RoundedRectViewContainerStyle;

@interface RoundedRectViewContainer : UIView

@property (strong, nonatomic) UIView *composite;
@property (nonatomic) RoundedRectViewContainerStyle style;

+ (const RoundedRectViewContainerStyle)defaultStyle;

- (id)initWithFrame:(CGRect)frame composite:(UIView *)composite;

@end
