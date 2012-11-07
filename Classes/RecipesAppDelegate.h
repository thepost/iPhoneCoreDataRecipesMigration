/*
     File: RecipesAppDelegate.h
 Abstract: Application delegate that sets up a tab bar controller with two view controllers -- a navigation controller that in turn loads a table view controller to manage a list of recipes, and a unit converter view controller.
 
  Version: 1.4
 
 Copyright (C) 2010 Apple Inc. All Rights Reserved.
 
 */

@class RecipeListTableViewController;

@interface RecipesAppDelegate : NSObject <UIApplicationDelegate> {

    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;	    
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
	
    UIWindow *window;
    UITabBarController *tabBarController;
    RecipeListTableViewController *recipeListController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UITabBarController *tabBarController;
@property (nonatomic, retain) IBOutlet RecipeListTableViewController *recipeListController;

@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (NSString *)applicationDocumentsDirectory;
- (BOOL)checkForMigration;
- (BOOL)performMigrationWithSourceMetadata :(NSDictionary *)sourceMetadata toDestinationModel:(NSManagedObjectModel *)destinationModel;

@end

