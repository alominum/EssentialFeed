//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Nima Nassehi on 2022-10-04.
//

import XCTest


class RemoteFeedLoader {
    let client : HTTPClient
    init (client : HTTPClient) {
        self.client = client
    }
    
    func load() {
        client.get(from: URL(string: "http://a-url")!)
    }
}

protocol HTTPClient {
    func get(from url : URL)
}

class HTTPClientSpy : HTTPClient {
    func get(from url: URL) {
        requestedURL = url
    }
    var requestedURL: URL?
}
class RemoteFeedLoaderTests : XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let client = HTTPClientSpy()
        _ = RemoteFeedLoader(client: client)
        
        XCTAssertNil(client.requestedURL)
    }
    
    func test_load_requestsDataFromURL() {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(client: client)
        
        sut.load()
        
        XCTAssertNotNil(client.requestedURL)
    }
}
