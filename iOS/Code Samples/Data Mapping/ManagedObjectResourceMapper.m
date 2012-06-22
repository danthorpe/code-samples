//
//  ManagedObjectResourceMapper.m
//  InPrimroseHill
//
//  Created by Daniel Thorpe on 21/04/2012.
//  Copyright (c) 2012 Blinding Skies Limited. All rights reserved.
//

#import "ManagedObjectResourceMapper.h"

NSString * const ManagedObjectResourceMappingException = @"Managed Object Resource Mapping Exception";

const struct ManagedObjectMappingKeys ManagedObjectMappingKeys = {
    // Entity level
    .requiredTraits = @"requiredTraits",
    .optionalTraits = @"optionalTraits",
    .resourceTypeNameKey = @"resourceType",    
    // Attribute/Relationship Level    
    .resourceMapper = @"resourceMapper",
    .isRequired = @"isRequired",
    .propertyKey = @"propertyKey",
    .relationshipKey = @"relationshipKey",
    .identifyingKeys = @"identifyingKeys",
    .ignoreRelationshipKey = @"ignoreRelationshipKey",
    .transformablePropertyClassName = @"attributeValueClassName",
    .traitKey = @"traitKey"

};

@implementation ManagedObjectResourceMapper

@synthesize managedObjectContext = __managedObjectContext;
@synthesize entityName = __entityName;
@synthesize relationship = __relationship;
@synthesize includeTypeInResource = __includeTypeInResource;

- (id)initWithEntityName:(NSString *)entityName {
    self = [super init];
    if (self) {
        self.entityName = entityName;
        self.managedObjectContext = nil;
        self.includeTypeInResource = NO;
    }
    return self;
}

#pragma mark - Mapping from Resources

- (id)objectFromResponse:(id)response {
    NSAssert(self.entityName, @"Require an entity name to instantiate an object.");
    NSAssert(self.managedObjectContext, @"Require a managed object context name to instanciate an object.");
    
    // Define the object we're going to create/fetch
    id obj = nil;
    
    // Check to see if there is an identifier in the dictionary
    id identifier = [(NSDictionary *)response objectForKey:CommonResourceAttributes.identifierKey];
                             
    if (identifier) {        
        // Try to fetch an object from the context
        NSArray *objects = [self.managedObjectContext fetchObjectArrayForEntityName:self.entityName withPredicateFormat:@"identifier == %@", identifier];
        if ([objects count] == 1) {
            obj = [objects objectAtIndex:0];
        }
     }
     
     if (!obj) {
#ifdef DEBUG         
         DDLogVerbose(@"Inserting new %@ into MOC", self.entityName);
#endif         
         obj = [NSEntityDescription insertNewObjectForEntityForName:self.entityName inManagedObjectContext:self.managedObjectContext];
     }
     
    return obj;
}
 
- (void)mapObject:(id)object fromResponse:(id)response {
    NSAssert(self.entityName, @"Require an entity name to instanciate an object.");
    NSAssert(self.managedObjectContext, @"Require a managed object context name to instanciate an object.");

    // Get the entity
    NSEntityDescription *entity = [NSEntityDescription entityForName:self.entityName inManagedObjectContext:self.managedObjectContext];
    
    // Recast the response as a dictionary
    NSDictionary *dictionary = (NSDictionary *)response;
    
    for (NSPropertyDescription *property in entity) {
        
        // Determine if it is an attribute or a relationship
        if ([property isKindOfClass:[NSAttributeDescription class]]) {
            
            // Perform the mapping
            [self mapAttribute:(NSAttributeDescription *)property from:dictionary to:object];
            
        } else if ([property isKindOfClass:[NSRelationshipDescription class]]) {
            
            // Check to see if there is a custom mapper for this relationship
            NSString *customMapper = [property.userInfo objectForKey:ManagedObjectMappingKeys.resourceMapper];
            if (customMapper) {
                
                // Instantiate the custom mapper
                id mapper = [[NSClassFromString(customMapper) alloc] initWithEntityName:[((NSRelationshipDescription *)property).entity name]];
                [(ManagedObjectResourceMapper *)mapper setManagedObjectContext:self.managedObjectContext];                
                [(ManagedObjectResourceMapper *)mapper setRelationship:(NSRelationshipDescription *)property];
                [mapper mapRelationship:(NSRelationshipDescription *)property from:dictionary to:object];
                
            } else {
                
                // Perform the mapping
                [self mapRelationship:(NSRelationshipDescription *)property from:dictionary to:object];
                
            }            
        }
    }
}

