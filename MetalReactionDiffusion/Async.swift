//
//  Async.swift
//
//  Created by Tobias DM on 15/07/14.
//
//	OS X 10.10+ and iOS 8.0+
//	Only use with ARC
//
//	The MIT License (MIT)
//	Copyright (c) 2014 Tobias Due Munk
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy of
//	this software and associated documentation files (the "Software"), to deal in
//	the Software without restriction, including without limitation the rights to
//	use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//	the Software, and to permit persons to whom the Software is furnished to do so,
//	subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//	FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//	COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//	IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//	CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


import Foundation

private class GCD {
    
    /* dispatch_get_queue() */
    class func mainQueue() -> DispatchQueue {
        return DispatchQueue.main
        // Could use return dispatch_get_global_queue(qos_class_main().id, 0)
    }
    class func userInteractiveQueue() -> DispatchQueue {
        return DispatchQueue.global(qos: .userInteractive)//.global(priority: DispatchQoS.QoSClass.userInteractive.id)
    }
    class func userInitiatedQueue() -> DispatchQueue {
        return DispatchQueue.global(qos: .userInitiated)//priority: DispatchQoS.QoSClass.userInitiated.id)
    }
    class func defaultQueue() -> DispatchQueue {
        return DispatchQueue.global(qos: .default)//priority: DispatchQoS.QoSClass.default.id)
    }
    class func utilityQueue() -> DispatchQueue {
        return DispatchQueue.global(qos: .utility)//priority: DispatchQoS.QoSClass.utility.id)
    }
    class func backgroundQueue() -> DispatchQueue {
        return DispatchQueue.global(qos: .background)//priority: DispatchQoS.QoSClass.background.id)
    }
}


public struct Async {
    
    fileprivate let block: DispatchWorkItem
    
    fileprivate init(_ block: DispatchWorkItem) {
        self.block = block
    }
}


extension Async { // Static methods
    
    
    /* dispatch_async() */
    
    fileprivate static func async(_ block: @escaping ()->(), inQueue queue: DispatchQueue) -> Async {
        // Create a new block (Qos Class) from block to allow adding a notification to it later (see matching regular Async methods)
        // Create block with the "inherit" type
        let _block = DispatchWorkItem(block: block) //dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, block)
        // Add block to queue
        queue.async(execute: _block)
        // Wrap block in a struct since dispatch_block_t can't be extended
        return Async(_block)
    }
    static func main(_ block: @escaping ()->()) -> Async {
        return Async.async(block, inQueue: GCD.mainQueue())
    }
    static func userInteractive(_ block: @escaping ()->()) -> Async {
        return Async.async(block, inQueue: GCD.userInteractiveQueue())
    }
    static func userInitiated(_ block: @escaping ()->()) -> Async {
        return Async.async(block, inQueue: GCD.userInitiatedQueue())
    }
    static func default_(_ block: @escaping ()->()) -> Async {
        return Async.async(block, inQueue: GCD.defaultQueue())
    }
    static func utility(_ block: @escaping ()->()) -> Async {
        return Async.async(block, inQueue: GCD.utilityQueue())
    }
    static func background(_ block: @escaping ()->()) -> Async {
        return Async.async(block, inQueue: GCD.backgroundQueue())
    }
    static func customQueue(_ queue: DispatchQueue, block: @escaping ()->()) -> Async {
        return Async.async(block, inQueue: queue)
    }
    
    
    /* dispatch_after() */
    
    fileprivate static func after(_ seconds: Double, block: @escaping ()->(), inQueue queue: DispatchQueue) -> Async {
        let nanoSeconds = Int64(seconds * Double(NSEC_PER_SEC))
        let time = DispatchTime.now() + Double(nanoSeconds) / Double(NSEC_PER_SEC)
        return at(time, block: block, inQueue: queue)
    }
    fileprivate static func at(_ time: DispatchTime, block: @escaping ()->(), inQueue queue: DispatchQueue) -> Async {
        // See Async.async() for comments
        
        let _block = DispatchWorkItem(block: block)// dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, block)
        queue.asyncAfter(deadline: time, execute: _block)
        return Async(_block)
    }
    static func main(_ after: Double, _ block: @escaping ()->()) -> Async {
        return Async.after(after, block: block, inQueue: GCD.mainQueue())
    }
    static func userInteractive(_ after: Double, _ block: @escaping ()->()) -> Async {
        return Async.after(after, block: block, inQueue: GCD.userInteractiveQueue())
    }
    static func userInitiated(_ after: Double, _ block: @escaping ()->()) -> Async {
        return Async.after(after, block: block, inQueue: GCD.userInitiatedQueue())
    }
    static func default_(_ after: Double, _ block: @escaping ()->()) -> Async {
        return Async.after(after, block: block, inQueue: GCD.defaultQueue())
    }
    static func utility(_ after: Double, _ block: @escaping ()->()) -> Async {
        return Async.after(after, block: block, inQueue: GCD.utilityQueue())
    }
    static func background(_ after: Double, _ block: @escaping ()->()) -> Async {
        return Async.after(after, block: block, inQueue: GCD.backgroundQueue())
    }
    static func customQueue(_ after: Double, _ queue: DispatchQueue, block: @escaping ()->()) -> Async {
        return Async.after(after, block: block, inQueue: queue)
    }
}


