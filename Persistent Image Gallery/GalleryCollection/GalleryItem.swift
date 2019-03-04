//
//  GalleryItem.swift
//  Image Gallery
//
//  Created by Aleksandr on 19/02/2019.
//  Copyright © 2019 Aleksandr Ruzmanov. All rights reserved.
//

import Foundation

struct GalleryItem: Codable {
    
    var imageData: Data?
    
    var url: URL?
    
    var aspectRatio: Double
    
    
    init(url: URL, aspectRatio: Double) {
        self.url = url
        self.aspectRatio = aspectRatio
    }
    
    init(imageData: Data, aspectRatio: Double) {
        self.imageData = imageData
        self.aspectRatio = aspectRatio
    }
}
