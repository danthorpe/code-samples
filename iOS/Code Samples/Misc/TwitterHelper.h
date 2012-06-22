//
//  TwitterHelper.h
//  InPrimroseHill
//
//  Created by Daniel Thorpe on 23/05/2012.
//  Copyright (c) 2012 Blinding Skies Limited. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TwitterHelper : NSObject

+ (void)getProfileImageForUsername:(NSString *)username completion:(void(^)(UIImage *image, NSError *error))completion;

@end
