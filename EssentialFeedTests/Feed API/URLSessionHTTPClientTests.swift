//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Nima Nassehi on 2022-10-24.
//

import XCTest
import EssentialFeed

final class URLSessionHTTPClientTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequests()
    }
    
    override func tearDown() {
        super.tearDown()
        URLProtocolStub.stoptInterceptingRequests()
    }
    
    func test_getFromURL_performsGETrequestWithURL() {
        let url = anyURL()
        
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
        let requestError = anyNSError()
        
        let receivedError = resultErrorFor(data: nil, response: nil, error: requestError) as NSError?
        
        XCTAssertEqual(receivedError?.domain,requestError.domain )
        XCTAssertEqual(receivedError?.code,requestError.code )
    }
    
    
    func test_getFromURL_FailsOnAllInvalidRepresentationCases() {
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: nil))
    }
    
    func test_getFromURL_successOnHTTPResponseAndData() {
        let data = anyData()
        let response = anyHTTPURLResponse()
        
        let receivedValues = resultValueFor(data: data, response: response, error: nil)
        
        XCTAssertEqual(receivedValues?.data, data)
        XCTAssertEqual(receivedValues?.response.statusCode, response.statusCode)
        XCTAssertEqual(receivedValues?.response.url, response.url)
    }
    
    func test_getFromURL_successWithEmptyDataOnHTTPResponseAndNilData() {
        let response = anyHTTPURLResponse()
        
        let receivedValues = resultValueFor(data: nil, response: response, error: nil)
        
        let emptyData = Data()
        XCTAssertEqual(receivedValues?.data, emptyData)
        XCTAssertEqual(receivedValues?.response.statusCode, response.statusCode)
        XCTAssertEqual(receivedValues?.response.url, response.url)
    }
    // MARK: - Helpers
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> HTTPClient {
        let sut = URLSessionHTTPClient()
        trackMemoryLeak(sut,file: file, line: line)
        return sut
    }
    
    private func resultValueFor(data: Data?, response: URLResponse?, error: Error?,file: StaticString = #filePath, line: UInt = #line) -> (data : Data,response: HTTPURLResponse)? {
        let result = resultFor(data: data, response: response, error: error)
        
        switch result {
        case let .success(data, response):
            return (data,response)
        default:
            XCTFail("We expected success, but got: \(result)",file: file,line: line)
            return nil
        }
    }
    
    private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?,file: StaticString = #filePath, line: UInt = #line) -> Error? {
        let result = resultFor(data: data, response: response, error: error)
        
        switch result {
        case let .failure(error as NSError):
            return error
        default:
            XCTFail("We expected error, but got: \(result)",file: file,line: line)
            return nil
        }
    }
    
    private func resultFor(data: Data?, response: URLResponse?, error: Error?,file: StaticString = #filePath, line: UInt = #line) -> HTTPClientResult {
        URLProtocolStub.stub(data: data, response: response,error: error)
        let sut = makeSUT(file: file,line: line)
        var receivedResult : HTTPClientResult!
        
        let exp = expectation(description: "Wait for client")
        
        sut.get(from: anyURL()) { result in
            receivedResult = result
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return receivedResult
    }
    
    private func anyURL() -> URL {
        return URL(string: "http://a-url.com")!
    }
    
    private func anyData() -> Data {
        return Data("json data".utf8)
    }
    
    private func nonHTTPURLResponse() -> URLResponse {
        return URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }
    
    private func anyHTTPURLResponse() -> HTTPURLResponse {
        return HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
    }
    
    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }
    
    private class URLProtocolStub : URLProtocol {
        private struct Stub {
            let response : URLResponse?
            let data : Data?
            let error : Error?
        }
        
        private static var stub : Stub?
        private static var requestObserver : ((URLRequest) -> Void)?
        
        static func stub(data : Data?, response : URLResponse?, error : Error?) {
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
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            if let requestObserver = URLProtocolStub.requestObserver {
                client?.urlProtocolDidFinishLoading(self)
                return requestObserver(request)
            }

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
