//
//  ResponseMapper.m
//  InPrimroseHill
//
//  Created by Daniel Thorpe on 21/04/2012.
//  Copyright (c) 2012 Blinding Skies Limited. All rights reserved.
//

// Models
#import "Community.h"
#import "Device.h"
#import "Person.h"
#import "DevicePosition.h"
#import "PersonUser.h"
#import "Business.h"
#import "BusinessUser.h"
#import "ContentItem.h"

#import "ManagedObjectResourceMapper.h"
#import "PositionResourceMapper.h"

#import "ResourceMapper.h"

const struct CommonResourceAttributes CommonResourceAttributes = {
    .typeKey = @"type",
    .identifierKey = @"identifier"
};

const struct ResourceTypes ResourceTypes = {
    .community = @"Community",
    .device = @"Device",
    .person = @"Person",
    .personPosition = @"Position.Person",
    .personUser = @"User.Person",
    .business = @"Business",
    .businessUser = @"User.Business",
    .contentItem = @"ContentItem"
};

@implementation ResourceMapper

+ (NSArray *)objectsFromResponse:(id)response {
    if ( [response isKindOfClass:[NSArray class]] ) {
        return (NSArray *)response;
    } else if ( [response isKindOfClass:[NSDictionary class]] ) {
        return [NSArray arrayWithObject:response];
    }
    [NSException raise:GenericException format:@"Unknown response type: %@", response];
    return nil;
}

+ (id)mapperForResponse:(id)response {
    
    // Get the type
    NSString *resourceType = [response objectForKey:CommonResourceAttributes.typeKey];
    
    return [ResourceMapper mapperForResourceType:resourceType];
}

+ (id)mapperForResourceType:(NSString *)resourceType {
    
    if ( [ResourceTypes.community isEqualToString:resourceType] ) {
        
        return [ResourceMapper mapperForEntityName:[Community entityName]];
        
    } else if ( [ResourceTypes.device isEqualToString:resourceType] ) {
        
        return [ResourceMapper mapperForEntityName:[Device entityName]];
        
    } else if ( [ResourceTypes.person isEqualToString:resourceType] ) {
        
        return [ResourceMapper mapperForEntityName:[Person entityName]];
        
    } else if ( [ResourceTypes.personUser isEqualToString:resourceType] ) {
        
        return [ResourceMapper mapperForEntityName:[PersonUser entityName]];
        
    } else if ( [ResourceTypes.businessUser isEqualToString:resourceType] ) {
        
        return [ResourceMapper mapperForEntityName:[BusinessUser entityName]];
        
    } else if ( [ResourceTypes.contentItem isEqualToString:resourceType] ) {
        
        return [ResourceMapper mapperForEntityName:[ContentItem entityName]];
        
    }
        
    return nil;
}

+ (id)mapperForEntityName:(NSString *)entityName {
    return [[ManagedObjectResourceMapper alloc] initWithEntityName:entityName];    
}

- (id)objectFromResponse:(id)response {
//    [NSException raise:GenericException format:@"Shouldn't call this method on the base class."];
    return nil;
}

- (void)mapObject:(id)object fromResponse:(id)response {
    [NSException raise:GenericException format:@"Shouldn't call this method on the base class."];
}

- (id)resourceFromObject:(id)object {
    return nil;
}
- (void)mapObject:(id)object toResponse:(id)response {
    [NSException raise:GenericException format:@"Shouldn't call this method on the base class."];
}



@end
