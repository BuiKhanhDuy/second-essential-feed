//
//  RemoteFeedLoader.swift
//  SecondEssentialFeed
//
//  Created by Macbook on 7/22/20.
//  Copyright © 2020 Duy Bui. All rights reserved.
//

import Foundation

public protocol HTTPClient {
  func get(from url: URL?, completion: @escaping  (Error) -> Void)
}

public class RemoteFeedLoader {
  private let url: URL?
  private let client: HTTPClient

  public enum Error: Swift.Error {
    case connectivity
  }

  public init(url: URL?, client: HTTPClient) {
    self.url = url
    self.client = client
  }

  public func load(completion: @escaping (Error) -> Void) {
    client.get(from: url) { _ in
      completion(.connectivity)
    }
  }
}
