//
//  ParameterWidget.swift
//  MetalReactionDiffusion
//
//  Created by Simon Gladman on 23/10/2014.
//  Copyright (c) 2014 Simon Gladman. All rights reserved.
//

import UIKit

class ParameterWidget: UIControl, UIPopoverPresentationControllerDelegate
{
    let label = UILabel(frame: CGRect.zero)
    let slider = UISlider(frame: CGRect.zero)
    
    let parameterWidgetViewController: ParameterWidgetViewController
//    let popoverController: UIPopoverPresentationController?
    
    override init(frame: CGRect)
    {
        parameterWidgetViewController = ParameterWidgetViewController()
        
        super.init(frame: frame)
    }
    
    required init(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToSuperview()
    {
        
        label.textColor = UIColor.white
        layer.backgroundColor = UIColor.darkGray.cgColor
        
        layer.cornerRadius = 5
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowOpacity = 0.5
        
        addSubview(label)
        addSubview(slider)
        
        slider.addTarget(self, action: #selector(ParameterWidget.sliderChangeHandler), for: UIControlEvents.valueChanged)
        parameterWidgetViewController.slider.addTarget(self, action: #selector(ParameterWidget.bigSliderChangeHandler), for: UIControlEvents.valueChanged)
        parameterWidgetViewController.slider.addTarget(self, action: #selector(ParameterWidget.bigSliderTouchUpInsideHandler), for: UIControlEvents.touchUpInside)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(ParameterWidget.longHoldHandler(_:)))
        longPress.minimumPressDuration = 0.75
        longPress.allowableMovement = 7.5
        addGestureRecognizer(longPress)
    }
    
    func longHoldHandler(_ recognizer: UILongPressGestureRecognizer)
    {
        if recognizer.state == UIGestureRecognizerState.began
        {
            if let rootController = UIApplication.shared.keyWindow!.rootViewController
            {
                var popupSource = layer.frame
                popupSource.origin.x += superview!.frame.origin.x
                popupSource.origin.y += superview!.frame.origin.y
                
                guard let popover = self.parameterWidgetViewController.popoverPresentationController else {
                    return
                }
                popover.sourceView = self
                popover.sourceRect = popupSource
                popover.delegate = self
                
                rootController.present(self.parameterWidgetViewController, animated: true, completion: nil)
            }
        }
    }
    
    func bigSliderTouchUpInsideHandler()
    {
        sendActions(for: UIControlEvents.ResetSimulation)
    }
    
    func bigSliderChangeHandler()
    {
        slider.value = parameterWidgetViewController.slider.value
        sliderChangeHandler()
    }
    
    func sliderChangeHandler()
    {
        value = slider.value
        
        popoulateLabel()
        
        sendActions(for: UIControlEvents.valueChanged)
    }
    
    func popoulateLabel()
    {
        if let fieldName = reactionDiffusionFieldName
        {
            label.text = fieldName.rawValue + " = " + (NSString(format: "%.6f", value) as String)
        }
    }
    
    var reactionDiffusionFieldName: ReactionDiffusionFieldNames?
        {
        didSet
        {
            popoulateLabel();
        }
    }
    
    var value: Float = 0
        {
        didSet
        {
            slider.value = value
            parameterWidgetViewController.slider.value = value
            popoulateLabel()
        }
    }
    
    var minimumValue: Float = 0
        {
        didSet
        {
            parameterWidgetViewController.slider.minimumValue = minimumValue
            slider.minimumValue = minimumValue
        }
    }
    
    var maximumValue: Float = 1
        {
        didSet
        {
            parameterWidgetViewController.slider.maximumValue = maximumValue
            slider.maximumValue = maximumValue
        }
    }
    
    override func layoutSubviews()
    {
        label.frame = CGRect(x: 5, y: -3, width: frame.width, height: frame.height / 2)
        slider.frame = CGRect(x: 0, y: frame.height - 30, width: frame.width, height: frame.height / 2)
    }
    
}
