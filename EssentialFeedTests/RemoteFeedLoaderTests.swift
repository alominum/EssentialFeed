//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Nima Nassehi on 2022-10-04.
//

import XCTest


class RemoteFeedLoader {

    
}

class  HTTPClient {

    var requestedURL : URL?
}

class RemoteFeedLoaderTests : XCTest {
    
    func test_init_doesNotRequestDataFromURL() {
        _ = RemoteFeedLoader()
        let client = HTTPClient()
        
        
        XCTAssertNil(client.requestedURL)
    }
}
