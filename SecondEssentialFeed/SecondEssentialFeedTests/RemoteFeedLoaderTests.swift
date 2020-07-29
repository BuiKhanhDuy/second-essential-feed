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

    expect(sut,
           toCompleteWithResult: .failure(.connectivity),
           when: {
            let clientError = NSError(domain: "any error", code: 0)
            client.complete(with: clientError)
    })
  }

  func test_load_deliversErrorOnNon200HTTPResponse() {
    let (sut, client) = makeSUT()
    let samples = [199, 201, 300, 400, 500]

    samples.enumerated().forEach { (index, value) in
      expect(sut,
             toCompleteWithResult: .failure(.invalidData),
             when: {
              client.complete(withStatusCode: value, at: index)
      })
    }
  }

  func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
    let (sut, client) = makeSUT()
    expect(sut,
           toCompleteWithResult: .failure(.invalidData),
           when: {
            let invalidJSON = Data("invalidJSON".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
    })
  }

  func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() {
    let (sut, client) = makeSUT()
    expect(sut,
           toCompleteWithResult: .success([]),
           when: {
            let emptyJSONList = Data("{\"items\": []}".utf8)
            client.complete(withStatusCode: 200, data: emptyJSONList)
    })
  }

  func test_load_deliversItemsOn200HTTPResponseWithJSONItems() {
    let (sut, client) = makeSUT()

    let item1 = FeedItem(
      id: UUID(),
      description: nil,
      location: nil,
      imageURL: URL(string: "http://a-url.com")!)

    let item1JSON = [
      "id": item1.id.uuidString,
      "image": item1.imageURL.absoluteString
    ]

    let item2 = FeedItem(
      id: UUID(),
      description: "a description",
      location: "a location",
      imageURL: URL(string: "http://another-url.com")!)

    let item2JSON = [
      "id": item2.id.uuidString,
      "description": item2.description,
      "location": item2.location,
      "image": item2.imageURL.absoluteString
    ]

    let itemsJSON = [
      "items": [item1JSON, item2JSON]
    ]

    expect(sut,
           toCompleteWithResult: .success([item1, item2]),
           when: {
      let json = try! JSONSerialization.data(withJSONObject: itemsJSON)
      client.complete(withStatusCode: 200, data: json)
    })
  }

  // MARK: - Helpers
  private func makeSUT(url: URL? = URL(string: "http://any-url.com")) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
    let client = HTTPClientSpy()
    let sut = RemoteFeedLoader(url: url, client: client)
    return (sut, client)
  }

  private func expect(_ sut: RemoteFeedLoader,
                      toCompleteWithResult result: RemoteFeedLoader.Result,
                      when action: () -> Void,
                      file: StaticString = #file,
                      line: UInt = #line) {
    var capturedResults = [RemoteFeedLoader.Result]()
    sut.load { capturedResults.append($0) }
    action()
    XCTAssertEqual(capturedResults, [result], file: file, line: line)
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

    func complete(withStatusCode: Int, data: Data = Data(), at index: Int = 0) {
      let response = HTTPURLResponse(url: messages[index].url!,
                                     statusCode: withStatusCode,
                                     httpVersion: nil,
                                     headerFields: nil)
      messages[index].completions(.success(data, response!))
    }
  }
}
