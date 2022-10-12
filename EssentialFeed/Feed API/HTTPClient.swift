//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Nima Nassehi on 2022-10-12.
//

import Foundation

public enum HTTPClientResult {
    case success(Data,HTTPURLResponse)
    case failure(Error)
}

public protocol HTTPClient {
    func get(from url : URL, completion : @escaping (HTTPClientResult) -> Void)
}
