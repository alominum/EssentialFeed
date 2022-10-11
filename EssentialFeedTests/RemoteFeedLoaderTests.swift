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
        
        expect(sut, toCompleteWith: .failure(.connectivity)) {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        }
    }

    func test_load_DeliversErrorOnInvalidData() {
        let (sut , client) = makeSUT()

        let samples = [199,201,300,400,500]
        samples.enumerated().forEach { index, code in
            
            expect(sut, toCompleteWith: .failure(.invalidData)) {
                client.complete(withStatusCode: code,at: index)
            }
        }
    }
    
    func test_laod_DeliversErrorOn200ResponseWithInvalidJSON() {
        let (sut , client) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(.invalidData)) {
            let invalidJSON = Data("invalid json".utf8)
            client.complete(withStatusCode: 200,data: invalidJSON)
        }
    }
    
    func test_load_DeliversNoItemsOnHTTP200WithEmptyJSONList() {
        let (sut,client) = makeSUT()
        
        expect(sut, toCompleteWith: .success([])) {
            let emptyListJSON = Data("{\"items\" : []}".utf8)
            client.complete(withStatusCode: 200,data: emptyListJSON)
        }
    }
    
    //MARK: - Helpers
    private func makeSUT(url: URL = URL(string: "http://a-url")!) -> (sut: RemoteFeedLoader,client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut,client)
    }
    
    private func expect(_ sut : RemoteFeedLoader,toCompleteWith result: RemoteFeedLoader.Result, when action: @escaping () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        var capturedResults = [RemoteFeedLoader.Result]()
        
        sut.load { capturedResults.append($0) }
        
        action()
    
        XCTAssertEqual(capturedResults, [result],file: file,line: line)
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