- (void)mapAttribute:(NSAttributeDescription *)attribute from:(NSDictionary *)source to:(id)target {
    
    // Query the attribute's metadata to determine the key used in the remote dictionary
    NSString *key = [attribute.userInfo objectForKey:ManagedObjectMappingKeys.propertyKey];
    
    // And whether or not the metadata specifies that this attribute is required 
    NSNumber *isRequired = [attribute.userInfo objectForKey:ManagedObjectMappingKeys.isRequired];    
    
    // Get the attribute value
    id attributeValue = [source valueForKeyPath:key];
    
    if (!attributeValue && [isRequired boolValue]) {
        [NSException raise:ManagedObjectResourceMappingException 
                    format:@"Attribute: %@, Entity: %@ does not have an attribute value for key: %@ in response: %@", attribute.name, self.entityName, key, source];
    }    
    
    if (attributeValue && ![attributeValue isEqual:[NSNull null]]) {
        [self mapAttribute:attribute value:attributeValue to:target];
    }
}

- (void)mapAttribute:(NSAttributeDescription *)attribute value:(id)attributeValue to:(id)target {
    id value = nil; // Define the value
    
    // Check the attribute type
    switch (attribute.attributeType) {
        case NSDateAttributeType:
            value = [self mapDateAttribute:attribute from:attributeValue];
            break;
        case NSDoubleAttributeType:
            value = [self mapDoubleAttribute:attribute from:attributeValue];
            break;
        case NSDecimalAttributeType:
            value = [self mapDecimalAttribute:attribute from:attributeValue];
            break;            
        case NSFloatAttributeType:
            value = [self mapFloatAttribute:attribute from:attributeValue];
            break;
        case NSInteger16AttributeType:
        case NSInteger32AttributeType:
        case NSInteger64AttributeType:
            value = [self mapIntegerAttribute:attribute from:attributeValue];
            break;
        case NSBooleanAttributeType:
            value = [self mapBooleanAttribute:attribute from:attributeValue];
            break;
        case NSBinaryDataAttributeType:
            value = [self mapDataAttribute:attribute from:attributeValue];
            break;            
        case NSStringAttributeType:
            value = [self mapStringAttribute:attribute from:attributeValue];
            break;
        case NSTransformableAttributeType:
            value = [self mapTransformableAttribute:attribute from:attributeValue];
            break;        
        default:  
            [NSException raise:ManagedObjectResourceMappingException 
                        format:@"Attribute: %@ type: %d is not recognised.", attribute.name, attribute.attributeType];
            break;
    }
    
    NSAssert(value, @"We require a value to have been mapped, attribute: %@, input: %@", attribute.name, attributeValue);
    
    // Set the value on the target object
    [target setValue:value forKey:attribute.name];
}

- (void)mapRelationship:(NSRelationshipDescription *)relationship from:(NSDictionary *)source to:(id)target {
    if ([relationship isEqual:self.relationship.inverseRelationship]) return;
    
    // Query the attribute's metadata to determine the key used in the remote dictionary
    NSString *key = [relationship.userInfo objectForKey:ManagedObjectMappingKeys.relationshipKey];
    
    // And whether or not the metadata specifies that this attribute is required 
    NSNumber *isRequired = [relationship.userInfo objectForKey:ManagedObjectMappingKeys.isRequired];    
    
    // Get the relationship value from the dictionary
    id relationshipValue = [source valueForKeyPath:key];
    
    if (!relationshipValue && [isRequired boolValue]) {
        [NSException raise:ManagedObjectResourceMappingException 
                    format:@"Relationship: %@ does not have an relationship value for key: %@ in response: %@", relationship.name, key, source];
    }
    
    if ( relationshipValue && ![relationshipValue isEqual:[NSNull null]] ) {
        [self mapRelationship:relationship value:relationshipValue to:target];
    }
}

