//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Nima Nassehi on 2022-10-24.
//

import XCTest
import EssentialFeed

class URLSessionHTTPClient {
    private let session : URLSession
    
    init(session : URLSession = .shared) {
        self.session = session
    }
    
    func get(from url : URL,completion :@escaping (HTTPClientResult)-> Void) {
        session.dataTask(with: url) { _, _, error in
            if let error = error {
                completion(.failure(error))
            }
        }.resume()
    }
}

final class URLSessionHTTPClientTests: XCTestCase {
    
    func test_getFromURL_FailsOnRequestError() {
        URLProtocolStub.startInterceptingRequests()
        let url = URL(string: "http://a-url.com")!
        let error = NSError(domain: "error", code: 0)
        URLProtocolStub.stub(url: url, data: nil, response: nil,error: error)
        let sut = URLSessionHTTPClient()
        
        let exp = expectation(description: "Wait for client")
        
        sut.get(from: url) { result in
            switch result {
            case let .failure(receivedError as NSError):
                XCTAssertEqual(error.domain, receivedError.domain)
                XCTAssertEqual(error.code, receivedError.code)
            default:
                XCTFail("We expected error: \(error) but got: \(result)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        URLProtocolStub.stoptInterceptingRequests()
    }
    
    // MARK: - Helpers
    private class URLProtocolStub : URLProtocol {
        private struct Stub {
            let response : HTTPURLResponse?
            let data : Data?
            let error : Error?
        }
        
        private static var stubs = [URL : Stub]()
        
        static func stub(url:URL,data : Data?,response : HTTPURLResponse?, error : Error?) {
            stubs[url] = Stub(response: response, data: data, error: error)
        }
        
        //MARK: Helpers
        static func startInterceptingRequests() {
            URLProtocolStub.registerClass(URLProtocolStub.self)
        }

        static func stoptInterceptingRequests() {
            URLProtocolStub.unregisterClass(URLProtocolStub.self)
        }
        
        //MARK: - Protocol methods
        
        override class func canInit(with request: URLRequest) -> Bool {
            guard let url = request.url else { return false }
            
            return URLProtocolStub.stubs[url] != nil
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            guard let url = request.url, let stub = URLProtocolStub.stubs[url] else { return }
            
            if let data = stub.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = stub.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let error = stub.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {
            
        }
    }
}
