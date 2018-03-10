//
//  VideoModels.swift
//  YouTubePlayListsForKids
//
//  Created by Xiaomei Huang on 1/23/18.
//  Copyright © 2018 Xiaomei Huang. All rights reserved.
//

import Foundation

struct Videos: Codable {
    let items: [Video]
    //   var nextPageToken: String
}

struct Video: Codable {
    let id: ID
    let snippet: Snippet
 //   let contentDetails: ContentDetails
}

struct ContentDetails: Codable {
    let duration: String
}

struct ID: Codable {
    let kind: String
    let videoId: String?
    let playlistId: String?
    let channelId: String?
}

struct Snippet: Codable {
    let channelId: String
    let title: String
    let description: String
    let thumbnails: ItemThumbnail?
}


struct ItemThumbnail:Codable {
    let medium: ThumbnailMedium
}

struct ThumbnailMedium:Codable {
    let url: String
}

struct PlayList: Codable {
    let items: [PlaylistItem]
    let pageInfo: PageInfo
    let nextPageToken: String?
    //  let nextPageToken: String
}

struct PageInfo: Codable {
    let totalResults: Int
}

struct PlaylistItem: Codable {
    let id: String
    let snippet: PlayListItemSnippet
}

struct PlayListItemSnippet: Codable {
    let title: String
    let description: String
    let thumbnails: ItemThumbnail?
    let resourceId: ResourceId
    let channelId: String
}

struct ResourceId: Codable {
    let videoId: String
}

struct ThumbnailContent:Codable {
    let url: String
}

struct Thumbnail:Codable {
    let medium: ThumbnailContent
}



struct VideoDetails: Codable {
    let items: [VideoDetail]
}

struct VideoDetail: Codable {
    let id: String
    let snippet: Snippet
    let contentDetails: ContentDetails
}

struct ChannelPlayLists: Codable {
    let items: [ChannelPlayList]
}

struct ChannelPlayList: Codable {
    let id: String
    let snippet: Snippet
    let contentDetails: ChannelContentDetails
}

struct ChannelContentDetails:Codable {
    let itemCount: Int
}


struct SearchResult: Codable {
    let video: Video
    var isSelected: Bool
    init(video: Video) {
        self.video = video
        self.isSelected = false
    }
}
struct PlayListSearchResult: Codable {
    let playlistItem: PlaylistItem
    var isSelected: Bool
    init(playlistItem: PlaylistItem) {
        self.playlistItem = playlistItem
        self.isSelected = false
    }
}
