//
//  RemoteFeedLoaderTests.swift
//  SecondEssentialFeedTests
//
//  Created by Macbook on 7/21/20.
//  Copyright © 2020 Duy Bui. All rights reserved.
//

import XCTest

class RemoteFeedLoader {
  let client: HTTPClient
  let url: URL?
  init(url: URL?, client: HTTPClient) {
    self.client = client
    self.url = url
  }
  func load() {
    client.get(from: url)
  }
}

protocol HTTPClient {
  func get(from url: URL?)
}

class HTTPClientSpy: HTTPClient {
  var requestedURL: URL?
  func get(from url: URL?) {
    requestedURL = url
  }
}

class RemoteFeedLoaderTests: XCTestCase {

  func test_init_doesNotRequestDataFromURL() {
    let anyURL = URL(string: "http://any-url.com")
    let client = HTTPClientSpy()
    let _ = RemoteFeedLoader(url: anyURL, client: client)
    XCTAssertNil(client.requestedURL)
  }

  func test_load_requestDataFromURL() {
    let anyURL = URL(string: "http://any-url.com")
    let client = HTTPClientSpy()
    let sut = RemoteFeedLoader(url: anyURL, client: client)
    sut.load()
    XCTAssertEqual(client.requestedURL, anyURL)
  }
}
