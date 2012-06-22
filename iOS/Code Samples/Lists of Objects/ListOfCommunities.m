//
//  ListOfSocialObjects.m
//  Talent
//
//  Created by Daniel Thorpe on 16/12/2011.
//  Copyright (c) 2011 Brave New Talent. All rights reserved.
//

#import "CommunityViewController.h"
#import "ListOfCommunities.h"
#import "UIScrollView+PullToRefresh.h"

#define kActivityIndicatorViewTag 826
#define kPageSize BNTWebserviceDefaultPageSize

typedef enum _ListOfCommunitiesSections {
    kListOfCommunitiesSection = 0,
    kListOfCommunitiesLoadingSection    
} ListOfCommunitiesSections;

@interface ListOfCommunities ()

/// The refreshing state
@property (nonatomic) BOOL isRefreshing;

/// The pagin state
@property (nonatomic) BOOL isPaging;

// Properties
@property (nonatomic) NSRange rangeOfNextObjects;

// Common initializer
- (void)commonInit;

// Cell configuration
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

// Actions
- (IBAction)dismiss:(id)sender;

// Refreshing
- (void)refresh:(WebserviceSaveCompletionBlock)completion;

// Paging
- (void)page:(WebserviceSaveCompletionBlock)completion;

@end


@implementation ListOfCommunities

// Public
@synthesize identifier = _identifier;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize filterPredicate = _filterPredicate;
@synthesize datasource = _datasource;
@synthesize delegate = _delegate;
@synthesize totalNumberOfCommunities = _totalNumberOfSocialObjects;
@synthesize paginationEnabled = _paginationEnabled;

// Private
@synthesize isRefreshing = _isRefreshing;
@synthesize isPaging = _isPaging;
@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize rangeOfNextObjects = _rangeOfNextObjects;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:@"ListOfSocialObjects" bundle:nil];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)init {
    self = [super initWithNibName:@"ListOfSocialObjects" bundle:nil];
    if (self) {
        [self commonInit];
    }
    return self;    
}

- (id)initWithListOfCommunities:(NSArray *)communities {
    self = [self init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    self.paginationEnabled = NO;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // If the view controller is presented modally, then put
    // a cancel button in the top right to dismiss it.
    if ([self.parentViewController isEqual:self.presentingViewController.presentedViewController]) {
        // Add a cancel button
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismiss:)];
    }    

    // Pull down to refresh
    self.tableView.pullDownToRefreshEnabled = YES;
    
    [self refresh:^(NSSet *objects, NSError *error) {
        
        // Tell the pull to refresh view that we've finished loading
        [self.tableView.pullToRefresh dataSourceDidFinishLoading:self.tableView];
        
        // On completion we want to stop refreshing
        self.isRefreshing = NO;            
    }];
    
    // Set that we're refreshing
    self.isRefreshing = YES;            
}

