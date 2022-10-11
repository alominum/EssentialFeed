//
//  FeedItem.swift
//  EssentialFeed
//
//  Created by Nima Nassehi on 2022-10-04.
//

import Foundation

public struct FeedItem : Equatable
{
    let id : UUID
    let location: String?
    let description : String?
    let image : String
}
