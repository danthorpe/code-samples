//
//  Webservice.m
//  InPrimroseHill
//
//  Created by Daniel Thorpe on 03/04/2012.
//  Copyright (c) 2012 Blinding Skies Limited. All rights reserved.
//

#import "KeychainItemWrapper.h"
#import "MockURLProtocol.h"
#import "User.h"
#import "Device.h"
#import "ResourceMapper.h"
#import "ManagedObjectResourceMapper.h"
#import "Webservice.h"

#import <Security/Security.h>

#if TARGET_IPHONE_SIMULATOR
NSString * const WebserviceAddress = @"http://localhost:9393";
#else
#ifndef DEBUG
NSString * const WebserviceAddress = @"https://api.truelocal.me";
#else
NSString * const WebserviceAddress = @"http://192.168.80.3:9999";
#endif
#endif
NSString * const WebserviceClientIdentifier = @"com.300notes.truelocal.inprimrosehill.iphone";

#define kSecretKey @"BC328826-F6AF-4110-871E-39D776D24FEA"

const struct WebserviceHeaderNames WebserviceHeaderNames = {
    .clientIdentifier = @"X-Client-Identifier",
    .clientSecretKey = @"X-Client-Secret-Key",
    .apiVersion = @"X-API-Version",
    .clientAccountIdentifier = @"X-Client-Account-Identifier",
    .clientAccountToken = @"X-Client-Account-Token",
    .deviceIdentifier = @"X-Device-Identifier"
};

/// A block type for successful response.
typedef void(^SuccessfulCompletionBlock)(AFHTTPRequestOperation *operation, id responseObject);

/// A block type for failed response.
typedef void(^FailedCompletionBlock)(AFHTTPRequestOperation *operation, NSError *error);

@interface Webservice (/* Private */)

+ (SuccessfulCompletionBlock)successfulCompletionBlockInManagedObjectContext:(NSManagedObjectContext *)moc 
                                                                  completion:(WebserviceResponseCompletionBlock)completion;

+ (FailedCompletionBlock)failedCompletionBlockWithCompletion:(WebserviceResponseCompletionBlock)completion;

@end

@implementation Webservice

@synthesize account = _account;

+ (Webservice *)sharedWebservice {
    
    static Webservice *_sharedWebservice = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        NSURL *url = [NSURL URLWithString:WebserviceAddress];
        DDLogInfo(@"Initializing Webservice with server: %@", [url absoluteString]);
        _sharedWebservice = [[self alloc] initWithBaseURL:url];
    });
    
    return _sharedWebservice;
}

+ (SuccessfulCompletionBlock)successfulCompletionBlockInManagedObjectContext:(NSManagedObjectContext *)moc completion:(WebserviceResponseCompletionBlock)completion {    
    return ^(AFHTTPRequestOperation *operation, id responseObject) {                

        // Stop any mocking
        [[Webservice sharedWebservice] stopMocking:operation.request];        
        
#ifdef DEBUG
        
        // Dump out the request and response headers
        [[operation.request allHTTPHeaderFields] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            DDLogVerbose(@"request header[%@]: %@", key, obj);            
        }];

        // Dump out the request and response headers
        [[operation.response allHeaderFields] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            DDLogVerbose(@"response header[%@]: %@", key, obj);            
        }];
#endif        
        // Define some variables        
        NSMutableArray *resultObjects = nil;
        NSError *error = nil;
        
        if (responseObject) {
            // Get the objects from the response
            NSArray *objects = [ResourceMapper objectsFromResponse:responseObject];
            
            // Create a mutable array to store result objects in
            resultObjects = [NSMutableArray arrayWithCapacity:[objects count]];
                        
            // Iterate through the objects
            for (NSDictionary *dic in objects) {
                
                // Get a resource mapper
                id resourceMapper = [ResourceMapper mapperForResponse:dic];
                
                if (resourceMapper) {
                    
                    // Set the MOC if it exists
                    if (moc && [resourceMapper respondsToSelector:@selector(setManagedObjectContext:)]) {
                        [resourceMapper setManagedObjectContext:moc];
                    }
                    
                    // Create an object from the mapper
                    id obj = [resourceMapper objectFromResponse:dic];
                    
                    if (obj) {
                        // Map the resource
                        [resourceMapper mapObject:obj fromResponse:dic];
                        
                        // Add the object
                        [resultObjects addObject:obj];
                    }
                }
            }
        }
        
        // Call the completion handler
        if (completion) completion(resultObjects, responseObject, operation.response.statusCode, error);
    };
}

+ (FailedCompletionBlock)failedCompletionBlockWithCompletion:(WebserviceResponseCompletionBlock)completion {
    return ^(AFHTTPRequestOperation *operation, NSError *error) {
        
        // Stop any mocking
        [[Webservice sharedWebservice] stopMocking:operation.request];        
        
        // Call the completion handler
        if (completion) completion(nil, nil, operation.response.statusCode, error);
    };
}

