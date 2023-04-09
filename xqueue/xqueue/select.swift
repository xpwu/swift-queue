//
//  select.swift
//  xqueue
//
//  Created by xpwu on 2023/4/9.
//

import Foundation

//public protocol Selector {
//	associatedtype E
//	func resume(_ e:E) async
//}
//
//extension Channel {
//	public func OnRecive<R, S: Selector>(selector: S, block: @escaping (E)async ->R) ->Void where S.E == R {
//		Task {
//			let value = await self.Receive()
//			let r = await block(value)
//			await selector.resume(r)
//		}
//	}
//}

actor once {
	var suspend: Bool = true
	
	// 修改状态，并返回之前是否是 suspend
	func `do`() -> Bool {
		if !suspend {
			return false
		}
		
		suspend = false
		return true
	}
}

//public func select<R, S: Selector>(builder: (S)->Void) async ->R where S.E == R {
//	return await withCheckedContinuation{ (c: CheckedContinuation<R, Never>) in
//		let s = selector(c)
//		builder(s)
//	}
//}

public func select<R>(_ asyncs: [()async ->R]) async ->R {
	let once = once()
	
	return await withCheckedContinuation{ (c: CheckedContinuation<R, Never>) in
		for asy in asyncs {
			// todo: cancel else task
			Task {
				let r = await asy()
				if await once.do() {
					c.resume(returning: r)
				}
			}
		}
	}
}

public func race<R>(_ asyncs: [()async ->R]) async ->R {
	return await select(asyncs)
}

