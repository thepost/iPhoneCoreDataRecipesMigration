/*
     File: RecipesAppDelegate.m 
 Abstract: Application delegate that sets up a tab bar controller with two view controllers -- a navigation controller that in turn loads a table view controller to manage a list of recipes, and a unit converter view controller.
  
 Version: 1.4 
 Copyright (C) 2010 Apple Inc. All Rights Reserved. 
  
 */

#import "RecipesAppDelegate.h"
#import "RecipeListTableViewController.h"
#import "UnitConverterTableViewController.h"

@implementation RecipesAppDelegate

@synthesize window;
@synthesize tabBarController;
@synthesize recipeListController;


- (void)applicationDidFinishLaunching:(UIApplication *)application 
{
    recipeListController.managedObjectContext = self.managedObjectContext;        
    
    [window addSubview:tabBarController.view];
    [window makeKeyAndVisible];
}


/**
 applicationWillTerminate: saves changes in the application's managed object context before the application terminates.
 */
- (void)applicationWillTerminate:(UIApplication *)application {
	
    NSError *error;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
			/*
			 Replace this implementation with code to handle the error appropriately.
			 
			 abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
			 */
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			abort();
        } 
    }
}


#pragma mark -
#pragma mark Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext {
	
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [NSManagedObjectContext new];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    return managedObjectContext;
}


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created by merging all of the models found in the application bundle.
 */
- (NSManagedObjectModel *)managedObjectModel {
	
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }

    /*
    //Alternatively use this...
    NSError *error = nil;
    NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType
                                    :<#(NSString *)#> 
                                    URL:<#(NSURL *)#> 
                                    error:error];
    NSArray *bundlesForSourceModel = nil;
    */
     
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"Recipes" ofType:@"momd"];
    NSURL *modelURL = [NSURL fileURLWithPath:modelPath];    
    
    managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
    return managedObjectModel;
}


/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator 
{	
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
		
	NSString *storePath = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:@"Recipes.sqlite"];
    [storePath retain];

	NSFileManager *fileManager = [NSFileManager defaultManager];
	//If the expected store doesn't exist, copy the default store.
	if (![fileManager fileExistsAtPath:storePath]) {
		NSString *defaultStorePath = [[NSBundle mainBundle] pathForResource:@"Recipes" ofType:@"sqlite"];
		if (defaultStorePath) {
			[fileManager copyItemAtPath:defaultStorePath toPath:storePath error:NULL];
		}
	}
    
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    
    //Check to see what version of the current model we're in. If it's >= 2.0, then and ONLY then check if migration has been performed...
    NSSet *versionIdentifiers = [[self managedObjectModel] versionIdentifiers];
    NSLog(@"Which Current Version is our .xcdatamodeld file set to? %@", versionIdentifiers);
    
    if ([versionIdentifiers containsObject:@"2.0"]) 
    {        
        BOOL hasMigrated = [self checkForMigration];
        
        if (hasMigrated==YES) {
            [storePath release];
            storePath = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:@"Recipes2.sqlite"];
        }
    }
    
    NSError *error = nil;
    NSURL *storeUrl = [NSURL fileURLWithPath:storePath];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, 
                             [NSNumber numberWithBool:NO], NSInferMappingModelAutomaticallyOption, nil];
    
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error]) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
    }    
    
    return persistentStoreCoordinator;
}//END


//This won't even get called unless our versionIdentifiers has confirmed that our Version 2 model exists.
- (BOOL)checkForMigration
{
    BOOL migrationSuccess = NO;
    NSString *storeSourcePath = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:@"Recipes2.sqlite"];
    NSFileManager *fileManager = [NSFileManager defaultManager];

	if (![fileManager fileExistsAtPath:storeSourcePath]) {
        //Version 2 SQL has not been created yet, so the source is still version 1...
        storeSourcePath = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:@"Recipes.sqlite"];
    }
	
    NSURL *storeSourceUrl = [NSURL fileURLWithPath: storeSourcePath];
	NSError *error = nil;        
    NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType 
                                                                                              URL:storeSourceUrl 
                                                                                            error:&error];    
    if (sourceMetadata) {
        NSString *configuration = nil;
        NSManagedObjectModel *destinationModel = [self.persistentStoreCoordinator managedObjectModel];
        
        //Our Source 1 is going to be incompatible with the Version 2 Model, our Source 2 won't be...
        BOOL pscCompatible = [destinationModel isConfiguration:configuration compatibleWithStoreMetadata:sourceMetadata];
        NSLog(@"Is the STORE data COMPATIBLE? %@", (pscCompatible==YES) ?@"YES" :@"NO");
                
        if (pscCompatible == NO) {
            migrationSuccess = [self performMigrationWithSourceMetadata:sourceMetadata toDestinationModel:destinationModel];
        }
    }
    else {
        NSLog(@"checkForMigration FAIL - No Source Metadata! \nERROR: %@", [error localizedDescription]);
    }
    return migrationSuccess;
}//END


- (BOOL)performMigrationWithSourceMetadata :(NSDictionary *)sourceMetadata toDestinationModel:(NSManagedObjectModel *)destinationModel
{
    BOOL migrationSuccess = NO;
    //Initialise a Migration Manager...
    NSManagedObjectModel *sourceModel = [NSManagedObjectModel mergedModelFromBundles:nil 
                                                                    forStoreMetadata:sourceMetadata];
    //Perform the migration...
    if (sourceModel) {
        NSMigrationManager *standardMigrationManager = [[NSMigrationManager alloc] initWithSourceModel:sourceModel 
                                                                                      destinationModel:destinationModel];
        //Retrieve the appropriate mapping model...
        NSMappingModel *mappingModel = [NSMappingModel mappingModelFromBundles:nil 
                                                                forSourceModel:sourceModel 
                                                              destinationModel:destinationModel];
        if (mappingModel) {
            NSError *error = nil;
            NSString *storeSourcePath = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:@"Recipes.sqlite"];
            NSURL *storeSourceUrl = [NSURL fileURLWithPath: storeSourcePath];
            NSString *storeDestPath = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:@"Recipes2.sqlite"];
            NSURL *storeDestUrl = [NSURL fileURLWithPath:storeDestPath];
            
            //Pass nil here because we don't want to use any of these options:
            //NSIgnorePersistentStoreVersioningOption, NSMigratePersistentStoresAutomaticallyOption, or NSInferMappingModelAutomaticallyOption
            NSDictionary *sourceStoreOptions = nil;
            NSDictionary *destinationStoreOptions = nil;
            
            migrationSuccess = [standardMigrationManager migrateStoreFromURL:storeSourceUrl 
                                                                             type:NSSQLiteStoreType
                                                                          options:sourceStoreOptions 
                                                                 withMappingModel:mappingModel 
                                                                 toDestinationURL:storeDestUrl 
                                                                  destinationType:NSSQLiteStoreType 
                                                               destinationOptions:destinationStoreOptions 
                                                                            error:&error];
            NSLog(@"MIGRATION SUCCESSFUL? %@", (migrationSuccess==YES)?@"YES":@"NO");
        }
    }   
    else {
        //TODO: Error to user...
        NSLog(@"checkForMigration FAIL - No Mapping Model found!");
        abort();    
    }
    return migrationSuccess;
}//END



#pragma mark -
#pragma mark Application's documents directory

/**
 Returns the path to the application's documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}


#pragma mark -
#pragma mark Memory management

- (void)dealloc {
    [managedObjectContext release];
    [managedObjectModel release];
    [persistentStoreCoordinator release];
    
    [recipeListController release];
    [tabBarController release];
    [window release];
    [super dealloc];
}

@end
