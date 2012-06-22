//
//  Webservice.h
//  InPrimroseHill
//
//  Created by Daniel Thorpe on 03/04/2012.
//  Copyright (c) 2012 Blinding Skies Limited. All rights reserved.
//

#import "AFHTTPClient.h"

extern NSString * const WebserviceAddress;
extern NSString * const WebserviceClientIdentifier;

/** 
 A block type for the response of a simple mapping
 
 @param objects An `NSArray` of the mapped objects
 @param response The request response
 @param status The status code of the response
 @param error Any error encountered by the request, or mapping.
 */
typedef void(^WebserviceResponseCompletionBlock)(NSArray *objects, id response, NSUInteger status, NSError *error);

@class KeychainItemWrapper;

extern const struct WebserviceHeaderNames {
    __unsafe_unretained NSString *clientIdentifier;
    __unsafe_unretained NSString *clientSecretKey;
    __unsafe_unretained NSString *apiVersion;
    __unsafe_unretained NSString *clientAccountIdentifier;
    __unsafe_unretained NSString *clientAccountToken;
    __unsafe_unretained NSString *deviceIdentifier;    
} WebserviceHeaderNames;

@interface Webservice : AFHTTPClient

@property (nonatomic, strong) KeychainItemWrapper *account;

/**
 Get the shared instance.
 @return a `Webservice` instance
 */
+ (Webservice *)sharedWebservice;

/**
 Creates a `AFHTTPRequestOperation` for the request. It successfully integrates the completion handler into 
 success and failure blocks. Upon success, the response is data mapped into Core Data model objects.
 @param request the `NSURLRequest`.
 @param moc a `NSManagedObjectContext` which is used to fetch/insert objects into Core Data
 @param completion a `WebserviceResponseCompletionBlock` completion handler.
 */
+ (AFHTTPRequestOperation *)operationForRequest:(NSURLRequest *)request 
                         inManagedObjectContext:(NSManagedObjectContext *)moc 
                                     completion:(WebserviceResponseCompletionBlock)completion;

/**
 Enqueues a `AFHTTPRequestOperation` for the request.
 @param request the `NSURLRequest`.
 @param moc a `NSManagedObjectContext` which is used to fetch/insert objects into Core Data
 @param completion a `WebserviceResponseCompletionBlock` completion handler.
 */
+ (AFHTTPRequestOperation *)callRequest:(NSURLRequest *)request 
                 inManagedObjectContext:(NSManagedObjectContext *)moc 
                             completion:(WebserviceResponseCompletionBlock)completion;

/**
 Enqueues a `AFHTTPRequestOperation` for the request with no Core Data fancy stuff.
 @param request the `NSURLRequest` to mock. This means that mocks are for for request method, path, parameters, body etc
 @param completion a `WebserviceResponseCompletionBlock` completion handler.
 */
+ (AFHTTPRequestOperation *)callRequest:(NSURLRequest *)request 
                             completion:(WebserviceResponseCompletionBlock)completion;

/**
 Enqueues an array of `AFHTTPRequestOperation` objects
 @param operations a `NSArray` of operations. This means that mocks are for for request method, path, parameters, body etc
 @param progressBlock a block which gets progress callbacks as operations are completed.
 @param completion a block executed after all operations complete.
 */

+ (void)groupRequestOperations:(NSArray *)operations 
                      progress:(void (^)(NSUInteger numberOfCompletedOperations, NSUInteger totalNumberOfOperations))progressBlock 
                    completion:(void (^)(NSArray *operations))completionBlock;
/**
 Class method to register mock requests with equivalent responses.
 @param request the `NSURLRequest` to mock. This means that mocks are for for request method, path, parameters, body etc
 @param filename the `NSString` filename of the mock data.
 @param statusCode the HTTP response status code to use.
 */
+ (void)mockRequest:(NSURLRequest *)request 
  withMockDataNamed:(NSString *)filename 
         statusCode:(NSUInteger)statusCode 
       errorMessage:(NSString *)errorMessage;

/**
 Methods to register mock requests with equivalent responses.
 @param request the `NSURLRequest` to mock. This means that mocks are for for request method, path, parameters, body etc
 @param data the `NSData` to use as the response.
 @param statusCode the HTTP response status code to use.
 */
- (void)mockRequest:(NSURLRequest *)request 
           withData:(NSData *)data 
         statusCode:(NSUInteger)statusCode 
              error:(NSError *)error;

- (void)stopMocking:(NSURLRequest *)request;


@end
