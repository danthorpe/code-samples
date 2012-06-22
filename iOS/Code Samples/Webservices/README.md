Webservices
-----------

This is a subclass of AFNetworking's AFHTTPClient class. AFNetworking is a popular library on iOS for performing asynchronous block based networking requests. It's usage in my code is to facilitate HTTP requests, and the automatic mapping of responses into object graphs, as discussed in the Data Mapping example code.

An example of how to use this class is as follows:

    // Post to the webservice
    NSURLRequest *request = [[Webservice sharedWebservice] requestWithMethod:@"POST" path:@"1/people" parameters:params];
    
    #ifdef DEBUG    
    // Mock this response
    [Webservice mockRequest:request withMockDataNamed:@"sign-up" statusCode:200 errorMessage:nil];
    #endif
    
    // Use the webservice
    [Webservice callRequest:request inManagedObjectContext:managedObjectContext completion:^(NSArray *objects, id response, NSUInteger status, NSError *error) {
        
        if (!response && error) {
            DDLogVerbose(@"error siging in: %@", [error localizedDescription]);
            if (completion) completion(nil, error);
        } else if (completion) {
            // Get the Person
            Person *person = [objects objectAtIndex:0];
            // Call the completion handler
            completion(person, nil);
        }
    }];
 
 
This enables a very clean separation of logic between networking, data mapping, model and controller layers. Typically the completion object is a block which will update the user interface or otherwise process the resultant object. 

Mocking API requests, which utilized the MockURLProtocol class is a very useful technique to adopt during development and testing. It works by registering a class that can accept URL requests, and then returning canned responses (from JSON files) registered for particular URL requests. This makes it possible to write unit/functional tests against code which relies on network connectivity.