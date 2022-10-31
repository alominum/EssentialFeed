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
    
    override class func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequests()
    }
    
    override class func tearDown() {
        super.tearDown()
        URLProtocolStub.stoptInterceptingRequests()
    }
    
    func test_getFromURL_performsGETrequestWithURL() {
        let url = URL(string: "http://a-url.com")!
        
        let exp = expectation(description: "Wait for request")
        URLProtocolStub.observeRequest { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        
        makeSUT().get(from: url) { _ in  }
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_getFromURL_FailsOnRequestError() {
        let url = URL(string: "http://a-url.com")!
        let error = NSError(domain: "error", code: 0)
        URLProtocolStub.stub(data: nil, response: nil,error: error)
        
        let exp = expectation(description: "Wait for client")
        
        makeSUT().get(from: url) { result in
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
    }
    
    // MARK: - Helpers
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeak(sut,file: file, line: line)
        return sut
    }
    
    private class URLProtocolStub : URLProtocol {
        private struct Stub {
            let response : HTTPURLResponse?
            let data : Data?
            let error : Error?
        }
        
        private static var stub : Stub?
        private static var requestObserver : ((URLRequest) -> Void)?
        
        static func stub(data : Data?, response : HTTPURLResponse?, error : Error?) {
            stub = Stub(response: response, data: data, error: error)
        }
        
        //MARK: Helpers
        static func startInterceptingRequests() {
            URLProtocolStub.registerClass(URLProtocolStub.self)
        }

        static func stoptInterceptingRequests() {
            URLProtocolStub.unregisterClass(URLProtocolStub.self)
            stub = nil
            requestObserver = nil
        }
        
        //MARK: - Protocol methods
        static func observeRequest(observer : @escaping (URLRequest) -> Void) {
            requestObserver = observer
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            requestObserver?(request)
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {
            
        }
    }
}