- (void)mapRelationship:(NSRelationshipDescription *)relationship value:(id)relationshipValue to:(id)target {
    NSParameterAssert(relationship);
    NSParameterAssert(relationshipValue);
    NSParameterAssert(target);
    
    // Check the response value type
    if ([relationshipValue isKindOfClass:[NSDictionary class]]) {
    
        [self mapObjectForRelationship:relationship with:(NSDictionary *)relationshipValue to:target];
        
    } else if ([relationshipValue isKindOfClass:[NSNumber class]]) {

        [self mapLocalObjectForRelationship:relationship with:relationshipValue to:target];
    
    } else if ([relationshipValue isKindOfClass:[NSString class]]) {
        
        [self mapLocalObjectForRelationship:relationship with:relationshipValue to:target];
        
    } else if ([relationshipValue isKindOfClass:[NSArray class]]) {
        // We might have an array of NSDictionaries
        
        // Recast the relationship value
        NSArray *objs = (NSArray *)relationshipValue;
        
        for (id relationshipValueItem in objs) {
            if ([relationshipValueItem isKindOfClass:[NSDictionary class]]) {
                // Map the dictionary
                [self mapObjectForRelationship:relationship with:(NSDictionary *)relationshipValueItem to:target];
            } else if ([relationshipValueItem isKindOfClass:[NSNumber class]]) {
                [NSException raise:ManagedObjectResourceMappingException 
                            format:@"Relationship: %@ requires a dependent webservice call which is not supported.", relationship.name];
            }            
        }            
    } else {
        [NSException raise:ManagedObjectResourceMappingException 
                    format:@"Relationship: %@ has an unknow value: %@.", relationship.name, relationshipValue];
    }
}

- (void)mapObjectForRelationship:(NSRelationshipDescription *)relationship with:(NSDictionary *)source to:(id)target {

    NSParameterAssert(relationship);
    NSParameterAssert(source);
    NSParameterAssert(target);

    // Get a resource mapper for this type
    id resourceMapper = [ResourceMapper mapperForEntityName:relationship.destinationEntity.name];
    
    // Set the MOC if it is set
    if ( self.managedObjectContext && [resourceMapper respondsToSelector:@selector(setManagedObjectContext:)] ) {
        [resourceMapper setManagedObjectContext:self.managedObjectContext];
    }
    
    // Ignore the inverse relationship if possible
    if ([resourceMapper respondsToSelector:@selector(setRelationship:)]) {
        [resourceMapper setRelationship:relationship];
    }
    
    // Get the object, first from the target.
    // This is a bit complicated, we're gonna have to search
    // our connected object graph, then the whole context
    // and eventually create a new object.
    id obj = [self objectForRelationship:relationship fromTarget:target withResource:source];
    
    if (!obj) {
        obj = [resourceMapper objectFromResponse:source];
    }
    
    if (obj) {
        // Perform the mapping
        [resourceMapper mapObject:obj fromResponse:source];
        
        // Set the relationship
        [self setRelationship:relationship with:obj to:target];
    }
}

- (void)mapLocalObjectForRelationship:(NSRelationshipDescription *)relationship with:(id)identifier to:(id)target {
    NSParameterAssert(relationship);
    NSParameterAssert(identifier);
    NSParameterAssert(target);

    // Query Core Data for this object
    id obj = [self.managedObjectContext firstObjectForEntityName:[relationship.destinationEntity name] withPredicateFormat:@"identifier == %@", identifier];
    
    if (obj) {
        // Set the relationship
        [self setRelationship:relationship with:obj to:target];
    }
}

- (id)objectForRelationship:(NSRelationshipDescription *)relationship fromTarget:(id)target withResource:(NSDictionary *)resource {

    // Check to see if the relationship is a to-many
    if (relationship.isToMany) {

        
    } else {
        // Return the object
        return [target valueForKey:relationship.name];        
    }
    
    return nil;
}

