//
//  ManagedObjectResourceMapper.h
//  InPrimroseHill
//
//  Created by Daniel Thorpe on 21/04/2012.
//  Copyright (c) 2012 Blinding Skies Limited. All rights reserved.
//

#import "ResourceMapper.h"

// Exception name
extern NSString * const ManagedObjectResourceMappingException;

// Core Data model metadata keys
extern const struct ManagedObjectMappingKeys {
    // Entity level
    __unsafe_unretained NSString *requiredTraits;
    __unsafe_unretained NSString *optionalTraits;
    __unsafe_unretained NSString *resourceTypeNameKey;    
    // Attribute/Relationship Level
    __unsafe_unretained NSString *resourceMapper;
    __unsafe_unretained NSString *isRequired;
    __unsafe_unretained NSString *propertyKey;
    __unsafe_unretained NSString *relationshipKey;
    __unsafe_unretained NSString *identifyingKeys;
    __unsafe_unretained NSString *ignoreRelationshipKey;
    __unsafe_unretained NSString *transformablePropertyClassName;
    __unsafe_unretained NSString *traitKey;
} ManagedObjectMappingKeys;

@interface ManagedObjectResourceMapper : ResourceMapper

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSString *entityName;
@property (strong, nonatomic) NSRelationshipDescription *relationship;
@property (nonatomic) BOOL includeTypeInResource;

/// Default constructor
- (id)initWithEntityName:(NSString *)entityName;

#pragma mark - Mapping

- (void)mapAttribute:(NSAttributeDescription *)attribute 
                from:(NSDictionary *)source 
                  to:(id)target;

- (void)mapAttribute:(NSAttributeDescription *)attribute 
               value:(id)attributeValue 
                  to:(id)target;

- (void)mapRelationship:(NSRelationshipDescription *)relationship 
                   from:(NSDictionary *)source 
                     to:(id)target;

- (void)mapRelationship:(NSRelationshipDescription *)relationship 
                  value:(id)relationshipValue 
                     to:(id)target;

- (void)mapObjectForRelationship:(NSRelationshipDescription *)relationship 
                            with:(NSDictionary *)source 
                              to:(id)target;

- (void)mapLocalObjectForRelationship:(NSRelationshipDescription *)relationship 
                                 with:(id)identifier 
                                   to:(id)target;

- (id)objectForRelationship:(NSRelationshipDescription *)relationship
                 fromTarget:(id)target 
               withResource:(NSDictionary *)resource; 

- (void)setRelationship:(NSRelationshipDescription *)relationship 
                   with:(id)obj 
                     to:(id)target;

- (NSEntityDescription *)entityForRelationship:(NSRelationshipDescription *)relationship 
                                          from:(NSDictionary *)source;

#pragma mark - Specific mappings for attribute types

- (NSDate *)mapDateAttribute:(NSAttributeDescription *)attribute from:(id)obj;
- (NSNumber *)mapDateToNumber:(NSDate *)date;
- (NSNumber *)mapDoubleAttribute:(NSAttributeDescription *)attribute from:(id)obj;
- (NSNumber *)mapFloatAttribute:(NSAttributeDescription *)attribute from:(id)obj;
- (NSNumber *)mapIntegerAttribute:(NSAttributeDescription *)attribute from:(id)obj;
- (NSNumber *)mapBooleanAttribute:(NSAttributeDescription *)attribute from:(id)obj;
- (NSDecimalNumber *)mapDecimalAttribute:(NSAttributeDescription *)attribute from:(id)obj;
- (NSData *)mapDataAttribute:(NSAttributeDescription *)attribute from:(id)obj;
- (NSString *)mapStringAttribute:(NSAttributeDescription *)attribute from:(id)obj;
- (id)mapTransformableAttribute:(NSAttributeDescription *)attribute from:(id)obj;
- (id)mapTransformableAttributeToFoundationObject:(NSAttributeDescription *)attribute from:(id)obj;

#pragma mark - Data mappings for transformable attributes
- (NSURL *)mapURLAttribute:(NSAttributeDescription *)attribute from:(id)obj;
- (NSString *)mapURLToString:(NSURL *)url;
- (NSMutableArray *)mapMutableArrayAttribute:(NSAttributeDescription *)attribute from:(id)obj;
- (NSMutableDictionary *)mapMutableDictionaryAttribute:(NSAttributeDescription *)attribute from:(id)obj;


- (void)mapAttribute:(NSAttributeDescription *)attribute 
                  to:(NSMutableDictionary *)target 
                from:(id)source;

- (void)mapRelationship:(NSRelationshipDescription *)relationship 
                     to:(NSMutableDictionary *)target 
                   from:(id)source;

- (NSDictionary *)mapResourceForRelationship:(NSRelationshipDescription *)relationship 
                            from:(id)source;
@end
