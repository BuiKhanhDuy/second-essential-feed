//
//  RemoteFeedLoader.swift
//  SecondEssentialFeed
//
//  Created by Macbook on 7/22/20.
//  Copyright © 2020 Duy Bui. All rights reserved.
//

import Foundation

public class RemoteFeedLoader: FeedLoader {

  private let url: URL?
  private let client: HTTPClient

  public enum Error: Swift.Error {
    case connectivity
    case invalidData
  }

  public typealias Result = LoadFeedResult

  public init(url: URL?, client: HTTPClient) {
    self.url = url
    self.client = client
  }

  public func load(completion: @escaping (Result) -> Void) {
    client.get(from: url) { [weak self] result in
      guard self != nil else { return }
      switch result {
      case .failure:
        completion(.failure(Error.connectivity))
      case let .success(data, response):
        completion(FeedItemsMapper.map(data, from: response))
      }
    }
  }
}
