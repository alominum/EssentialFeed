//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Nima Nassehi on 2022-10-04.
//

import Foundation

enum LoadFeedResult {
    case success([FeedItem])
    case failure(Error)
}

protocol FeedLoader {
    func loadFeed(completion : @escaping (LoadFeedResult) -> Void)
}
