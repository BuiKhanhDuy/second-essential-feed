//
//  HTTPClient.swift
//  SecondEssentialFeed
//
//  Created by Macbook on 8/4/20.
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
