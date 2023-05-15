//
//  queue.swift
//  xqueue
//
//  Created by xpwu on 2023/4/9.
//

import Foundation

class tCtx {
	@TaskLocal
	static var ctx: Int = 0
}

public class XQueue<T> {
	private var queue = Channel<(T) async ->Void>(buffer: .Unlimited)
	private var underlying: T?
	
	public init(_ initT: @escaping () async ->T) {
		Task {[unowned self] in
			let t = await initT()
			underlying = t
			
			await tCtx.$ctx.withValue(1) {
				while true {
					let run = await queue.Receive()
					await run(t)
				}
			}
		}
	}
}

extension XQueue {
	public func en<R>(block: @escaping (T) async ->R) async -> R {
		// process nest
		if tCtx.ctx == 1 {
			return await block(underlying!)
		}
		
		let ch = Channel<R>(buffer: 1)
		
		await queue.Send{t in
			await ch.Send(await block(t))
		}
		
		return await ch.Receive()
	}
}
