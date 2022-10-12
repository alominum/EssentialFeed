//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Nima Nassehi on 2022-10-11.
//

import Foundation

public final class RemoteFeedLoader {
    private let url : URL
    private let client : HTTPClient
    
    public enum Error : Swift.Error {
        case connectivity
        case invalidData
    }
    
    public enum Result : Equatable{
        case success([FeedItem])
        case failure(Error)
    }
    
    public init (url : URL, client : HTTPClient) {
        self.client = client
        self.url = url
    }
    
    public func load(completion : @escaping (Result) -> Void) {
        client.get(from: url) { result in
            switch result {
            case let .success(data, response):
                do {
                    completion(.success(try FeedItemMapper.map(data, response)))
                } catch {
                    completion(.failure(.invalidData))
                }

            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }
}
