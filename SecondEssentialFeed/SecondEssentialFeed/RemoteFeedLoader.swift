//
//  RemoteFeedLoader.swift
//  SecondEssentialFeed
//
//  Created by Macbook on 7/22/20.
//  Copyright © 2020 Duy Bui. All rights reserved.
//

import Foundation

public enum HTTPClientResult {
  case success(Data, HTTPURLResponse)
  case failure(Error)
}

public protocol HTTPClient {
  func get(from url: URL?,
           completion: @escaping (HTTPClientResult) -> Void)
}

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
      case let .success(data, _):
        if let root = try? JSONDecoder().decode(Root.self, from: data) {
          completion(.success(root.items.map { $0.item }))
        } else {
          completion(.failure(.invalidData))
        }
      }
    }
  }
}

private struct Root: Decodable {
  let items: [Item]
}

private struct Item: Decodable {
  let id: UUID
  let description: String?
  let location: String?
  let image: URL

  var item: FeedItem {
    return FeedItem(id: id,
                    description: description,
                    location: location,
                    imageURL: image)
  }
}