- (void)setRelationship:(NSRelationshipDescription *)relationship with:(id)obj to:(id)target {
    
    // Set the relationship
    if (relationship.isToMany) {
        // Add the object        
        if (relationship.isOrdered) {
            [[target mutableOrderedSetValueForKey:relationship.name] addObject:obj];
        } else {
            [[target mutableSetValueForKey:relationship.name] addObject:obj];
        }
        
    } else {
        [target setValue:obj forKey:relationship.name];
    }
    
    // Set the inverse relationship
    if (relationship.inverseRelationship.isToMany) {
        // Add the object
        if (relationship.inverseRelationship.isOrdered) {
            [[obj mutableOrderedSetValueForKey:relationship.inverseRelationship.name] addObject:target];
        } else {
            [[obj mutableSetValueForKey:relationship.inverseRelationship.name] addObject:target];
        }
    } else {
        [obj setValue:target forKey:relationship.inverseRelationship.name];
    }
}


- (NSEntityDescription *)entityForRelationship:(NSRelationshipDescription *)relationship from:(NSDictionary *)source {
    
    // Get the destination entity
    NSEntityDescription *entity = [relationship destinationEntity];
    
    // Get the entity name as given by the response
    NSString *entityName = [source objectForKey:CommonResourceAttributes.typeKey];
    if (entityName) {
        NSEntityDescription *subentity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self.managedObjectContext];        
        if ([subentity isKindOfEntity:entity]) {
            return subentity;
        } else {
            [NSException raise:ManagedObjectResourceMappingException 
                        format:@"Relationship: %@ maps to entity: %@: but response returns type: %@", relationship.name, entity.name, entityName];
            return nil;
        }
    }
    return entity;
}

#pragma mark - Specific mappings for attribute types

- (NSDate *)mapDateAttribute:(NSAttributeDescription *)attribute from:(id)obj {
    // We need to have a special treatment of date types
    if ([obj isKindOfClass:[NSNumber class]]) {
        // We expect seconds since UNIX epoch (GMT)
        return [NSDate dateWithTimeIntervalSince1970:[obj doubleValue]];
    } else if ([obj isKindOfClass:[NSDate class]]) {
        return obj;
    }
    [NSException raise:ManagedObjectResourceMappingException format:@"Attribute: %@ maps to a date property: %@, which is malformed", attribute.name, obj];
    return nil;
}

- (NSNumber *)mapDateToNumber:(NSDate *)date {
    return [NSNumber numberWithDouble:[date timeIntervalSince1970]];
}

- (NSNumber *)mapDoubleAttribute:(NSAttributeDescription *)attribute from:(id)obj {
    // This should be an NSNumber
    if ([obj isKindOfClass:[NSNumber class]]) {
        return obj;
    } else if ([obj isKindOfClass:[NSString class]]) {
        return [NSNumber numberWithDouble:[(NSString *)obj doubleValue]];
    }
    [NSException raise:ManagedObjectResourceMappingException format:@"Attribute: %@ maps to a double property: %@, which is malformed", attribute.name, obj];
    return nil;
}

- (NSNumber *)mapFloatAttribute:(NSAttributeDescription *)attribute from:(id)obj {
    // This should be an NSNumber
    if ([obj isKindOfClass:[NSNumber class]]) {
        return obj;
    } else if ([obj isKindOfClass:[NSString class]]) {
        return [NSNumber numberWithFloat:[(NSString *)obj floatValue]];
    }
    [NSException raise:ManagedObjectResourceMappingException format:@"Attribute: %@ maps to a float property: %@, which is malformed", attribute.name, obj];
    return nil;
}

- (NSNumber *)mapIntegerAttribute:(NSAttributeDescription *)attribute from:(id)obj {
    // This should be an NSNumber
    if ([obj isKindOfClass:[NSNumber class]]) {
        return obj;
    } else if ([obj isKindOfClass:[NSString class]]) {
        return [NSNumber numberWithInteger:[(NSString *)obj integerValue]];
    }
    [NSException raise:ManagedObjectResourceMappingException format:@"Attribute: %@ maps to an integer property: %@, which is malformed", attribute.name, obj];
    return nil;
}

- (NSNumber *)mapBooleanAttribute:(NSAttributeDescription *)attribute from:(id)obj {
    // This should be an NSNumber
    if ([obj isKindOfClass:[NSNumber class]]) {
        return obj;
    } else if ([obj isKindOfClass:[NSString class]]) {
        return [NSNumber numberWithBool:[(NSString *)obj boolValue]];
    }
    [NSException raise:ManagedObjectResourceMappingException format:@"Attribute: %@ maps to a boolean property: %@, which is malformed", attribute.name, obj];
    return nil;
}

