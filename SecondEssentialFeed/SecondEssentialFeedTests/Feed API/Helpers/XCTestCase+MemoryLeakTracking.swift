//
//  XCTestCase+MemoryLeakTracking.swift
//  SecondEssentialFeedTests
//
//  Created by Macbook on 8/18/20.
//  Copyright © 2020 Duy Bui. All rights reserved.
//

import XCTest

extension XCTestCase {
  func trackForMemoryLeaks(_ instance: AnyObject,
                                   file: StaticString = #file,
                                   line: UInt = #line) {
    addTeardownBlock { [weak instance] in
      XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.",
                   file: file,
                   line: line)
    }
  }
}
