//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Nima Nassehi on 2022-10-24.
//

import XCTest
import EssentialFeed

protocol HTTPSession {
    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSessionTask
}

protocol HTTPSessionTask {
    func resume()
}

class URLSessionHTTPClient {
    private let session : HTTPSession
    
    init(session : HTTPSession) {
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

    func test_getFromURL_resumesDataTaskWithURL() {
        let url = URL(string: "http://a-url.com")!
        let session = HTTPSessionSpy()
        let task = URLSessionDataTaskSpy()
        session.stub(url: url, task: task)
        let sut = URLSessionHTTPClient(session: session)
        sut.get(from: url) { _ in  }
        
        XCTAssertEqual(task.resumeCallCount, 1)
    }
    
    func test_getFromURL_FailsOnRequestError() {
        let url = URL(string: "http://a-url.com")!
        let session = HTTPSessionSpy()
        let error = NSError(domain: "error", code: 0)
        session.stub(url: url, error: error)
        let sut = URLSessionHTTPClient(session: session)
        
        let exp = expectation(description: "Wait for client")
        
        sut.get(from: url) { result in
            switch result {
            case let .failure(receivedError as NSError):
                XCTAssertEqual(error, receivedError)
            default:
                XCTFail("We expected error: \(error) but got: \(result)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
    
    // MARK: - Helpers
    private class HTTPSessionSpy : HTTPSession {
        private struct Stub {
            let task : HTTPSessionTask
            let error : Error?
        }
        
        private var stubs = [URL : Stub]()
        
        func stub(url:URL,task : HTTPSessionTask = FakeURLSessionDataTask(),error : Error? = nil ) {
            stubs[url] = Stub(task: task, error: error)
        }
        
        func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSessionTask {
            guard let stub = stubs[url] else {
                fatalError("No sub found for url: \(url).")
            }
            completionHandler(nil,nil,stub.error)
            return stub.task
        }
        
    }
    
    private class FakeURLSessionDataTask : HTTPSessionTask {
        func resume() {}
    }
    
    private class URLSessionDataTaskSpy : HTTPSessionTask {
        var resumeCallCount = 0

        func resume() {
            resumeCallCount += 1
        }
    }
}