- (NSDecimalNumber *)mapDecimalAttribute:(NSAttributeDescription *)attribute from:(id)obj {
    // This should be an NSDecimalNumber
    if ([obj isKindOfClass:[NSDecimalNumber class]]) {
        return obj;
    } else if ([obj isKindOfClass:[NSString class]]) {
        return [NSDecimalNumber decimalNumberWithString:(NSString *)obj];
    }
    [NSException raise:ManagedObjectResourceMappingException format:@"Attribute: %@ maps to a decimal property: %@, which is malformed", attribute.name, obj];
    return nil;
}

- (NSData *)mapDataAttribute:(NSAttributeDescription *)attribute from:(id)obj {
    // This should be an NSData
    if ([obj isKindOfClass:[NSData class]]) {
        return obj;
    } else if ([obj isKindOfClass:[NSString class]]) {
        return [(NSString *)obj dataUsingEncoding:NSUTF8StringEncoding];
    }
    [NSException raise:ManagedObjectResourceMappingException format:@"Attribute: %@ maps to a data: %@, which is malformed", attribute.name, obj];
    return nil;
}

- (NSString *)mapStringAttribute:(NSAttributeDescription *)attribute from:(id)obj {
    if ([obj isKindOfClass:[NSString class]]) {
        return obj;
    }
    [NSException raise:ManagedObjectResourceMappingException format:@"Attribute: %@ maps to a string: %@, which is malformed", attribute.name, obj];
    return nil;
}

- (id)mapTransformableAttribute:(NSAttributeDescription *)attribute from:(id)obj {
    // Check to see if the attribute has a Transformable property class name
    NSString *transformablePropertyClassName = [attribute.userInfo objectForKey:ManagedObjectMappingKeys.transformablePropertyClassName];
    if (!transformablePropertyClassName) {
        [NSException raise:ManagedObjectResourceMappingException format:@"Attribute: %@ is a transformable attribute, yet doesn't have a class name specified in its metadata", attribute.name];
    }
    
    if ([transformablePropertyClassName isEqualToString:@"NSURL"]) {
        return [self mapURLAttribute:attribute from:obj];
    } else if ([transformablePropertyClassName isEqualToString:@"NSMutableArray"]) {
        return [self mapMutableArrayAttribute:attribute from:obj];
    } else if ([transformablePropertyClassName isEqualToString:@"NSMutableDictionary"]) {
        return [self mapMutableDictionaryAttribute:attribute from:obj];
    }
    
    [NSException raise:ManagedObjectResourceMappingException format:@"Attribute: %@ mapping of %@ type is not implemented.", attribute.name, transformablePropertyClassName];
    return nil;
}

- (id)mapTransformableAttributeToFoundationObject:(NSAttributeDescription *)attribute from:(id)obj {
    // Check to see if the attribute has a Transformable property class name
    NSString *transformablePropertyClassName = [attribute.userInfo objectForKey:ManagedObjectMappingKeys.transformablePropertyClassName];
    if (!transformablePropertyClassName) {
        [NSException raise:ManagedObjectResourceMappingException format:@"Attribute: %@ is a transformable attribute, yet doesn't have a class name specified in its metadata", attribute.name];
    }

    if ([transformablePropertyClassName isEqualToString:@"NSURL"]) {
        return [self mapURLToString:(NSURL *)obj];
    } else if ([transformablePropertyClassName isEqualToString:@"NSMutableArray"]) {
        return obj;
    } else if ([transformablePropertyClassName isEqualToString:@"NSMutableDictionary"]) {
        return obj;
    }
    
    [NSException raise:ManagedObjectResourceMappingException format:@"Attribute: %@ mapping of %@ type is not implemented.", attribute.name, transformablePropertyClassName];
    return nil;    
}


#pragma mark - Data mappings for transformable attributes

- (NSURL *)mapURLAttribute:(NSAttributeDescription *)attribute from:(id)obj {
    if ([obj isKindOfClass:[NSString class]]) {
        return [NSURL URLWithString:obj];
    } else {
        return [NSURL URLWithString:[(NSArray *)obj objectAtIndex:0]];
    }
    [NSException raise:ManagedObjectResourceMappingException format:@"Attribute: %@ maps to a URL: %@, which is malformed", attribute.name, obj];
    return nil;
}

