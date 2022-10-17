//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Nima Nassehi on 2022-10-04.
//

import Foundation

public enum LoadFeedResult<Error : Swift.Error> {
    case success([FeedItem])
    case failure(Error)
}

public protocol FeedLoader {
    associatedtype Error : Swift.Error
    func load(completion : @escaping (LoadFeedResult<Error>) -> Void)
}
