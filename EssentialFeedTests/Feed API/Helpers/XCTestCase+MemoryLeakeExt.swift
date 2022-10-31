//
//  XCTestCase+MemoryLeakeExt.swift
//  EssentialFeedTests
//
//  Created by Nima Nassehi on 2022-10-31.
//

import XCTest

extension XCTestCase {
    func trackForMemoryLeak(_ instance : AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance,"sut needs to be deallocated.",file: file,line: line)
        }
    }
}
