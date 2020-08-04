//
//  RemoteFeedLoader.swift
//  SecondEssentialFeed
//
//  Created by Macbook on 7/22/20.
//  Copyright © 2020 Duy Bui. All rights reserved.
//

import Foundation

public class RemoteFeedLoader {
  private let url: URL?
  private let client: HTTPClient

  public enum Error: Swift.Error {
    case connectivity
    case invalidData
  }

  public enum Result: Equatable {
    case success([FeedItem])
    case failure(Error)
  }

  public init(url: URL?, client: HTTPClient) {
    self.url = url
    self.client = client
  }

  public func load(completion: @escaping (Result) -> Void) {
    client.get(from: url) { result in
      switch result {
      case .failure:
        completion(.failure(.connectivity))
      case let .success(data, response):
        completion(self.map(data, from: response))
      }
    }
  }

  private func map(_ data: Data, from response: HTTPURLResponse) -> Result {
    do {
      let items = try FeedItemsMapper.map(data, response)
      return .success(items)
    } catch {
      return .failure(.invalidData)
    }
  }
}
