//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Nima Nassehi on 2022-10-04.
//

import XCTest


class RemoteFeedLoader {
    func load() {
        HTTPClient.shared.get(from: URL(string: "http://a-url")!)
    }
}

class  HTTPClient {
    static var shared = HTTPClient()
    
    func get(from url : URL) {}

}

class HTTPClientSpy : HTTPClient {
    override func get(from url: URL) {
        requestedURL = url
    }
    var requestedURL: URL?
}
class RemoteFeedLoaderTests : XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        _ = RemoteFeedLoader()
        let client = HTTPClientSpy()
        HTTPClient.shared = client
        
        XCTAssertNil(client.requestedURL)
    }
    
    func test_load_requestsDataFromURL() {
        let sut = RemoteFeedLoader()
        let client = HTTPClientSpy()
        HTTPClient.shared = client
        
        sut.load()
        
        XCTAssertNotNil(client.requestedURL)
    }
}
