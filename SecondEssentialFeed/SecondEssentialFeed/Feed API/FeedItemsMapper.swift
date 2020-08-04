//
//  FeedItemsMapper.swift
//  SecondEssentialFeed
//
//  Created by Macbook on 8/4/20.
//  Copyright © 2020 Duy Bui. All rights reserved.
//

import Foundation

internal final class FeedItemsMapper {

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

  internal static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [FeedItem] {
    guard response.statusCode == 200 else {
      throw RemoteFeedLoader.Error.invalidData
    }
    let root = try JSONDecoder().decode(Root.self, from: data)
    return root.items.map { $0.item }
  }
}