+ (AFHTTPRequestOperation *)operationForRequest:(NSURLRequest *)request 
              inManagedObjectContext:(NSManagedObjectContext *)moc 
                          completion:(WebserviceResponseCompletionBlock)completion {
    NSParameterAssert(request);
    
    // Create an operation
    AFJSONRequestOperation *op = [[AFJSONRequestOperation alloc] initWithRequest:request];
    
    // Set the completion block
    [op setCompletionBlockWithSuccess:[Webservice successfulCompletionBlockInManagedObjectContext:moc completion:completion]
                              failure:[Webservice failedCompletionBlockWithCompletion:completion]];
    
    return op;
}

+ (AFHTTPRequestOperation *)callRequest:(NSURLRequest *)request 
      inManagedObjectContext:(NSManagedObjectContext *)moc 
                  completion:(WebserviceResponseCompletionBlock)completion {
    
    AFJSONRequestOperation *op = (AFJSONRequestOperation *)[Webservice operationForRequest:request inManagedObjectContext:moc completion:completion];
    
    // Add the operation
    [[Webservice sharedWebservice] enqueueHTTPRequestOperation:op];
    
    return op;    
}

+ (AFHTTPRequestOperation *)callRequest:(NSURLRequest *)request completion:(WebserviceResponseCompletionBlock)completion {
    return [Webservice callRequest:request inManagedObjectContext:nil completion:completion];
}

+ (void)groupRequestOperations:(NSArray *)operations 
                      progress:(void (^)(NSUInteger numberOfCompletedOperations, NSUInteger totalNumberOfOperations))progressBlock 
                    completion:(void (^)(NSArray *operations))completionBlock {
    NSParameterAssert(operations);
    
    // This is supported directly by AFNetworking
    [[Webservice sharedWebservice] enqueueBatchOfHTTPRequestOperations:operations progressBlock:progressBlock completionBlock:completionBlock];
}

+ (void)mockRequest:(NSURLRequest *)request withMockDataNamed:(NSString *)filename statusCode:(NSUInteger)statusCode errorMessage:(NSString *)errorMessage {    
    NSData *data = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:filename ofType:@"json"]];
    NSError *error = nil;
    if (errorMessage) {
        error = [NSError errorWithDomain:ErrorDomain code:-69 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:errorMessage, NSLocalizedDescriptionKey, nil]];
    }
    [[Webservice sharedWebservice] mockRequest:request withData:data statusCode:statusCode error:error];
}

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (self) {
        
        // Set the Keychain Item Wrappers
        _account = [[KeychainItemWrapper alloc] initWithIdentifier:UserDefaultsKeys.account accessGroup:nil];
        
        // X-Client-Identifier
        [self setDefaultHeader:WebserviceHeaderNames.clientIdentifier value:WebserviceClientIdentifier];
        
        // X-Client-Secret-Key
        [self setDefaultHeader:WebserviceHeaderNames.clientSecretKey value:kSecretKey];
        
        // X-API-Version HTTP Header
        [self setDefaultHeader:WebserviceHeaderNames.apiVersion value:@"1"];
        
        // X-Client-Account-Identifier
        id accountIdentifier = [_account objectForKey:(__bridge_transfer id)kSecAttrAccount];
        if (accountIdentifier) {
            // X-API-Version HTTP Header
            [self setDefaultHeader:WebserviceHeaderNames.clientAccountIdentifier value:accountIdentifier];
        }
        
        // X-Client-Account-Token
        id accountToken = [_account objectForKey:(__bridge_transfer id)kSecValueData];
        if (accountToken) {
            // X-API-Version HTTP Header
            [self setDefaultHeader:WebserviceHeaderNames.clientAccountToken value:accountToken];
        }

#if TARGET_OS_IPHONE
        // X-UDID HTTP Header
        [self setDefaultHeader:WebserviceHeaderNames.deviceIdentifier value:[Device identifier]];
#endif

    }
    return self;
}

- (void)mockRequest:(NSURLRequest *)request withData:(NSData *)data statusCode:(NSUInteger)statusCode error:(NSError *)error {
    
    // Register our test NSURLProtocol class
    [NSURLProtocol registerClass:[MockURLProtocol class]];    
    
    // Define the standard response headers
    static NSDictionary *headers = nil;
    if (!headers) headers = [NSDictionary dictionaryWithObjectsAndKeys:@"application/json; charset=utf-8", @"Content-Type", nil];
    
    // Set the mock properties for the request
    [MockURLProtocol mockRequest:request withHeaders:headers data:data statusCode:[NSNumber numberWithInteger:statusCode] error:error];
}

- (void)stopMocking:(NSURLRequest *)request {
    // Remove this mock request
    [MockURLProtocol removeMockRequest:request];
    
    if ( 0 == [MockURLProtocol numberOfMockRequests] ) {
        [NSURLProtocol unregisterClass:[MockURLProtocol class]];
    }
}

@end