- (NSString *)mapURLToString:(NSURL *)url {
    return [url absoluteString];
}

- (NSMutableArray *)mapMutableArrayAttribute:(NSAttributeDescription *)attribute from:(id)obj {
    if ([obj isKindOfClass:[NSMutableArray class]]) {
        return obj;
    } else if ([obj isKindOfClass:[NSArray class]]) {
        return [NSMutableArray arrayWithArray:(NSArray *)obj];
    }
    [NSException raise:ManagedObjectResourceMappingException format:@"Attribute: %@ maps to a NSMutableArray: %@, which is malformed", attribute.name, obj];
    return nil;
}

- (NSMutableDictionary *)mapMutableDictionaryAttribute:(NSAttributeDescription *)attribute from:(id)obj {
    if ([obj isKindOfClass:[NSMutableDictionary class]]) {
        return (NSMutableDictionary *)obj;
    } else if ([obj isKindOfClass:[NSDictionary class]]) {
        return [NSMutableDictionary dictionaryWithDictionary:obj];
    }
    [NSException raise:ManagedObjectResourceMappingException format:@"Attribute: %@ maps to a NSMutableDictionary: %@, which is malformed", attribute.name, obj];
    return nil;
}



#pragma mark - Mapping to Resources

- (id)resourceFromObject:(id)object {
    
    if (self.includeTypeInResource) {
        NSAssert(self.entityName, @"Require an entity name to instanciate an object.");
        NSAssert(self.managedObjectContext, @"Require a managed object context name to instanciate an object.");
        
        // Get the entity
        NSEntityDescription *entity = [NSEntityDescription entityForName:self.entityName inManagedObjectContext:self.managedObjectContext];
        
        // Check to see if the entity metadata has a type key
        NSString *type = [entity.userInfo objectForKey:ManagedObjectMappingKeys.resourceTypeNameKey];
        if (!type) {
            type = [[(NSManagedObject *)object entity] name];
        }
        
        return [NSMutableDictionary dictionaryWithObjectsAndKeys:
                type, CommonResourceAttributes.typeKey, 
                nil];
    }
    
    return [NSMutableDictionary dictionary];    
}

- (void)mapObject:(id)object toResponse:(id)response {
    NSAssert(self.entityName, @"Require an entity name to instanciate an object.");
    NSAssert(self.managedObjectContext, @"Require a managed object context name to instanciate an object.");
    
    // Cast to a managed object
    NSManagedObject *managedObject = (NSManagedObject *)object;
    
    // Get the entity
    NSEntityDescription *entity = [NSEntityDescription entityForName:self.entityName inManagedObjectContext:self.managedObjectContext];
    
    // Recast the response as a dictionary
    NSMutableDictionary *dictionary = (NSMutableDictionary *)response;
    
    // Iterate through the properties
    for (NSPropertyDescription *property in entity) {
        
        // Determine if it is an attribute or a relationship
        if ([property isKindOfClass:[NSAttributeDescription class]]) {
            
            // Perform the mapping
            [self mapAttribute:(NSAttributeDescription *)property to:dictionary from:managedObject];
            
        } else if ([property isKindOfClass:[NSRelationshipDescription class]]) {
            
            // Check to see if there is a custom mapper for this relationship
            NSString *customMapper = [property.userInfo objectForKey:ManagedObjectMappingKeys.resourceMapper];
            if (customMapper) {
                
                // Instantiate the custom mapper
                id mapper = [[NSClassFromString(customMapper) alloc] initWithEntityName:[((NSRelationshipDescription *)property).entity name]];
                [(ManagedObjectResourceMapper *)mapper setManagedObjectContext:self.managedObjectContext];                
                [(ManagedObjectResourceMapper *)mapper setRelationship:(NSRelationshipDescription *)property];
                [mapper mapRelationship:(NSRelationshipDescription *)property to:dictionary from:object];
                
            } else {
                
                // Perform the mapping
                [self mapRelationship:(NSRelationshipDescription *)property to:dictionary from:object];

            }
        }
    }
}