- (void)viewDidUnload {    
    [super viewDidUnload];
    DDLogInfo(@"List Of Social Objects: %@", NSStringFromSelector(_cmd));
    // Release any retained subviews of the main view.
    
    self.managedObjectContext = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Actions

- (IBAction)dismiss:(id)sender {
    [self.presentingViewController dismissModalViewControllerAnimated:YES];
}

#pragma mark - Refreshing

- (void)refresh:(WebserviceSaveCompletionBlock)completion {
    if (self.datasource && [self.datasource respondsToSelector:@selector(listOfSocialObjects:refreshObjectInRange:inManagedObjectContext:completion:)]) {
        
        // Work our the current range
        NSUInteger numberOfObjects = [self.tableView numberOfRowsInSection:0];
        
        [self.datasource listOfCommunities:self 
                        refreshObjectInRange:NSMakeRange(0, MAX(numberOfObjects, kPageSize)) 
                      inManagedObjectContext:self.managedObjectContext 
                                  completion:completion];
    }
}

#pragma mark - Paging

- (void)page:(WebserviceSaveCompletionBlock)completion {
    if (self.datasource && [self.datasource respondsToSelector:@selector(listOfSocialObjects:refreshObjectInRange:inManagedObjectContext:completion:)]) {
        
        // Work our the current range
        NSUInteger numberOfObjects = [self.tableView numberOfRowsInSection:0];
        
        [self.datasource listOfCommunities:self 
                        refreshObjectInRange:NSMakeRange(numberOfObjects, kPageSize) 
                      inManagedObjectContext:self.managedObjectContext 
                                  completion:completion];
    }
}

#pragma mark - Dynamic Properties

- (NSFetchedResultsController *)fetchedResultsController {
    // If the FRC has already been created, just return it here
    if (_fetchedResultsController) return _fetchedResultsController;
    
    // Create a NSFetchRequest
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    // Check to see if we have a datasource and it can give use the EntityDescription
    if (self.datasource && [self.datasource respondsToSelector:@selector(listOfSocialObjects:entityDescriptionInManagedObjectContext:)]) {
        // Set a custom entity
        fetchRequest.entity = [self.datasource listOfCommunities:self entityDescriptionInManagedObjectContext:self.managedObjectContext];
    } else {
        // Set the entity to SocialObject (this will return any sub-entities)
        fetchRequest.entity = [Community entityInManagedObjectContext:self.managedObjectContext];
    }
    
    // Set the sort descriptors
    fetchRequest.sortDescriptors = [NSArray arrayWithObjects:
                                    [[NSSortDescriptor alloc] initWithKey:CommunityAttributes.displayName ascending:YES], 
                                    nil];
    
    // Set a filter predicate if there is one
    if (self.filterPredicate) {
        fetchRequest.predicate = self.filterPredicate;
    }
    
    // Create a NSFetchedResultsController
    NSFetchedResultsController *aFRC = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    
    // Set ourselves as the delegate
    aFRC.delegate = self;
    
    // Execute a fetch
    NSError *error = nil;
    BOOL success = [aFRC performFetch:&error];
    if (!success && error) {
        DDLogError(@"Something went horribly wrong: %@", [error userInfo]);
        abort();
    }
    
    // Store it in the property
    self.fetchedResultsController = aFRC;
    
    // Return it
    return _fetchedResultsController;
}

#pragma mark - NSFetchedResultsControllerDelegate Methods

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {

    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {

    UITableView *tableView = self.tableView;
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath]
                    atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    NSUInteger numberOfSectionsFromFRC = [[self.fetchedResultsController sections] count];
    
    return self.paginationEnabled ? 1 + numberOfSectionsFromFRC : numberOfSectionsFromFRC;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    // Return the number of rows in the section.
    if (section == kListOfCommunitiesSection) {

        // Get the section info object out of the FRC
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
        
        // Query it to get the number of objects
        return [sectionInfo numberOfObjects];

    } else {

        return self.paginationEnabled ? 1 : 0;

    }

    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *GenericCellIdentifier = @"Cell";
    
    // Dequeue a cell
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:GenericCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:GenericCellIdentifier];
    }

    // Configure the cell...
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {

    if (indexPath.section == kListOfCommunitiesSection) {
        // Get the social object out of the data
        Community *community = [self.fetchedResultsController objectAtIndexPath:indexPath];
        cell.textLabel.text = community.displayName;
        
        // Get the avatar
        [cell.imageView setImageWithURL:[community.avatarUrl modifyAvatarURLForSize:kBNTAvatarSmallSize] 
                       placeholderImage:[community avatarPlaceholderImage] 
                                options:BNTRemoteImageViewOptionsNone];

    } else {
        
        if (self.paginationEnabled && indexPath.section == kListOfCommunitiesLoadingSection && indexPath.row == 0) {
            cell.textLabel.text = NSLocalizedString(@"Load More", @"Text to indicate more results are available");
            cell.textLabel.textAlignment = UITextAlignmentCenter;
            cell.textLabel.textColor = BNTBlueColor;
        }        
    }
}

#pragma mark - UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    if (indexPath.section == kListOfCommunitiesSection) {

        // Get the object at the index path
        Community *community = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(listOfSocialObjects:didSelectCommunity:)]) {
            
            // Call the delegate method
            [self.delegate listOfCommunities:self didSelectCommunity:community];
            
        } else {
            
            // Create a community view controller
            CommunityViewController *vc = [[CommunityViewController alloc] init];
            
            // Configure it
            vc.managedObjectContext = self.managedObjectContext;
            vc.community = community;
                
            // Push the view controller
            [self.navigationController pushViewController:vc animated:YES];

        }
        
    } else if (self.paginationEnabled && indexPath.section == kListOfCommunitiesLoadingSection && indexPath.row == 0) {        
        if (!self.isPaging) {
            [self page:^(NSSet *objects, NSError *error) {
                self.isPaging = YES;
            }];
            self.isPaging = YES;
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    }
}

#pragma mark - BNTPullToRefreshDelegate Methods

- (BOOL)pullToRefreshDataSourceIsLoading:(BNTPullToRefresh *)view {
	return self.isRefreshing;
}

- (BNTPullToRefreshState)pullToRefresh:(BNTPullToRefresh *)view didTriggerRefreshOnScrollView:(UIScrollView *)scrollView {
    if (!self.isRefreshing) {
        // Refresh
        [self refresh:^(NSSet *objects, NSError *error) {
            // On completion we want to stop refreshing
            self.isRefreshing = NO;
            // Tell the pull to refresh view that we've finished loading
            [view dataSourceDidFinishLoading:self.tableView];
        }];
        
        // Set that we're refreshing
        self.isRefreshing = YES;        
    }	
    return kBNTPullToRefreshLoading;
}

@end
