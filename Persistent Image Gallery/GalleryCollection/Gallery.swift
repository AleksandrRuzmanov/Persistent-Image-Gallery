//
//  Gallery.swift
//  Image Gallery
//
//  Created by Aleksandr on 19/02/2019.
//  Copyright © 2019 Aleksandr Ruzmanov. All rights reserved.
//

import Foundation

struct Gallery: Codable {

    private var galleryItems = [GalleryItem]()
    
    mutating func addItem(_ item: GalleryItem, at index: Int) {
        galleryItems.insert(item, at: index)
    }
    
    mutating func addItemWith(aspectRatio: Double, url: URL? = nil, imageData: Data? = nil, at index: Int) {
        assert(!(url == nil && imageData == nil), "Both url and imageData are nil!")
        if url != nil {
            galleryItems.insert(GalleryItem(url: url!, aspectRatio: aspectRatio), at: index)
        } else if imageData != nil {
            galleryItems.insert(GalleryItem(imageData: imageData!, aspectRatio: aspectRatio), at: index)
        }
    }
    
    mutating func removeItem(at index: Int) {
        galleryItems.remove(at: index)
    }
    
    func getItem(at index: Int) -> GalleryItem? {
        return galleryItems[index]
    }
    
    func itemsCount() -> Int {
        return galleryItems.count
    }
    
    var json: Data? {
        return try? JSONEncoder().encode(self)
    }
    
    init() {
        
    }
    
    init?(json: Data) {
        if let newValue = try? JSONDecoder().decode(Gallery.self, from: json) {
            self = newValue
        } else {
            return nil
        }
    }
    
}




