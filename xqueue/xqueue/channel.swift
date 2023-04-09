//
//  channel.swift
//  xqueue
//
//  Created by xpwu on 2023/4/9.
//

import Foundation

public protocol SendChannel {
	associatedtype E
	func Send(_ e: E) async
	func Close()
}

public protocol ReceiveChannel {
	associatedtype E
	func Receive() async -> E
}

class node<E> {
	var element: E
	var next: node<E>? = nil
	
	init(_ e: E) {
		element = e
	}
}

class queue<E> {
	var first: node<E>? = nil
	var last: node<E>? = nil
	var count: Int = 0
	
	func en(_ e: E) {
		// is empty
		defer {
			self.count += 1
		}
		
		guard let last = last else {
			self.last = node(e)
			first = self.last
			return
		}
		
		last.next = node(e)
		self.last = last.next
	}
	
	func de()-> E? {
		guard let first = first else {
			return nil
		}

		let ret = first.element
		self.first = first.next
		
		// empty
		if self.first == nil {
			self.last = nil
			self.count = 0
		}
		
		self.count -= 1
		
		return ret
	}
}

actor channel<E> {
	var data: queue<E> = queue()
	var sendSuspend: queue<()->Void> = queue()
	var receiveSuspend: queue<()->Void> = queue()
	var max: Int
	
	init(_ max: Int = 0) {
		self.max = max
	}
	
//	func send(_ e: E) async {
//		data.en(e)
//		receiveSuspend.de()?()
//
//		if data.count < max {
//			return
//		}
//
//		await withCheckedContinuation {
//			(continuation: CheckedContinuation<Void, Never>)->Void in
//
//			sendSuspend.en({
//				continuation.resume()
//			})
//		}
//	}
	
	func send(_ e:E, waiting: @escaping ()->Void) ->(todo: (()->Void)?, needWait: Bool) {
		data.en(e)
		let todo = receiveSuspend.de()
		var needWait = false
		
		if data.count >= max {
			sendSuspend.en(waiting)
			needWait = true
		}
		
		return (todo, needWait)
	}
	
	// return if value == nil {need wait} else {not need wait}
	func receive(waiting: @escaping (E)->Void) async ->(todo: (()->Void)?, value: E?) {
		let value = data.de()
		let todo = sendSuspend.de()
		
		if value == nil {
			receiveSuspend.en {[unowned self] in
				waiting(self.data.de()!)
			}
		}
		
		return (todo, value)
	}

//	func receive() async -> E {
//		let v = data.de()
//		sendSuspend.de()?()
//
//		if v != nil {
//			return v!
//		}
//
//		return await withCheckedContinuation {
//			(continuation: CheckedContinuation<E, Never>)->Void in
//
//			receiveSuspend.en { [unowned self] in
//				let v = self.data.de()
//				continuation.resume(with: .success(v!))
//			}
//		}
//	}
}

public class Channel<E> {
	var chan: channel<E>
	
	init(buffer: Int = 0) {
		chan = channel(buffer)
	}
}

extension Int {
	public static let Unlimited: Int = Int.max
}

extension Channel: SendChannel {
	public func Close() {
		// todo
	}
	
	public func Send(_ e: E) async {
		await withCheckedContinuation({ (continuation: CheckedContinuation<Void, Never>) in
			Task {
				let (todo, needWait) = await chan.send(e) {
					continuation.resume()
				}
				
				todo?()
				
				if !needWait {
					continuation.resume()
				}
			}
		})
	}
}

extension Channel: ReceiveChannel {
	public func Receive() async -> E {
		await withCheckedContinuation({ (continuation: CheckedContinuation<E, Never>) in
			Task {
				let (todo, value) = await chan.receive {value in
					continuation.resume(with: .success(value))
				}
				
				todo?()
				
				if value != nil {
					continuation.resume(with: .success(value!))
				}
			}
		})
	}
}
