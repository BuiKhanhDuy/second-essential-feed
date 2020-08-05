//
//  FeedLoader.swift
//  SecondEssentialFeed
//
//  Created by Macbook on 7/21/20.
//  Copyright © 2020 Duy Bui. All rights reserved.
//

import Foundation

public enum LoadFeedResult {
  case success([FeedItem])
  case failure(Error)
}

protocol FeedLoader {
  func load(completion: @escaping (LoadFeedResult) -> Void)
}
