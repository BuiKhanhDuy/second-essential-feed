//
//  URLSessionHTTPClientTests.swift
//  SecondEssentialFeedTests
//
//  Created by Macbook on 8/10/20.
//  Copyright © 2020 Duy Bui. All rights reserved.
//

import XCTest
import SecondEssentialFeed

protocol HTTPClient {
  func dataTask(with url: URL,
                completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPClientDataTask
}

protocol HTTPClientDataTask {
  func resume()
}

class URLSessionHTTPClient {
  private let session: HTTPClient
  init(session: HTTPClient) {
    self.session = session
  }

  func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
    session.dataTask(with: url) { (_, _, error) in
        if let error = error {
          completion(.failure(error))
        }
    }.resume()
  }
}

class URLSessionHTTPClientTests: XCTestCase {

  func test_getFromURL_resumesDataTaskWithURL() {
    let url = URL(string: "http://any-url.com")!
    let session = URLSessionSpy()
    let task = URLSessionDataTaskSpy()
    let sut = URLSessionHTTPClient(session: session)
    session.stub(url: url, task: task)
    sut.get(from: url) { _ in }

    XCTAssertEqual(task.resumeCallCount, 1)
  }

  func test_getFromURL_failsOnRequestError() {
    let url = URL(string: "http://any-url.com")!
    let requestError = NSError(domain: "any error", code: 1)
    let session = URLSessionSpy()
    session.stub(url: url, error: requestError)

    let sut = URLSessionHTTPClient(session: session)

    let exp = expectation(description: "Wait for completion")
    sut.get(from: url) { result in
      switch result {
      case let .failure(receivedError as NSError):
        XCTAssertEqual(receivedError, requestError)
      default:
        XCTFail("Expected error with \(requestError), got \(result) instead")
      }
      exp.fulfill()
    }
    wait(for: [exp], timeout: 1.0)
  }

  private class URLSessionSpy: HTTPClient {

    private var stubs = [URL: Stub]()

    private struct Stub {
      let task: HTTPClientDataTask
      let error: Error?
    }

    func stub(url: URL, task: HTTPClientDataTask = FakeURLSessionDataTask(), error: Error? = nil) {
      stubs[url] = Stub(task: task, error: error)
    }

    func dataTask(with url: URL,
                           completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPClientDataTask {
      guard let stub = stubs[url] else {
        fatalError("Couldn't find stub for \(url)")
      }
      completionHandler(nil, nil, stub.error)
      return stub.task
    }
  }

  private class FakeURLSessionDataTask: HTTPClientDataTask {
    func resume() {}
  }

  private class URLSessionDataTaskSpy: HTTPClientDataTask {
    var resumeCallCount = 0
    func resume() {
      resumeCallCount += 1
    }
  }
}