extension Async { // Regualar methods matching static once
    
    
    /* dispatch_async() */
    
    fileprivate func chain(block chainingBlock: @escaping ()->(), runInQueue queue: DispatchQueue) -> Async {
        // See Async.async() for comments
        let _chainingBlock = DispatchWorkItem(block: chainingBlock)// dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, chainingBlock)
        self.block.notify(queue: queue, execute: _chainingBlock)
        return Async(_chainingBlock)
    }
    
    func main(_ chainingBlock: @escaping ()->()) -> Async {
        return chain(block: chainingBlock, runInQueue: GCD.mainQueue())
    }
    func userInteractive(_ chainingBlock: @escaping ()->()) -> Async {
        return chain(block: chainingBlock, runInQueue: GCD.userInteractiveQueue())
    }
    func userInitiated(_ chainingBlock: @escaping ()->()) -> Async {
        return chain(block: chainingBlock, runInQueue: GCD.userInitiatedQueue())
    }
    func default_(_ chainingBlock: @escaping ()->()) -> Async {
        return chain(block: chainingBlock, runInQueue: GCD.defaultQueue())
    }
    func utility(_ chainingBlock: @escaping ()->()) -> Async {
        return chain(block: chainingBlock, runInQueue: GCD.utilityQueue())
    }
    func background(_ chainingBlock: @escaping ()->()) -> Async {
        return chain(block: chainingBlock, runInQueue: GCD.backgroundQueue())
    }
    func customQueue(_ queue: DispatchQueue, chainingBlock: @escaping ()->()) -> Async {
        return chain(block: chainingBlock, runInQueue: queue)
    }
    
    
    /* dispatch_after() */
    
    fileprivate func after(_ seconds: Double, block chainingBlock: @escaping ()->(), runInQueue queue: DispatchQueue) -> Async {
        
        // Create a new block (Qos Class) from block to allow adding a notification to it later (see Async)
        // Create block with the "inherit" type
        let _chainingBlock = DispatchWorkItem(block: chainingBlock)// dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, chainingBlock)
        
        // Wrap block to be called when previous block is finished
        let chainingWrapperBlock: ()->() = {
            // Calculate time from now
            let nanoSeconds = Int64(seconds * Double(NSEC_PER_SEC))
            let time = DispatchTime.now() + Double(nanoSeconds) / Double(NSEC_PER_SEC)
            queue.asyncAfter(deadline: time, execute: _chainingBlock)
        }
        // Create a new block (Qos Class) from block to allow adding a notification to it later (see Async)
        // Create block with the "inherit" type
        let _chainingWrapperBlock = DispatchWorkItem(block: chainingWrapperBlock)//dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, chainingWrapperBlock)
        // Add block to queue *after* previous block is finished
        self.block.notify(queue: queue, execute: _chainingWrapperBlock)
//        dispatch_block_notify(self.block, queue, _chainingWrapperBlock)
        // Wrap block in a struct since dispatch_block_t can't be extended
        return Async(_chainingBlock)
    }
    func main(_ after: Double, _ block: @escaping ()->()) -> Async {
        return self.after(after, block: block, runInQueue: GCD.mainQueue())
    }
    func userInteractive(_ after: Double, _ block: @escaping ()->()) -> Async {
        return self.after(after, block: block, runInQueue: GCD.userInteractiveQueue())
    }
    func userInitiated(_ after: Double, _ block: @escaping ()->()) -> Async {
        return self.after(after, block: block, runInQueue: GCD.userInitiatedQueue())
    }
    func default_(_ after: Double, _ block: @escaping ()->()) -> Async {
        return self.after(after, block: block, runInQueue: GCD.defaultQueue())
    }
    func utility(_ after: Double, _ block: @escaping ()->()) -> Async {
        return self.after(after, block: block, runInQueue: GCD.utilityQueue())
    }
    func background(_ after: Double, _ block: @escaping ()->()) -> Async {
        return self.after(after, block: block, runInQueue: GCD.backgroundQueue())
    }
    func customQueue(_ after: Double, _ queue: DispatchQueue, block: @escaping ()->()) -> Async {
        return self.after(after, block: block, runInQueue: queue)
    }
    
    
    /* cancel */
    
    func cancel() {
        self.block.cancel()
//        dispatch_block_cancel(block)
    }
    
    
    /* wait */
    
    /// If optional parameter forSeconds is not provided, use DISPATCH_TIME_FOREVER
    func wait(_ seconds: Double = 0.0) {
        if seconds != 0.0 {
            let nanoSeconds = Int64(seconds * Double(NSEC_PER_SEC))
            let time = DispatchTime.now() + Double(nanoSeconds) / Double(NSEC_PER_SEC)
            let _ = self.block.wait(timeout: time)
//            dispatch_block_wait(block, time)
        } else {
            let _ = self.block.wait(wallTimeout: .distantFuture)
//            dispatch_block_wait(block, DispatchTime.distantFuture)
        }
    }
}
