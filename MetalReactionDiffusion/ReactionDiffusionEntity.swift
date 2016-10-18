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
    @NSManaged var imageData: Data
    @NSManaged var autoSaved: NSNumber
    
    var pendingDelete: Bool = false
    
    class func createInstanceFromEntity(_ entity: ReactionDiffusionEntity) -> ReactionDiffusion!
    {
        var returnObject: ReactionDiffusion!
        
        let model: ReactionDiffusionModels = ReactionDiffusionModels(rawValue: entity.model)!
        
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
        returnObject.reactionDiffusionStruct.timestep = Float(entity.timestep)
        returnObject.reactionDiffusionStruct.a0 = Float(entity.a0)
        returnObject.reactionDiffusionStruct.a1 = Float(entity.a1)
        returnObject.reactionDiffusionStruct.epsilon = Float(entity.epsilon)
        returnObject.reactionDiffusionStruct.delta = Float(entity.delta)
        returnObject.reactionDiffusionStruct.k1 = Float(entity.k1)
        returnObject.reactionDiffusionStruct.k2 = Float(entity.k2)
        returnObject.reactionDiffusionStruct.k3 = Float(entity.k3)
        returnObject.reactionDiffusionStruct.F = Float(entity.f)
        returnObject.reactionDiffusionStruct.K = Float(entity.k)
        returnObject.reactionDiffusionStruct.Du = Float(entity.du)
        returnObject.reactionDiffusionStruct.Dv = Float(entity.dv)
        returnObject.reactionDiffusionStruct.alpha = Float(entity.alpha)
        returnObject.reactionDiffusionStruct.beta = Float(entity.beta)
        returnObject.reactionDiffusionStruct.gamma = Float(entity.gamma)
        
        return returnObject
    }
    
    class func createInManagedObjectContext(_ moc: NSManagedObjectContext, model: String, reactionDiffusionStruct: ReactionDiffusionParameters, image: UIImage, autoSaved: Bool = false) -> ReactionDiffusionEntity
    {
        let newItem = NSEntityDescription.insertNewObject(forEntityName: "ReactionDiffusionEntity", into: moc) as! ReactionDiffusionEntity
        
        newItem.model = model
        
        newItem.imageData = UIImageJPEGRepresentation(image.resizeToBoundingSquare(160.0), 0.75)!
 
        newItem.timestep = NSNumber(value: reactionDiffusionStruct.timestep)
        newItem.a0 = NSNumber(value: reactionDiffusionStruct.a0)
        newItem.a1 = NSNumber(value: reactionDiffusionStruct.a1)
        newItem.epsilon = NSNumber(value: reactionDiffusionStruct.epsilon)
        newItem.delta = NSNumber(value: reactionDiffusionStruct.delta)
        newItem.k1 = NSNumber(value: reactionDiffusionStruct.k1)
        newItem.k2 = NSNumber(value: reactionDiffusionStruct.k2)
        newItem.k3 = NSNumber(value: reactionDiffusionStruct.k3)
        newItem.f = NSNumber(value: reactionDiffusionStruct.F)
        newItem.k = NSNumber(value: reactionDiffusionStruct.K)
        newItem.du = NSNumber(value: reactionDiffusionStruct.Du)
        newItem.dv = NSNumber(value: reactionDiffusionStruct.Dv)
        newItem.alpha = NSNumber(value: reactionDiffusionStruct.alpha)
        newItem.beta = NSNumber(value: reactionDiffusionStruct.beta)
        newItem.gamma = NSNumber(value: reactionDiffusionStruct.gamma)
        newItem.autoSaved = autoSaved as NSNumber
        
        return newItem
    }
}
