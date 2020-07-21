//
//  RemoteFeedLoaderTests.swift
//  SecondEssentialFeedTests
//
//  Created by Macbook on 7/21/20.
//  Copyright © 2020 Duy Bui. All rights reserved.
//

import XCTest

class RemoteFeedLoader {
  func load() {
    HTTPClient.shared.requestedURL = URL(string: "http://any-url.com")
  }
}

class HTTPClient {
  static let shared = HTTPClient()
  var requestedURL: URL?
}

class RemoteFeedLoaderTests: XCTestCase {

  func test_init_doesNotRequestDataFromURL() {
    let client = HTTPClient.shared
    let _ = RemoteFeedLoader()
    XCTAssertNil(client.requestedURL)
  }

  func test_load_requestDataFromURL() {
    let client = HTTPClient.shared
    let sut = RemoteFeedLoader()

    sut.load()

    XCTAssertNotNil(client.requestedURL)
  }
}
