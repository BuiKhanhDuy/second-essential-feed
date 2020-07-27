//
//  RemoteFeedLoaderTests.swift
//  SecondEssentialFeedTests
//
//  Created by Macbook on 7/21/20.
//  Copyright © 2020 Duy Bui. All rights reserved.
//

import XCTest
import SecondEssentialFeed

class RemoteFeedLoaderTests: XCTestCase {

  func test_init_doesNotRequestDataFromURL() {
    let (_, client) = makeSUT()
    XCTAssertTrue(client.requestedURLs.isEmpty)
  }

  func test_load_requestsDataFromURL() {
    let anyURL = URL(string: "http://a-url.com")
    let (sut, client) = makeSUT(url: anyURL)
    sut.load { _ in }
    XCTAssertEqual(client.requestedURLs, [anyURL])
  }

  func test_loadTwice_requestsDataFromURLTwice() {
    let anyURL = URL(string: "http://a-url.com")
    let (sut, client) = makeSUT(url: anyURL)
    sut.load { _ in }
    sut.load { _ in }
    XCTAssertEqual(client.requestedURLs, [anyURL, anyURL])
  }

  func test_load_deliversConnectivityErrorOnClientError() {
    let (sut, client) = makeSUT()

    var capturedErrors = [RemoteFeedLoader.Error]()
    sut.load { capturedErrors.append($0) }

    let clientError = NSError(domain: "any error", code: 0)
    client.complete(with: clientError)

    XCTAssertEqual(capturedErrors, [.connectivity])
  }

  func test_load_deliversInvalidErrorNon200HTTPResponse() {
    let (sut, client) = makeSUT()
    let samples = [199, 201, 300, 400, 500]

    samples.enumerated().forEach { (index, value) in
      var capturedErrors = [RemoteFeedLoader.Error]()
      sut.load { capturedErrors.append($0) }

      client.complete(withStatusCode: value, at: index)
      XCTAssertEqual(capturedErrors, [.invalidData])
    }
  }

  // MARK: - Helpers

  private func makeSUT(url: URL? = URL(string: "http://any-url.com")) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
    let client = HTTPClientSpy()
    let sut = RemoteFeedLoader(url: url, client: client)
    return (sut, client)
  }

  private class HTTPClientSpy: HTTPClient {
    var requestedURLs: [URL?] {
      return messages.map { $0.url }
    }

    var messages = [(url: URL?, completions: ((HTTPClientResult) -> Void))]()

    func get(from url: URL?, completion: @escaping (HTTPClientResult) -> Void) {
      messages.append((url, completion))
    }

    func complete(with error: Error, at index: Int = 0) {
      messages[index].completions(.failure(error))
    }

    func complete(withStatusCode: Int, at index: Int = 0) {
      let response = HTTPURLResponse(url: messages[index].url!,
                                     statusCode: withStatusCode,
                                     httpVersion: nil,
                                     headerFields: nil)
      messages[index].completions(.success(response!))
    }
  }
}
