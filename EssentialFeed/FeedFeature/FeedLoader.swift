//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Nima Nassehi on 2022-10-04.
//

import Foundation

public enum LoadFeedResult{
    case success([FeedItem])
    case failure(Error)
}

public protocol FeedLoader {
    func load(completion : @escaping (LoadFeedResult) -> Void)
}
