//
//  URLSessionHTTPClientTests.swift
//  SecondEssentialFeedTests
//
//  Created by Macbook on 8/10/20.
//  Copyright © 2020 Duy Bui. All rights reserved.
//

import XCTest
import SecondEssentialFeed

class URLSessionHTTPClientTests: XCTestCase {

  override func setUp() {
    super.setUp()
    URLProtocolStub.startInterceptingRequests()
  }

  override func tearDown() {
    super.tearDown()
    URLProtocolStub.stopInterceptingRequests()
  }

  func test_getFromURL_performsGETRequestWithURL() {

    let exp = expectation(description: "Wait for request")
    let url = anyURL()
    URLProtocolStub.observeRequests { request in
      XCTAssertEqual(request.url, url)
      XCTAssertEqual(request.httpMethod, "GET")
      exp.fulfill()
    }

    makeSUT().get(from: url) { _ in }
    wait(for: [exp], timeout: 1.0)
  }

  func test_getFromURL_failsOnRequestError() {
    let requestError = NSError(domain: "any error", code: 1)
    let receivedError = resultErrorFor(data: nil,
                                       response: nil,
                                       error: requestError)
    XCTAssertEqual(receivedError as NSError?, requestError)
  }

  func test_getFromURL_failsOnAllNilValues() {
    let data = anyData()
    let urlResponse = nonHTTPURLResponse()
    let httpURLResponse = anyHTTPURLResponse()
    let error = anyError()
    XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
    XCTAssertNotNil(resultErrorFor(data: nil, response: urlResponse, error: nil))
    XCTAssertNotNil(resultErrorFor(data: data, response: nil, error: nil))
    XCTAssertNotNil(resultErrorFor(data: data, response: nil, error: error))
    XCTAssertNotNil(resultErrorFor(data: nil, response: urlResponse, error: error))
    XCTAssertNotNil(resultErrorFor(data: nil, response: httpURLResponse, error: error))
    XCTAssertNotNil(resultErrorFor(data: data, response: urlResponse, error: error))
    XCTAssertNotNil(resultErrorFor(data: data, response: httpURLResponse, error: error))
    XCTAssertNotNil(resultErrorFor(data: data, response: urlResponse, error: nil))
  }

  func test_getFromURL_succeedsOnHTTPURLResponseWithData() {
    let data = anyData()
    let response = anyHTTPURLResponse()

    let resultValues = resultValuesFor(data: data,
                                       response: response,
                                       error: nil)

    XCTAssertEqual(resultValues?.data, data)
    XCTAssertEqual(resultValues?.response.url, response.url)
    XCTAssertEqual(resultValues?.response.statusCode, response.statusCode)
  }

  func test_getFromURL_succeedsWithEmptyDataOnHTTPURLResponseWithNilData() {
    let emptyData = Data()
    let response = anyHTTPURLResponse()

    let resultValues = resultValuesFor(data: nil,
                                       response: response,
                                       error: nil)

    XCTAssertEqual(resultValues?.data, emptyData)
    XCTAssertEqual(resultValues?.response.url, response.url)
    XCTAssertEqual(resultValues?.response.statusCode, response.statusCode)
  }

  private func resultErrorFor(data: Data?,
                              response: URLResponse?,
                              error: Error?,
                              file: StaticString = #file,
                              line: UInt = #line) -> Error? {

    let result = resultFor(data: data,
                           response: response,
                           error: error,
                           file: file,
                           line: line)
    switch result {
    case let .failure(error):
      return error
    default:
      XCTFail("Expected failure with error \(error), got \(result) instead", file: file, line: line)
      return nil
    }
  }

  private func resultValuesFor(data: Data?,
                               response: URLResponse?,
                               error: Error?,
                               file: StaticString = #file,
                               line: UInt = #line) -> (data: Data, response: HTTPURLResponse)? {

    let result = resultFor(data: data,
                           response: response,
                           error: error,
                           file: file,
                           line: line)
    switch result {
    case let .success(data, response):
      return (data, response)
    default:
      XCTFail("Expected success, got \(result) instead", file: file, line: line)
      return nil
    }
  }

  private func resultFor(data: Data?,
                         response: URLResponse?,
                         error: Error?,
                         file: StaticString = #file,
                         line: UInt = #line) -> HTTPClientResult {

    URLProtocolStub.stub(data: data,
                         response: response,
                         error: error)

    let sut = makeSUT(file: file, line: line)
    let exp = expectation(description: "Wait for completion")

    var receivedResult: HTTPClientResult!

    sut.get(from: anyURL()) { result in
      receivedResult = result
      exp.fulfill()
    }

    wait(for: [exp], timeout: 1.0)
    return receivedResult
  }

  private func makeSUT(file: StaticString = #file,
                       line: UInt = #line) -> HTTPClient {
    let sut = URLSessionHTTPClient()
    trackForMemoryLeaks(sut, file: file, line: line)
    return sut
  }

  private func anyURL() -> URL {
    URL(string: "http://any-url.com")!
  }

  private func anyData() -> Data {
    Data("any data".utf8)
  }

  private func nonHTTPURLResponse() -> URLResponse {
    URLResponse(url: anyURL(),
                mimeType: nil,
                expectedContentLength: 0,
                textEncodingName: nil)
  }

  private func anyHTTPURLResponse() -> HTTPURLResponse {
    HTTPURLResponse(url: anyURL(),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil)!
  }

  private func anyError() -> Error {
    NSError(domain: "any error",
            code: 0,
            userInfo: nil)
  }

  private class URLProtocolStub: URLProtocol {

    private static var stub: Stub?

    private struct Stub {
      let data: Data?
      let response: URLResponse?
      let error: Error?
    }

    static func startInterceptingRequests() {
      URLProtocol.registerClass(URLProtocolStub.self)
    }

    static func stopInterceptingRequests() {
      URLProtocol.unregisterClass(URLProtocolStub.self)
      stub = nil
      requestObserver = nil
    }

    private static var requestObserver: ((URLRequest) -> Void)?

    static func observeRequests(observer: @escaping (URLRequest) -> Void) {
      requestObserver = observer
    }

    static func stub(data: Data?,
                     response: URLResponse?,
                     error: Error? = nil) {
      stub = Stub(data: data,
                  response: response,
                  error: error)
    }

    override class func canInit(with request: URLRequest) -> Bool {
      requestObserver?(request)
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

