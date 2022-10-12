//
//  FeedItemMapper.swift
//  EssentialFeed
//
//  Created by Nima Nassehi on 2022-10-12.
//

import Foundation

class FeedItemMapper {
    
    private static var OK_200 : Int { 200 }
    
    static func map(_ data : Data, _ response : HTTPURLResponse) throws -> [FeedItem] {
        if response.statusCode == OK_200,let root = try? JSONDecoder().decode(Root.self, from: data) {
            return root.items.map{$0.item}
        } else {
            throw RemoteFeedLoader.Error.invalidData
        }
    }
    
    private struct Root : Decodable {
        let items : [Item]
    }
    
    private struct Item : Decodable {
        let id : UUID
        let location: String?
        let description : String?
        let image : URL
        
        var item : FeedItem {
            return FeedItem(id: id, location: location, description: description, imageURL: image)
        }
    }
}
