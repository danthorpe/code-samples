//
//  ResponseMapper.h
//  InPrimroseHill
//
//  Created by Daniel Thorpe on 21/04/2012.
//  Copyright (c) 2012 Blinding Skies Limited. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ResourceMapping <NSObject>

- (id)objectFromResponse:(id)response;
- (void)mapObject:(id)object fromResponse:(id)response;

- (id)resourceFromObject:(id)object;
- (void)mapObject:(id)object toResponse:(id)response;

@end

extern const struct CommonResourceAttributes {
    __unsafe_unretained NSString *typeKey;
    __unsafe_unretained NSString *identifierKey;
} CommonResourceAttributes;

extern const struct ResourceTypes {
    __unsafe_unretained NSString *community;    
    __unsafe_unretained NSString *device;    
    __unsafe_unretained NSString *person;
    __unsafe_unretained NSString *personPosition;
    __unsafe_unretained NSString *personUser;
    __unsafe_unretained NSString *business;
    __unsafe_unretained NSString *businessUser;
    __unsafe_unretained NSString *contentItem;
} ResourceTypes;

@interface ResourceMapper : NSObject <ResourceMapping>

// Class methods for standard response - lists of objects
+ (NSArray *)objectsFromResponse:(id)response;

+ (id)mapperForResponse:(id)response;

+ (id)mapperForResourceType:(NSString *)resourceType;

+ (id)mapperForEntityName:(NSString *)entityName;

@end
