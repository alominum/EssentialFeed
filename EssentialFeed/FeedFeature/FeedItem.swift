//
//  FeedItem.swift
//  EssentialFeed
//
//  Created by Nima Nassehi on 2022-10-04.
//

import Foundation

public struct FeedItem : Equatable
{
    public let id : UUID
    public let location: String?
    public let description : String?
    public let imageURL : URL
    
    public  init(id: UUID, location: String?, description: String?, imageURL: URL) {
        self.id = id
        self.location = location
        self.description = description
        self.imageURL = imageURL
    }
}

