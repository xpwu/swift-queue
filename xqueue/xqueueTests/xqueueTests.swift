//
//  xqueueTests.swift
//  xqueueTests
//
//  Created by xpwu on 2023/4/9.
//

import XCTest
@testable import xqueue

class xqueueTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
	
	func testChannel1() async {
		let expectation = self.expectation(description: "testChannel1")
		
		let ch = Channel<Int>(buffer: 0)
		
		Task {
			let ret = await ch.Receive()
			XCTAssertEqual(ret, 10)
			expectation.fulfill()
		}
		
		Task {
			await ch.Send(10)
		}
		
		self.wait(for: [expectation], timeout: 10)
	}
	
	func testChannel2() async {
		let expectation = self.expectation(description: "testChannel2")
		
		let ch = Channel<Int>(buffer: 0)
		
		Task {
			await ch.Send(10)
		}
		
		let ret = await ch.Receive()
		XCTAssertEqual(ret, 10)
		expectation.fulfill()
		
		self.wait(for: [expectation], timeout: 10)
	}
	
	func testChannel3() async {
		let expectation = self.expectation(description: "testChannel3")
		
		let ch = Channel<Int>(buffer: 0)
		
		Task {
			let ret = await ch.Receive()
			XCTAssertEqual(ret, 10)
			expectation.fulfill()
		}
		
		await ch.Send(10)

		self.wait(for: [expectation], timeout: 10)
	}
	
	func testChannelMore() async {
		let expectation = self.expectation(description: "testChannelMore")
		
		let ch = Channel<Int>(buffer: .Unlimited)
		
		let count = 100
		let sumA = sum()
		
		Task {
			var sum = 0
			for _ in 0..<count {
				sum += await ch.Receive()
			}
			let a = await sumA.result()
			
			XCTAssertEqual(sum, a)
			expectation.fulfill()
		}
		
		for _ in 0..<count {
			Task {
				let v = Int.random(in: 0..<1000)
				await sumA.add(v)
				await ch.Send(v)
			}
		}
		
		self.wait(for: [expectation], timeout: 10)
	}

}

actor sum {
	var value = 0
	func add(_ v: Int) {
		value += v
	}
	
	func result()->Int {
		return value
	}
}
