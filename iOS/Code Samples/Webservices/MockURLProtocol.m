//
//  MockURLProtocol.m
//  InPrimroseHill
//
//  Created by Daniel Thorpe on 08/05/2012.
//  Copyright (c) 2012 Blinding Skies Limited. All rights reserved.
//

#import "MockURLProtocol.h"
#import "NSURLRequest+THN.h"

#define kMockDataForRequestKey @"data"
#define kMockStatusCodeForRequestKey @"status"
#define kMockErrorForRequestKey @"error"
#define kMockHeadersForRequestKey @"headers"

static NSMutableDictionary *mocks = nil;

@implementation MockURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    // Only mock requests which we have configured
    return [mocks objectForKey:[request identifier]] != nil;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

+ (void)setMocks:(NSMutableDictionary *)m {
    mocks = m;
}

+ (void)mockRequest:(NSURLRequest *)request 
        withHeaders:(NSDictionary *)h 
               data:(NSData *)d 
         statusCode:(NSNumber *)sc 
              error:(NSError *)e {
    
    // Create a dictionary
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:
                         h, kMockHeadersForRequestKey,
                         d, kMockDataForRequestKey, 
                         sc, kMockStatusCodeForRequestKey, 
                         e, kMockErrorForRequestKey, 
                         nil];
    if (!mocks) {
        mocks = [NSMutableDictionary dictionary];
    }
    
    // Set the object
    [mocks setObject:dic forKey:[request identifier]];
}

+ (void)removeMockRequest:(NSURLRequest *)request {    
    if (mocks) 
        [mocks removeObjectForKey:[request identifier]];
}

+ (NSUInteger)numberOfMockRequests {
    if (mocks) 
        return [[mocks allKeys] count];
    return 0;
}

- (NSCachedURLResponse *)cachedResponse {
    return nil;
}

- (void)startLoading {
    NSURLRequest *request = [self request];
    id<NSURLProtocolClient> client = [self client];
    NSString *key = [request identifier];
    NSData *d = [[mocks objectForKey:key] objectForKey:kMockDataForRequestKey];
    NSError *e = [[mocks objectForKey:key] objectForKey:kMockErrorForRequestKey];
    if (d) {
        DDLogVerbose(@"mocking response for: %@", key);
        NSUInteger statusCode = [[[mocks objectForKey:key] objectForKey:kMockStatusCodeForRequestKey] integerValue];
        NSDictionary *headers = [[mocks objectForKey:key] objectForKey:kMockHeadersForRequestKey];
        // Send the pre-set data
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:request.URL 
                                                                  statusCode:statusCode 
                                                                 HTTPVersion:@"HTTP/1.1" 
                                                                headerFields:headers];
        [client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        [client URLProtocol:self didLoadData:d];
        [client URLProtocolDidFinishLoading:self];
    } else if (e) {
        // Send the pre-set error
        [client URLProtocol:self didFailWithError:e];
    }
}

- (void)stopLoading { }

@end
