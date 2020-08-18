//
//  URLSessionHTTPClientTests.swift
//  SecondEssentialFeedTests
//
//  Created by Macbook on 8/10/20.
//  Copyright © 2020 Duy Bui. All rights reserved.
//

import XCTest
import SecondEssentialFeed

class URLSessionHTTPClient {
  private let session: URLSession
  init(session: URLSession = .shared) {
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

  func test_getFromURL_failsOnRequestError() {
    URLProtocolStub.startInterceptingRequests()

    let url = URL(string: "http://any-url.com")!
    let requestError = NSError(domain: "any error", code: 1)

    URLProtocolStub.stub(data: nil,
                         response: nil,
                         error: requestError)

    let sut = URLSessionHTTPClient()
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

    URLProtocolStub.stopInterceptingRequests()
  }

  private class URLProtocolStub: URLProtocol {

    private static var stub: Stub?

    private struct Stub {
      let data: Data?
      let response: HTTPURLResponse?
      let error: Error?
    }

    static func startInterceptingRequests() {
      URLProtocol.registerClass(URLProtocolStub.self)
    }

    static func stopInterceptingRequests() {
      URLProtocol.unregisterClass(URLProtocolStub.self)
      stub = nil
    }

    static func stub(data: Data?,
                     response: HTTPURLResponse?,
                     error: Error? = nil) {
      stub = Stub(data: data,
                        response: response,
                        error: error)
    }

    override class func canInit(with request: URLRequest) -> Bool {
      return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
      return request
    }

    override func startLoading() {

      if let data = URLProtocolStub.stub?.data {
        client?.urlProtocol(self, didLoad: data)
      }

      if let response = URLProtocolStub.stub?.response {
        client?.urlProtocol(self,
                            didReceive: response,
                            cacheStoragePolicy: .notAllowed)
      }

      if let error = URLProtocolStub.stub?.error {
        client?.urlProtocol(self, didFailWithError: error)
      }

      client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
  }
}

