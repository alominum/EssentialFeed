//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Nima Nassehi on 2022-10-04.
//

import XCTest


class RemoteFeedLoader {
    func load() {
        HTTPClient.shared.requestedURL = URL(string: "http://a-url")
    }
}

class  HTTPClient {
    static let shared = HTTPClient()
    
    private init() {}
    var requestedURL : URL?
}

class RemoteFeedLoaderTests : XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        _ = RemoteFeedLoader()
        let client = HTTPClient.shared
        
        XCTAssertNil(client.requestedURL)
    }
    
    func test_load_requestsDataFromURL() {
        let sut = RemoteFeedLoader()
        let client = HTTPClient.shared
        
        sut.load()
        
        XCTAssertNotNil(client.requestedURL)
    }
}
