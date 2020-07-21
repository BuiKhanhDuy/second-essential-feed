//
//  RemoteFeedLoaderTests.swift
//  SecondEssentialFeedTests
//
//  Created by Macbook on 7/21/20.
//  Copyright © 2020 Duy Bui. All rights reserved.
//

import XCTest

class RemoteFeedLoader {

}

class HTTPClient {
  var requestedURL: URL?
}

class RemoteFeedLoaderTests: XCTestCase {

  func test_init_doesNotRequestDataFromURL() {
    let client = HTTPClient()
    let _ = RemoteFeedLoader()
    XCTAssertNil(client.requestedURL)
  }
}