- (void)mapAttribute:(NSAttributeDescription *)attribute to:(NSMutableDictionary *)target from:(id)source {
    
    // Query the attribute's metadata to determine the key used in the remote dictionary
    NSString *key = [attribute.userInfo objectForKey:ManagedObjectMappingKeys.propertyKey];    
    
    // Check to see if we've got a value for this attribute
    id attributeValue = [source valueForKey:attribute.name];
        
    if (attributeValue && ![attributeValue isEqual:[NSNull null]] && key) {
        
        id value = nil; // Define the value
        
        // Check the attribute type
        switch (attribute.attributeType) {
            case NSDateAttributeType:
                value = [self mapDateToNumber:(NSDate *)attributeValue];
                break;
            case NSDoubleAttributeType:
            case NSDecimalAttributeType:                
            case NSFloatAttributeType:
            case NSInteger16AttributeType:
            case NSInteger32AttributeType:
            case NSInteger64AttributeType:
            case NSBooleanAttributeType:
            case NSBinaryDataAttributeType:                
            case NSStringAttributeType:
                value = attributeValue;
                break;
            case NSTransformableAttributeType:
                value = [self mapTransformableAttributeToFoundationObject:attribute from:attributeValue];
                break;        
            default:  
                [NSException raise:ManagedObjectResourceMappingException 
                            format:@"Attribute: %@ type: %d is not recognised.", attribute.name, attribute.attributeType];
                break;
        }
        
        NSAssert(value, @"We require a value to have been mapped, attribute: %@, input: %@", attribute.name, attributeValue);
        
        // Set the value on the target object
        [target setValue:value forKey:key];
    }
}

- (void)mapRelationship:(NSRelationshipDescription *)relationship to:(NSMutableDictionary *)target from:(id)source {
    if ([relationship isEqual:self.relationship.inverseRelationship]) return;
    
    // Check to see if this relationship should not be included
    NSNumber *ignore = [relationship.userInfo objectForKey:ManagedObjectMappingKeys.ignoreRelationshipKey];

    if (ignore && [ignore boolValue]) return;
    
    // Query the attribute's metadata to determine the key used in the remote dictionary
    NSString *key = [relationship.userInfo objectForKey:ManagedObjectMappingKeys.relationshipKey];

    // Get the relationship value from the dictionary
    id relationshipValue = [source valueForKey:relationship.name];    
    
    if ( relationshipValue && ![relationshipValue isEqual:[NSNull null]] && key ) {

        if ( relationship.isToMany ) {
            // Map the items in the to-many set
            NSMutableArray *array = [NSMutableArray arrayWithCapacity:10];
            for (id relationshipItemValue in relationshipValue) {
                // Map the item
                NSDictionary *subItem = [self mapResourceForRelationship:relationship from:relationshipItemValue];
                // Add it to the array
                [array addObject:subItem];
            }
            
            // Set the sub-resource
            [target setObject:array forKey:key];

        } else {
            // Get the sub resource
            NSDictionary *sub = [self mapResourceForRelationship:relationship from:relationshipValue];
            
            // Set the sub-resource
            [target setObject:sub forKey:key];
        }
    }
    
}

- (NSDictionary *)mapResourceForRelationship:(NSRelationshipDescription *)relationship from:(id)source {
    NSParameterAssert(relationship);
    NSParameterAssert(source);

    // Get a resource mapper for this type
    id resourceMapper = [ResourceMapper mapperForEntityName:relationship.destinationEntity.name];
    
    // Set the MOC if it is set
    if ( self.managedObjectContext && [resourceMapper respondsToSelector:@selector(setManagedObjectContext:)] ) {
        [resourceMapper setManagedObjectContext:self.managedObjectContext];
    }
    
    // Ignore the inverse relationship if possible
    if ([resourceMapper respondsToSelector:@selector(setRelationship:)]) {
        [resourceMapper setRelationship:relationship];
    }
    
    // Set the include type
    if ([resourceMapper respondsToSelector:@selector(setIncludeTypeInResource:)]) {
        [resourceMapper setIncludeTypeInResource:self.includeTypeInResource];
    }
    
    // Get the resource
    NSMutableDictionary *resource = [resourceMapper resourceFromObject:source];

    // Perform the mapping
    [resourceMapper mapObject:source toResponse:resource];
    
    // Return the resource
    return resource;
}

@end
