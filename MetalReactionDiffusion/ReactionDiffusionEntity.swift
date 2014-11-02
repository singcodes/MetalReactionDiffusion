//
//  ReactionDiffusionEntity.swift
//  MetalReactionDiffusion
//
//  Created by Simon Gladman on 31/10/2014.
//  Copyright (c) 2014 Simon Gladman. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class ReactionDiffusionEntity: NSManagedObject {

    @NSManaged var model: String
    @NSManaged var timestep: NSNumber
    @NSManaged var a0: NSNumber
    @NSManaged var a1: NSNumber
    @NSManaged var epsilon: NSNumber
    @NSManaged var delta: NSNumber
    @NSManaged var k1: NSNumber
    @NSManaged var k2: NSNumber
    @NSManaged var k3: NSNumber
    @NSManaged var f: NSNumber
    @NSManaged var k: NSNumber
    @NSManaged var du: NSNumber
    @NSManaged var dv: NSNumber
    @NSManaged var alpha: NSNumber
    @NSManaged var beta: NSNumber
    @NSManaged var gamma: NSNumber
    @NSManaged var imageData: NSData

    
    class func createInstanceFromEntity(entity: ReactionDiffusionEntity) -> ReactionDiffusion!
    {
        var returnObject: ReactionDiffusion!
        
        var model: ReactionDiffusionModels = ReactionDiffusionModels(rawValue: entity.model)!
        
        switch model
        {
            case .BelousovZhabotinsky:
                returnObject = BelousovZhabotinsky()
            case .GrayScott:
                returnObject = GrayScott()
            case .FitzHughNagumo:
                returnObject = FitzhughNagumo()
        }
        
        // populate numeric params...
        
        return returnObject
    }
    
    class func createInManagedObjectContext(moc: NSManagedObjectContext, model: String, reactionDiffusionStruct: ReactionDiffusionParameters, image: UIImage) -> ReactionDiffusionEntity
    {
        let newItem = NSEntityDescription.insertNewObjectForEntityForName("ReactionDiffusionEntity", inManagedObjectContext: moc) as ReactionDiffusionEntity
        
        newItem.model = model
        
        newItem.imageData = UIImageJPEGRepresentation(image.resizeToBoundingSquare(boundingSquareSideLength: 160.0), 0.75)
        
        newItem.timestep = reactionDiffusionStruct.timestep
        newItem.a0 = reactionDiffusionStruct.a0
        newItem.a1 = reactionDiffusionStruct.a1
        newItem.epsilon = reactionDiffusionStruct.epsilon
        newItem.delta = reactionDiffusionStruct.delta
        newItem.k1 = reactionDiffusionStruct.k1
        newItem.k2 = reactionDiffusionStruct.k2
        newItem.k3 = reactionDiffusionStruct.k3
        newItem.f = reactionDiffusionStruct.F
        newItem.k = reactionDiffusionStruct.K
        newItem.du = reactionDiffusionStruct.Du
        newItem.dv = reactionDiffusionStruct.Dv
        newItem.alpha = reactionDiffusionStruct.alpha
        newItem.beta = reactionDiffusionStruct.beta
        newItem.gamma = reactionDiffusionStruct.gamma
        
        
        return newItem
    }
}