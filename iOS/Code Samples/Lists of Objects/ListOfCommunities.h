//
//  ListOfSocialObjects.h
//  Talent
//
//  Created by Daniel Thorpe on 16/12/2011.
//  Copyright (c) 2011 Brave New Talent. All rights reserved.
//

#import "BNTTableViewController.h"

@class ListOfCommunities;

/// Define a block type which accepts an array and error
typedef void(^NSArrayBlock)(NSArray *results, NSError *error);

/// Define a block type which accepts a NSRange and `NSArrayBlock`.
typedef void(^CommunityDataSource)(NSManagedObjectContext *context, NSRange objectsInRange, NSArrayBlock completion);

typedef enum _TableViewRefreshDataMethod {
    kTableViewRefreshDataReplaceMethod,
    kTableViewRefreshDataAppendMethod
} TableViewRefreshDataMethod;

@protocol ListOfCommunitiesDataSource <NSObject>

@optional
- (void)listOfCommunities:(ListOfCommunities *)list 
     refreshObjectInRange:(NSRange)range 
   inManagedObjectContext:(NSManagedObjectContext *)context 
               completion:(WebserviceSaveCompletionBlock)completion;

@optional
- (NSEntityDescription *)listOfCommunities:(ListOfCommunities *)list 
   entityDescriptionInManagedObjectContext:(NSManagedObjectContext *)context;

@end

@protocol ListOfCommunitiesDelegate <NSObject>

@optional
- (void)listOfCommunities:(ListOfCommunities *)list 
       didSelectCommunity:(Community *)community;

@end

/**
 A table view controller to display an arbitrary list of social objects.
 */
@interface ListOfCommunities : UITableViewController <NSFetchedResultsControllerDelegate>

/// An identifier, so that the same object can be a data source for multiple lists
@property (nonatomic) NSUInteger identifier;

/// A Managed Object Context which `SocialObjects` get fetched into.
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

/// A filter predicate to filter SocialObjects
@property (strong, nonatomic) NSPredicate *filterPredicate;

/// A fetched results controller
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

/// The refreshing state
@property (nonatomic, readonly) BOOL isRefreshing;

/// The paging state
@property (nonatomic) BOOL paginationEnabled;
@property (nonatomic, readonly) BOOL isPaging;

/// The datasource
@property (weak, nonatomic) id <ListOfCommunitiesDataSource> datasource;

/// The delegate
@property (weak, nonatomic) id <ListOfCommunitiesDelegate> delegate;

/**
 The total number of social objects to display, required to put a limit
 on paging
 */
@property (nonatomic) NSUInteger totalNumberOfCommunities;

/**
 Initialize the table view controller with a list of social objects 
 */
- (id)initWithListOfCommunities:(NSArray *)communities;


@end
