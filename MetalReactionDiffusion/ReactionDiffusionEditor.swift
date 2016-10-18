//
//  ReactionDiffusionEditor.swift
//  MetalReactionDiffusion
//
//  Created by Simon Gladman on 23/10/2014.
//  Copyright (c) 2014 Simon Gladman. All rights reserved.
//

import UIKit

class ReactionDiffusionEditor: UIControl
{
    var parameterWidgets = [ParameterWidget]()
    let toolbar = UIToolbar(frame: CGRect.zero)
    let menuButton = UIButton(frame: CGRect.zero)
    let label = UILabel(frame: CGRect.zero)
    var requestedReactionDiffusionModel : ReactionDiffusionModels?

    override func didMoveToSuperview()
    {
        let resetSimulationButton = UIBarButtonItem(title: "Reset Sim", style: UIBarButtonItemStyle.plain, target: self, action: #selector(ReactionDiffusionEditor.resetSimulation))
        
        let spacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        
        let resetParametersButton = UIBarButtonItem(title: "Reset Params", style: UIBarButtonItemStyle.plain, target: self, action: #selector(ReactionDiffusionEditor.resetParameters))
        
        toolbar.items = [resetSimulationButton, spacer, resetParametersButton]
        
        toolbar.barStyle = UIBarStyle.blackTranslucent
        
        addSubview(toolbar)
        
        menuButton.layer.borderColor = UIColor.lightGray.cgColor
        menuButton.layer.borderWidth = 1
        menuButton.layer.cornerRadius = 5
        
        menuButton.showsTouchWhenHighlighted = true
        menuButton.imageView?.contentMode = UIViewContentMode.scaleAspectFit
        menuButton.setImage(UIImage(named: "hamburger.png"), for: UIControlState())

        menuButton.addTarget(self, action: #selector(ReactionDiffusionEditor.displayCallout), for: UIControlEvents.touchDown)
        
        addSubview(menuButton)
        
        label.textAlignment = NSTextAlignment.right
        label.textColor = UIColor.white
        
        addSubview(label)
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: -1, height: 2)
        layer.shadowOpacity = 1
    }
    
    var reactionDiffusionModel: ReactionDiffusion!
    {
        didSet
        {
            if oldValue == nil || oldValue.model.rawValue != reactionDiffusionModel.model.rawValue
            {
                //createUserInterface()
            }
            createUserInterface()
        }
    }

    func displayCallout()
    {
        // work in progress! Refactor to create once, draw list of possible models from seperate class....
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        let fitzhughNagumoAction = UIAlertAction(title: ReactionDiffusionModels.FitzHughNagumo.rawValue, style: UIAlertActionStyle.default, handler: reactionDiffusionModelChangeHandler)
        let grayScottAction = UIAlertAction(title: ReactionDiffusionModels.GrayScott.rawValue, style: UIAlertActionStyle.default, handler: reactionDiffusionModelChangeHandler)
        let belousovZhabotinskyAction = UIAlertAction(title: ReactionDiffusionModels.BelousovZhabotinsky.rawValue, style: UIAlertActionStyle.default, handler: reactionDiffusionModelChangeHandler)
        
        let saveAction = UIAlertAction(title: "Save", style: UIAlertActionStyle.default, handler: saveActionHandler)
        let loadAction = UIAlertAction(title: "Browse and Load", style: UIAlertActionStyle.default, handler: loadActionHandler)
        let aboutAction = UIAlertAction(title: "About", style: UIAlertActionStyle.default, handler: aboutActionHandler)
        
        alertController.addAction(belousovZhabotinskyAction)
        alertController.addAction(fitzhughNagumoAction)
        alertController.addAction(grayScottAction)
        
        alertController.addAction(saveAction)
        alertController.addAction(loadAction)
        alertController.addAction(aboutAction)
        
        if let viewController = UIApplication.shared.keyWindow!.rootViewController
        {
            if let popoverPresentationController = alertController.popoverPresentationController
            {
                let xx = menuButton.frame.origin.x + frame.origin.x
                let yy = menuButton.frame.origin.y + frame.origin.y
                
                popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirection.right
                
                popoverPresentationController.sourceRect = CGRect(x: xx, y: yy, width: menuButton.frame.width, height: menuButton.frame.height)
                popoverPresentationController.sourceView = viewController.view

                viewController.present(alertController, animated: true, completion: nil)
            }
        }
    }

    func reactionDiffusionModelChangeHandler(_ value: UIAlertAction!) -> Void
    {
        requestedReactionDiffusionModel = ReactionDiffusionModels(rawValue: value.title!)
        
        sendActions(for: UIControlEvents.ModelChanged)
    }
    
    func saveActionHandler(_ value: UIAlertAction!) -> Void
    {
        sendActions(for: UIControlEvents.SaveModel)
    }
    
    func loadActionHandler(_ value: UIAlertAction!) -> Void
    {
        sendActions(for: UIControlEvents.LoadModel)
    }
    
    func aboutActionHandler(_ value: UIAlertAction!) -> Void
    {
        let alertController = UIAlertController(title: "ReDiLab v1.0\nReaction Diffusion Laboratory", message: "\nSimon Gladman | November 2014", preferredStyle: UIAlertControllerStyle.alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        let openBlogAction = UIAlertAction(title: "Open Blog", style: .default, handler: visitFlexMonkey)
        
        alertController.addAction(okAction)
        alertController.addAction(openBlogAction)
        
        if let viewController = UIApplication.shared.keyWindow!.rootViewController
        {
            viewController.present(alertController, animated: true, completion: nil)
        }
    }
    
    func visitFlexMonkey(_ value: UIAlertAction!)
    {
        UIApplication.shared.openURL(URL(string: "http://flexmonkey.blogspot.co.uk")!)
    }

    
    func resetSimulation()
    {
        sendActions(for: UIControlEvents.ResetSimulation)
    }
    
    func resetParameters()
    {
        reactionDiffusionModel.resetParameters()
        
        for widget in parameterWidgets
        {
            widget.value = reactionDiffusionModel.getValueForFieldName(widget.reactionDiffusionFieldName!)
        }
        
        sendActions(for: UIControlEvents.valueChanged)
    }
    
    func createUserInterface()
    {
        label.text = reactionDiffusionModel.model.rawValue
        
        for widget in parameterWidgets
        {
            var varWidget: ParameterWidget? = widget
            
            varWidget!.removeFromSuperview()
            varWidget = nil
        }
        
        parameterWidgets = [ParameterWidget]()
        
        for fieldName in reactionDiffusionModel.fieldNames
        {
            let widget = ParameterWidget(frame: CGRect.zero)
            
            parameterWidgets.append(widget)
            
            widget.minimumValue = reactionDiffusionModel.getMinMaxForFieldName(fieldName).min
            widget.maximumValue = reactionDiffusionModel.getMinMaxForFieldName(fieldName).max
      
            widget.value = reactionDiffusionModel.getValueForFieldName(fieldName)
            widget.reactionDiffusionFieldName = fieldName
            
            widget.addTarget(self, action: #selector(ReactionDiffusionEditor.widgetChangeHandler(_:)), for: UIControlEvents.valueChanged)
            widget.addTarget(self, action: #selector(ReactionDiffusionEditor.resetSimulation), for: UIControlEvents.ResetSimulation)
 
            addSubview(widget)
        }
        
        setNeedsLayout()
    }

    func widgetChangeHandler(_ widget: ParameterWidget)
    {
        if let fieldName = widget.reactionDiffusionFieldName
        {
            reactionDiffusionModel.setValueForFieldName(fieldName, value: widget.value)
            
            sendActions(for: UIControlEvents.valueChanged)
        }
    }
    
    override func layoutSubviews()
    {
        layer.backgroundColor = UIColor.darkGray.cgColor

        toolbar.frame = CGRect(x: 0, y: frame.height - 40, width: frame.width, height: 40)
        
        let enums = parameterWidgets.enumerated()
        for (idx, widget) in enums
        {
            widget.frame = CGRect(x: 10, y: 60 + idx * 80, width: Int(frame.width - 20), height: 55)
        }
        
        menuButton.frame = CGRect(x: 10, y: 10, width: 30, height: 30)
        
        label.frame = CGRect(x: 40, y: 10, width: frame.width - 40 - 10, height: 30)
    }

}

extension UIControlEvents
{
    static let ResetSimulation: UIControlEvents = UIControlEvents(rawValue: 0x01000000)
    static let ModelChanged: UIControlEvents = UIControlEvents(rawValue: 0x02000000)
    static let SaveModel: UIControlEvents = UIControlEvents(rawValue: 0x04000000)
    static let LoadModel: UIControlEvents = UIControlEvents(rawValue: 0x08000000)
}
