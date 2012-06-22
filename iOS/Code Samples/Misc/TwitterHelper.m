//
//  TwitterHelper.m
//  InPrimroseHill
//
//  Created by Daniel Thorpe on 23/05/2012.
//  Copyright (c) 2012 Blinding Skies Limited. All rights reserved.
//

#import "TwitterHelper.h"

#define kTwitterApiRootURL [NSURL URLWithString:@"https://api.twitter.com/1/"]

@implementation TwitterHelper

+ (void)getProfileImageForUsername:(NSString *)username completion:(void(^)(UIImage *image, NSError *error))completion {

    NSParameterAssert(username);
    NSParameterAssert(completion);
    
    // Create the URL
    NSURL *url = [NSURL URLWithString:@"users/profile_image" relativeToURL:kTwitterApiRootURL];
    
    // Create the parameters
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            username, @"screen_name", 
                            @"bigger", @"size",
                            nil];
    
    // Create a TWRequest to get the the user's profile image
    TWRequest *request = [[TWRequest alloc] initWithURL:url parameters:params requestMethod:TWRequestMethodGET];
    
    // Execute the request
    [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {

        // Handle any errors properly, not like this!        
        if (!responseData && error) {
            completion(nil, error);
        }
        
        // We should now have some image data
        completion([UIImage imageWithData:responseData], nil);
    }];
}

@end
