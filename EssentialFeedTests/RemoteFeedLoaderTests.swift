//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Nima Nassehi on 2022-10-04.
//

import XCTest
import EssentialFeed

class RemoteFeedLoaderTests : XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let (_ , client) = makeSUT()
        
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestsDataFromURL() {
        let url = URL(string: "http://a-given-url.com")!
        let (sut , client) = makeSUT(url: url)
        
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "http://a-given-url.com")!
        let (sut , client) = makeSUT(url: url)
        
        sut.load { _ in }
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url,url])
    }
    
    func test_load_DeliversErrorOnClientsError() {
        let (sut , client) = makeSUT()
        var capturedErrors = [RemoteFeedLoader.Error]()
        
        sut.load { capturedErrors.append($0) }
        
        let clientError = NSError(domain: "Test", code: 0)
        client.complete(with: clientError)
        
        XCTAssertEqual(capturedErrors, [.connectivity])
    }

    func test_load_DeliversErrorOnInvalidData() {
        let (sut , client) = makeSUT()

        let samples = [199,201,300,400,500]
        samples.enumerated().forEach { index, code in

            var capturedErrors = [RemoteFeedLoader.Error]()
            
            sut.load { capturedErrors.append($0) }
            
            client.complete(withStatusCode: code,at: index)
        
            XCTAssertEqual(capturedErrors, [.invalidData])
        }
    }
    
    func test_laod_DeliversErrorOn200ResponseWithInvalidJSON() {
        let (sut , client) = makeSUT()
        var capturedErrors = [RemoteFeedLoader.Error]()
        
        sut.load { capturedErrors.append($0) }
        
        let invalidJSON = Data("invalid json".utf8)
        client.complete(withStatusCode: 200, data : invalidJSON)
    
        XCTAssertEqual(capturedErrors, [.invalidData])
    }
    
    //MARK: - Helpers
    private func makeSUT(url: URL = URL(string: "http://a-url")!) -> (sut: RemoteFeedLoader,client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut,client)
    }
    
    private class HTTPClientSpy : HTTPClient {
        var messages = [(url : URL,completion : (HTTPClientResult) -> Void)]()
        var requestedURLs : [URL] { messages.map{ $0.url }}
        
        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url,completion))
        }
        
        func complete(with error: Error,at index : Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(withStatusCode status: Int,data : Data = Data(), at index : Int = 0) {
            let response = HTTPURLResponse(url: messages[index].url, statusCode: status, httpVersion: nil, headerFields: nil)!
            messages[index].completion(.success(data, response))
        }
    }

}
