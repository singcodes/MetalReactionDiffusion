//
//  ViewController.swift
//  MetalReactionDiffusion
//
//  Created by Simon Gladman on 18/10/2014.
//  Copyright (c) 2014 Simon Gladman. All rights reserved.
//
//  Thanks to http://www.raywenderlich.com/77488/ios-8-metal-tutorial-swift-getting-started
//  Thanks to https://twitter.com/steipete/status/473952933684330497
//  Thanks to http://metalbyexample.com/textures-and-samplers/
//  Thanks to http://metalbyexample.com/introduction-to-compute/
//
//  Thanks to http://jamesonquave.com/blog/core-data-in-swift-tutorial-part-1/

import UIKit
import Metal
import QuartzCore
import CoreData

class ViewController: UIViewController, UIPopoverPresentationControllerDelegate
{
    let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue)
    let renderingIntent: CGColorRenderingIntent = .defaultIntent
    
    let imageSide: Int = 640
    let imageSize = CGSize(width: Int(640), height: Int(640))
    let imageByteCount = Int(640 * 640 * 4) 
    
    let bytesPerPixel = Int(4)
    let bitsPerComponent = Int(8)
    let bitsPerPixel:Int = 32
    let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
     
    let bytesPerRow = Int(4 * 640)
    let providerLength = Int(640 * 640 * 4) * MemoryLayout<UInt8>.size
    var imageBytes = [UInt8](repeating: 0, count: Int(640 * 640 * 4))
    
    var pipelineState: MTLComputePipelineState!
    var defaultLibrary: MTLLibrary! = nil
    var device: MTLDevice! = nil
    var commandQueue: MTLCommandQueue! = nil

    let imageView =  UIImageView(frame: CGRect.zero)
    let editor = ReactionDiffusionEditor(frame: CGRect.zero)
    
    var region: MTLRegion!
    var textureA: MTLTexture!
    var textureB: MTLTexture!
    var useTextureAForInput = true
    var resetSimulationFlag = false
    var newModelLoadedFlag = false

    var image:UIImage!
    var runTime = CFAbsoluteTimeGetCurrent()
    var errorFlag:Bool = false
    
    var threadGroupCount:MTLSize!
    var threadGroups: MTLSize!

    var reactionDiffusionModel: ReactionDiffusion = GrayScott()
    {
        didSet
        {
            if oldValue.model != reactionDiffusionModel.model
            {
                newModelLoadedFlag = true
            }
        }
    }
    
    var requestedReactionDiffusionModel: ReactionDiffusionModels?

    let appDelegate: AppDelegate
    let managedObjectContext: NSManagedObjectContext
    
    let browseAndLoadController: BrowseAndLoadController
    
    required init?(coder aDecoder: NSCoder)
    {
        appDelegate = UIApplication.shared.delegate as! AppDelegate
        managedObjectContext = appDelegate.managedObjectContext!
        
        browseAndLoadController = BrowseAndLoadController()
        
        super.init(coder: aDecoder)!
//        super.init?(coder: aDecoder)

        browseAndLoadController.preferredContentSize = CGSize(width: 640, height: 480)
    }

    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        view.backgroundColor = UIColor.black
        
        imageView.contentMode = UIViewContentMode.scaleAspectFit
        
        view.addSubview(imageView)
        view.addSubview(editor)

        editor.alpha = 0
        imageView.alpha = 0

        UIView.animate(withDuration: 0.5, delay: 0.25, options: UIViewAnimationOptions(), animations: {self.imageView.alpha = 1.0; self.editor.alpha = 1.0}, completion: nil)
        
        editor.reactionDiffusionModel = reactionDiffusionModel
        editor.addTarget(self, action: #selector(ViewController.editorChangeHandler(_:)), for: UIControlEvents.valueChanged)
        editor.addTarget(self, action: #selector(ViewController.resetSimulationHandler), for: UIControlEvents.ResetSimulation)
        editor.addTarget(self, action: #selector(ViewController.modelChangedHandler(_:)), for: UIControlEvents.ModelChanged)
        editor.addTarget(self, action: #selector(ViewController.saveModel), for: UIControlEvents.SaveModel)
        editor.addTarget(self, action: #selector(ViewController.loadModel), for: UIControlEvents.LoadModel)
        
        setUpMetal()
    }

    final func modelChangedHandler(_ value: ReactionDiffusionEditor)
    {
        if value.requestedReactionDiffusionModel != nil
        {
            requestedReactionDiffusionModel = value.requestedReactionDiffusionModel!
        }
    }
    
    final func editorChangeHandler(_ value: ReactionDiffusionEditor)
    {
        reactionDiffusionModel.reactionDiffusionStruct = value.reactionDiffusionModel.reactionDiffusionStruct
    }
    
    func resetSimulationHandler()
    {
        resetSimulationFlag = true
    }
    
    func saveModel()
    {
        var newEntity = ReactionDiffusionEntity.createInManagedObjectContext(managedObjectContext, model: reactionDiffusionModel.model.rawValue, reactionDiffusionStruct: reactionDiffusionModel.reactionDiffusionStruct, image: self.imageView.image!)
        
       appDelegate.saveContext()
    }
    
    func loadModel()
    {
        let fetchRequest = NSFetchRequest<ReactionDiffusionEntity>(entityName: "ReactionDiffusionEntity")
        
        if let fetchResults = try? managedObjectContext.fetch(fetchRequest)
        {
            // retrieved fetchResults.count records....
            guard let popover = self.popoverPresentationController, let root = UIApplication.shared.keyWindow?.rootViewController else {
                return
            }
            popover.delegate = self
            popover.sourceView = view
            popover.sourceRect = view.frame
            popover.permittedArrowDirections = .any
            
            root.present(self, animated: true, completion: nil)
        
            browseAndLoadController.fetchResults = fetchResults
        }
    }
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        if let _selectedEntity = browseAndLoadController.selectedEntity
        {
            reactionDiffusionModel = ReactionDiffusionEntity.createInstanceFromEntity(_selectedEntity)
        }
    }

    func setUpMetal()
    {
        device = MTLCreateSystemDefaultDevice()
        
        print("device = \(device)")
        
        if device == nil
        {
            errorFlag = true
            
    
        }
        else
        {
            defaultLibrary = device.newDefaultLibrary()
            commandQueue = device.makeCommandQueue()
            
            let kernelFunction = defaultLibrary.makeFunction(name: reactionDiffusionModel.shaderName)
            pipelineState = try! device.makeComputePipelineState(function: kernelFunction!)//device.newComputePipelineStateWithFunction(kernelFunction!, completionHandler: nil)
            
            setUpTexture()
            run()
        }
    }

    var isRunning: Bool = false
    {
        didSet
        {
            if isRunning && oldValue != isRunning
            {
                self.run()
            }
        }
    }
    
    final func run()
    {
        if device == nil || !isRunning
        {
            return
        }
        
        Async.background()
        {
            self.image = self.applyFilter()
        }
        .main
        {
            self.imageView.image = self.image

            if self.useTextureAForInput
            {
                if self.newModelLoadedFlag
                {
                    self.newModelLoadedFlag = false
       
                    self.editor.reactionDiffusionModel = self.reactionDiffusionModel
                    
                    let kernelFunction = self.defaultLibrary.makeFunction(name: self.reactionDiffusionModel.shaderName)//.newFunctionWithName(self.reactionDiffusionModel.shaderName)
                    self.pipelineState = try! self.device.makeComputePipelineState(function: kernelFunction!)//.makeComputePipelineStateWithFunction(kernelFunction!)
                    
                    self.resetSimulationFlag = true
                }
                
                if self.resetSimulationFlag
                {
                    self.resetSimulationFlag = false
                    
                    self.setUpTexture()
                }
                
                if self.requestedReactionDiffusionModel != nil
                {
                    let _requestedReactionDiffusionModel = self.requestedReactionDiffusionModel!
                    
                    switch _requestedReactionDiffusionModel
                    {
                        case .GrayScott:
                            self.reactionDiffusionModel = GrayScott()
                        case .FitzHughNagumo:
                            self.reactionDiffusionModel = FitzhughNagumo()
                        case .BelousovZhabotinsky:
                            self.reactionDiffusionModel = BelousovZhabotinsky()
                    }
                    
                    self.requestedReactionDiffusionModel = nil
                    self.editor.reactionDiffusionModel = self.reactionDiffusionModel
                
                    let kernelFunction = self.defaultLibrary.makeFunction(name: self.reactionDiffusionModel.shaderName)
                    self.pipelineState = try! self.device.makeComputePipelineState(function: kernelFunction!)//newComputePipelineStateWithFunction(kernelFunction!, completionHandler: nil)
                }
            }
   
            let fps = Int( 1 / (CFAbsoluteTimeGetCurrent() - self.runTime))
            //println("\(fps) fps")
            self.runTime = CFAbsoluteTimeGetCurrent()
            
            self.run()
        }
    }

    func setUpTexture()
    {
        let imageRef = reactionDiffusionModel.initalImage.cgImage!

        threadGroupCount = MTLSizeMake(16, 16, 1)
        threadGroups = MTLSizeMake(Int(imageSide) / threadGroupCount.width, Int(imageSide) / threadGroupCount.height, 1)

        var rawData = [UInt8](repeating: 0, count: Int(imageSide * imageSide * 4))

        let context = CGContext(data: &rawData, width: imageSide, height: imageSide, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: rgbColorSpace, bitmapInfo: bitmapInfo.rawValue)
        
        context?.draw(imageRef, in: CGRect(x: 0, y: 0, width: CGFloat(imageSide), height: CGFloat(imageSide)))
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.rgba8Unorm, width: Int(imageSide), height: Int(imageSide), mipmapped: false)
        
        textureA = device.makeTexture(descriptor: textureDescriptor)
        
        let outTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: textureA.pixelFormat, width: textureA.width, height: textureA.height, mipmapped: false)
        textureB = device.makeTexture(descriptor: outTextureDescriptor)
        
        region = MTLRegionMake2D(0, 0, Int(imageSide), Int(imageSide))
        textureA.replace(region: region, mipmapLevel: 0, withBytes: &rawData, bytesPerRow: Int(bytesPerRow))
    }

    final func applyFilter() -> UIImage
    {
        let commandBuffer = commandQueue.makeCommandBuffer()
        let commandEncoder = commandBuffer.makeComputeCommandEncoder()
        
        commandEncoder.setComputePipelineState(pipelineState)
        
        var buffer: MTLBuffer = device.makeBuffer(bytes: &reactionDiffusionModel.reactionDiffusionStruct, length: MemoryLayout<ReactionDiffusionParameters>.size, options: [])
        commandEncoder.setBuffer(buffer, offset: 0, at: 0)
        
        commandQueue = device.makeCommandQueue()
        
        for _ in 0 ... reactionDiffusionModel.iterationsPerFrame
        {
            if useTextureAForInput
            {
                commandEncoder.setTexture(textureA, at: 0)
                commandEncoder.setTexture(textureB, at: 1)
            }
            else
            {
                commandEncoder.setTexture(textureB, at: 0)
                commandEncoder.setTexture(textureA, at: 1)
            }

            commandEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCount)

            useTextureAForInput = !useTextureAForInput
        }
        
        commandEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
  
        if !useTextureAForInput
        {
            textureB.getBytes(&imageBytes, bytesPerRow: Int(bytesPerRow), from: region, mipmapLevel: 0)
        }
        else
        {
            textureA.getBytes(&imageBytes, bytesPerRow: Int(bytesPerRow), from: region, mipmapLevel: 0)
        }
        
        let providerRef = CGDataProvider(data: Data(bytes: &imageBytes, count: providerLength) as CFData)
       
        let imageRef = CGImage(width: Int(imageSize.width), height: Int(imageSize.height), bitsPerComponent: bitsPerComponent, bitsPerPixel: bitsPerPixel, bytesPerRow: bytesPerRow, space: rgbColorSpace, bitmapInfo: bitmapInfo, provider: providerRef!, decode: nil, shouldInterpolate: false, intent: renderingIntent)

        return UIImage(cgImage: imageRef!)
    }

    
    override func viewDidLayoutSubviews()
    {
        if errorFlag
        {
            let alertController = UIAlertController(title: "ReDiLab v1.0\nReaction Diffusion Laboratory", message: "\nSorry! ReDiLab requires an iPad with an A7 or later processor. It appears your device is earlier.", preferredStyle: UIAlertControllerStyle.alert)

            present(alertController, animated: true, completion: nil)
            
            errorFlag = false
        }

        let imageSide = view.frame.height - topLayoutGuide.length
        
        imageView.frame = CGRect(x: 0, y: topLayoutGuide.length, width: imageSide, height: imageSide)
     
        let editorWidth = CGFloat(view.frame.width - imageSide)
        
        editor.frame = CGRect(x: imageSide, y: topLayoutGuide.length, width: editorWidth, height: imageSide)
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
}



