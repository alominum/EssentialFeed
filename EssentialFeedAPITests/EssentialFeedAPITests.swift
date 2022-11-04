//
//  EssentialFeedAPITests.swift
//  EssentialFeedAPITests
//
//  Created by Nima Nassehi on 2022-11-04.
//

import XCTest
import EssentialFeed

class EssentialFeedAPITests: XCTestCase {
    
    func test_EndToEndTestServerGETFeedResult_MatchesData() {
        switch getFeedResult() {
        case let .success(items):
            XCTAssertEqual(items.count, 8,"Expected 8 items in the API payload.")
            
            XCTAssertEqual(items[0], expectedItem(at: 0))
            XCTAssertEqual(items[1], expectedItem(at: 1))
            XCTAssertEqual(items[2], expectedItem(at: 2))
            XCTAssertEqual(items[3], expectedItem(at: 3))
            XCTAssertEqual(items[4], expectedItem(at: 4))
            XCTAssertEqual(items[5], expectedItem(at: 5))
            XCTAssertEqual(items[6], expectedItem(at: 6))
            XCTAssertEqual(items[7], expectedItem(at: 7))
            
        case let .failure(error):
            XCTFail("Expected success but got \(error) instead")
        default:
            XCTFail("Expected success but got nothing")
        }
    }

    // Helpers
    private let urlString = "https://essentialdeveloper.com/feed-case-study/test-api/feed"
    
    private let payload : [[String : String]] = [
        ["id": "73A7F70C-75DA-4C2E-B5A3-EED40DC53AA6",
        "description": "Description 1",
        "location": "Location 1",
        "image": "https://url-1.com"],
        ["id": "BA298A85-6275-48D3-8315-9C8F7C1CD109",
               "location": "Location 2",
               "image": "https://url-2.com"],
        ["id": "5A0D45B3-8E26-4385-8C5D-213E160A5E3C",
         "description": "Description 3",
         "image": "https://url-3.com"],
        ["id": "FF0ECFE2-2879-403F-8DBE-A83B4010B340",
         "image": "https://url-4.com"],
        ["id": "DC97EF5E-2CC9-4905-A8AD-3C351C311001",
         "description": "Description 5",
         "location": "Location 5",
         "image": "https://url-5.com"],
        ["id": "557D87F1-25D3-4D77-82E9-364B2ED9CB30",
         "description": "Description 6",
         "location": "Location 6",
         "image": "https://url-6.com"],
        ["id": "A83284EF-C2DF-415D-AB73-2A9B8B04950B",
         "description": "Description 7",
         "location": "Location 7",
         "image": "https://url-7.com"],
        ["id": "F79BD7F8-063F-46E2-8147-A67635C3BB01",
         "description": "Description 8",
         "location": "Location 8",
         "image": "https://url-8.com"]
    ]

    private func expectedItem(at index : Int) -> FeedItem {
        return FeedItem(id: UUID(uuidString: payload[index]["id"] ?? "noId") ?? UUID(),
                 location: payload[index]["location"],
                 description: payload[index]["description"],
                 imageURL: URL(string: payload[index]["image"] ?? "no image url")!)
    }
    
    private func getFeedResult() -> LoadFeedResult? {
        let url = URL(string: urlString)!
        let client = URLSessionHTTPClient()
        let loader = RemoteFeedLoader(url: url, client: client)
        
        var capturedResult : LoadFeedResult?
        let exp = expectation(description: "Wait for API")
        loader.load { result in
            capturedResult = result
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 5.0)
        return capturedResult
    }
}
