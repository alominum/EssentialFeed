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
        
        expect(sut, toCompleteWith: failure(.connectivity)) {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        }
    }

    func test_load_DeliversErrorOnInvalidData() {
        let (sut , client) = makeSUT()

        let samples = [199,201,300,400,500]
        samples.enumerated().forEach { index, code in
            
            expect(sut, toCompleteWith: failure(.invalidData)) {
                let jsonData = makeItemsJSON(items: [])
                client.complete(withStatusCode: code,data: jsonData, at: index)
            }
        }
    }
    
    func test_laod_DeliversErrorOn200ResponseWithInvalidJSON() {
        let (sut , client) = makeSUT()
        
        expect(sut, toCompleteWith: failure(.invalidData)) {
            let invalidJSON = Data("invalid json".utf8)
            client.complete(withStatusCode: 200,data: invalidJSON)
        }
    }
    
    func test_load_DeliversNoItemsOnHTTP200WithEmptyJSONList() {
        let (sut,client) = makeSUT()
        
        expect(sut, toCompleteWith: .success([])) {
            let emptyListJSON = makeItemsJSON(items: [])
            client.complete(withStatusCode: 200,data: emptyListJSON)
        }
    }
    
    func test_load_DeliversArraysOfFeedItemsWith200REsponse() {
        let (sut,client) = makeSUT()
        
        let item1 = makeItem(id: UUID(), imageURL: URL(string: "http://an-image-url")!)
        let item2 = makeItem(id: UUID(), location: "a location", description: "a description", imageURL: URL(string: "http://another-image-url")!)
        
        let items = [item1,item2]
        
        expect(sut, toCompleteWith: .success(items.map{$0.item})) {
            let jsonData = makeItemsJSON(items: items.map{$0.json})
            client.complete(withStatusCode: 200,data: jsonData)
        }
    }
    
    func test_load_DoNotDeliverFeedAfterDeallocation() {
        let url = URL(string: "http://a-url.com")!
        let client = HTTPClientSpy()
        var sut : RemoteFeedLoader? = RemoteFeedLoader(url: url, client: client)
        
        var capturedResult = [RemoteFeedLoader.Result]()
        sut?.load { capturedResult.append($0) }
                  
        sut = nil
        client.complete(withStatusCode: 200, data: makeItemsJSON(items: []))
        
        XCTAssertTrue(capturedResult.isEmpty)
    }
    
    //MARK: - Helpers
    private func makeSUT(url: URL = URL(string: "http://a-url")!, file: StaticString = #filePath, line: UInt = #line) -> (sut: RemoteFeedLoader,client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        trackMemoryLeak(sut,file: file,line: line)
        trackMemoryLeak(client,file: file,line: line)
        return (sut,client)
    }
    
    private func failure(_ error : RemoteFeedLoader.Error) -> RemoteFeedLoader.Result {
        .failure(error)
    }
        
    private func makeItem(id: UUID, location: String? = nil, description: String? = nil, imageURL: URL) -> (item : FeedItem, json : [String : Any]){
        let item = FeedItem(id: id, location: location, description: description, imageURL: imageURL)
        let json = [
            "id" : item.id.uuidString,
            "location" : item.location,
            "description" : item.description,
            "image" : item.imageURL.absoluteString
        ].reduce(into: [String:Any]()) {(acc,e) in
            if let value = e.value { acc[e.key] = value }
        }
        return (item,json)
    }
    
    private func makeItemsJSON(items : [[String : Any]]) -> Data {
        let json = [ "items" : items]
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    private func expect(_ sut : RemoteFeedLoader,toCompleteWith expectedResult: RemoteFeedLoader.Result, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "wait for load to complete.")
        
        sut.load { receivedResult in
            switch (expectedResult,receivedResult) {
            case let (.success(expectedItems),.success(receivedItems)):
                XCTAssertEqual(expectedItems, receivedItems,file: file,line: line)
            case let (.failure(expectedError as RemoteFeedLoader.Error),.failure(receivedError as RemoteFeedLoader.Error)):
                XCTAssertEqual(expectedError, receivedError,file: file,line: line)
            default:
                XCTFail("Expected result \(expectedResult) but reeived \(receivedResult)",file: file,line: line)
            }
            exp.fulfill()
        }
        
        action()
    
        wait(for: [exp], timeout: 1.0)
        
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
        
        func complete(withStatusCode status: Int,data : Data, at index : Int = 0) {
            let response = HTTPURLResponse(url: messages[index].url, statusCode: status, httpVersion: nil, headerFields: nil)!
            messages[index].completion(.success(data, response))
        }
    }

}
