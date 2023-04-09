//
//  queue.swift
//  xqueue
//
//  Created by xpwu on 2023/4/9.
//

import Foundation

class XQueue<T> {
	private var queue = Channel<(T) async ->Void>(buffer: .Unlimited)
	
	init(_ initT: @escaping () async ->T) {
		Task {
			let t = await initT()
			
			while true {
				let run = await queue.Receive()
				await run(t)
			}
		}
	}
}

extension XQueue {
	func en<R>(block: @escaping (T) async ->R) async -> R {
		let ch = Channel<R>(buffer: 1)
		
		await queue.Send{t in
			await ch.Send(await block(t))
		}
		
		return await ch.Receive()
	}
}
