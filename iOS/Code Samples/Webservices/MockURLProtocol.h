//
//  MockURLProtocol.h
//  InPrimroseHill
//
//  Created by Daniel Thorpe on 08/05/2012.
//  Copyright (c) 2012 Blinding Skies Limited. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MockURLProtocol : NSURLProtocol

+ (void)setMocks:(NSMutableDictionary *)m;

+ (void)mockRequest:(NSURLRequest *)request 
        withHeaders:(NSDictionary *)h 
               data:(NSData *)d 
         statusCode:(NSNumber *)sc 
              error:(NSError *)e;

+ (void)removeMockRequest:(NSURLRequest *)request;

+ (NSUInteger)numberOfMockRequests;

@end