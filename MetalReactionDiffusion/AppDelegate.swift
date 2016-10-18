//
//  AppDelegate.swift
//  MetalReactionDiffusion
//
//  Created by Simon Gladman on 18/10/2014.
//  Copyright (c) 2014 Simon Gladman. All rights reserved.
//


import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {
        let existingUser = UserDefaults.standard.bool(forKey: "existingUser") as Bool
        
        if !existingUser
        {
            if let _managedObjectContext = managedObjectContext
            {
                let presets:[ReactionDiffusion] = [Worms(), Spots(), SpottyBifurcation(), Strings(), Bifurcation(),Liquid(), ExcitedLines(), SpiralCoral()]
                
                let presetImage = UIImage(named: "preset.jpg")
                
                for preset in presets
                {
                    let _ = ReactionDiffusionEntity.createInManagedObjectContext(_managedObjectContext, model: preset.model.rawValue, reactionDiffusionStruct: preset.reactionDiffusionStruct, image: presetImage!)
                    
                    self.saveContext()
                }
            }
        }
        
        
        UserDefaults.standard.set(true, forKey: "existingUser")
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication)
    {
        if let viewController = window?.rootViewController as? ViewController
        {
            viewController.isRunning = false
        }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication)
    {
        deleteItemsPendingDelete()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication)
    {
    }
    
    func applicationDidBecomeActive(_ application: UIApplication)
    {
        if let viewController = window?.rootViewController as? ViewController
        {
            loadAutoSaved()
            
            viewController.isRunning = true
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication)
    {
        deleteItemsPendingDelete()
    }
    
    func loadAutoSaved()
    {
        var autoSavedFound: Bool = false
        
        let fetchRequest = NSFetchRequest<ReactionDiffusionEntity>(entityName: "ReactionDiffusionEntity")
        
        if let _managedObjectContext = managedObjectContext
        {
            if let fetchResults = try? _managedObjectContext.fetch(fetchRequest)
            {
                for entity in fetchResults
                {
                    if (entity.autoSaved == true)
                    {
                        if let viewController = window?.rootViewController as? ViewController
                        {
                            viewController.reactionDiffusionModel = ReactionDiffusionEntity.createInstanceFromEntity(entity)
                            
                            autoSavedFound = true
                        }
                        
                        _managedObjectContext.delete(entity)
                    }
                }
            }
        }
        
        if !autoSavedFound
        {
            if let viewController = window?.rootViewController as? ViewController
            {
                viewController.reactionDiffusionModel = FitzhughNagumo()
                viewController.reactionDiffusionModel.reactionDiffusionStruct.timestep = 0.02
                viewController.reactionDiffusionModel.reactionDiffusionStruct.a0 = 0.664062
                viewController.reactionDiffusionModel.reactionDiffusionStruct.a1 = 0.451172
                viewController.reactionDiffusionModel.reactionDiffusionStruct.epsilon = 0.136719
                viewController.reactionDiffusionModel.reactionDiffusionStruct.delta = 4.0
                viewController.reactionDiffusionModel.reactionDiffusionStruct.k1 = 1.645508
                viewController.reactionDiffusionModel.reactionDiffusionStruct.k2 = 0.0097
                viewController.reactionDiffusionModel.reactionDiffusionStruct.k3 = 2.2314
            }
        }
    }
    
    func deleteItemsPendingDelete()
    {
        let fetchRequest = NSFetchRequest<ReactionDiffusionEntity>(entityName: "ReactionDiffusionEntity")
        
        if let _managedObjectContext = managedObjectContext
        {
            if let fetchResults = try? _managedObjectContext.fetch(fetchRequest)
            {
                for entity in fetchResults
                {
                    if entity.pendingDelete
                    {
                        _managedObjectContext.delete(entity)
                    }
                }
            }
            
            // save current state
            
            if let viewController = window?.rootViewController as? ViewController
            {
                let _ = ReactionDiffusionEntity.createInManagedObjectContext(_managedObjectContext, model: viewController.reactionDiffusionModel.model.rawValue, reactionDiffusionStruct: viewController.reactionDiffusionModel.reactionDiffusionStruct, image: viewController.imageView.image!, autoSaved: true)
            }
        }
        
        self.saveContext()
    }
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "uk.co.flexmonkey.MetalReactionDiffusion" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "ReDiLab", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator: NSPersistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("ReDiLab.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        //TODO: - add coordinator
        guard let store = try? coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil) else {
            // Report any error we got.
            var dict: [AnyHashable : Any] = [:]
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict as [AnyHashable: Any])
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error!.userInfo)")

            assertionFailure()
            return nil
        }
        //        if nil == try? coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil) ?? nil {
//                    coordinator = nil
//                    // Report any error we got.
//                    let dict = NSMutableDictionary()
//                    dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
//                    dict[NSLocalizedFailureReasonErrorKey] = failureReason
//                    dict[NSUnderlyingErrorKey] = error
//                    error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict as [AnyHashable: Any])
//                    // Replace this with code to handle the error appropriately.
//                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//                    NSLog("Unresolved error \(error), \(error!.userInfo)")
        //            abort()
        //        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext ()
    {
        if let moc = self.managedObjectContext {
            if moc.hasChanges {
                try! moc.save()
            }
        }
    }
    
}

