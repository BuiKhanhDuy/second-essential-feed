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

  func test_load_deliversErrorOnNon200HTTPResponseWithEmptyJSONList() {
    let (sut, client) = makeSUT()
    expect(sut,
           toCompleteWithResult: .failure(.invalidData),
           when: {
            let emptyJSONList = Data("{\"items\": []}".utf8)
            client.complete(withStatusCode: 400, data: emptyJSONList)
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

    let feedItem1 = makeItem(id: UUID(), imageURL: URL(string: "http://a-url.com")!)
    let feedItem2 = makeItem(id: UUID(), description: "a description", location: "a location", imageURL: URL(string: "http://a-url.com")!)

    let json = makeItemsJSON([feedItem1.json, feedItem2.json])

    expect(sut,
           toCompleteWithResult: .success([feedItem1.model, feedItem2.model]),
           when: {
      client.complete(withStatusCode: 200, data: json)
    })
  }

  // MARK: - Helpers
  private func makeSUT(url: URL? = URL(string: "http://any-url.com")) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
    let client = HTTPClientSpy()
    let sut = RemoteFeedLoader(url: url, client: client)
    return (sut, client)
  }

  private func makeItem(id: UUID,
                        description: String? = nil,
                        location: String? = nil,
                        imageURL: URL) -> (model: FeedItem, json: [String: Any]) {
    let item = FeedItem(id: id,
                         description: description,
                         location: location,
                         imageURL: imageURL)
    let json = [
      "id": id.uuidString,
      "description": description,
      "location": location,
      "image": imageURL.absoluteString
    ].compactMapValues { $0 }

    return (item, json)
  }

  private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
    let json = ["items": items]
    return try! JSONSerialization.data(withJSONObject: json)
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
