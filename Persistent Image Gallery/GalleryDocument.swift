//
//  GalleryDocument.swift
//  Persistent Image Gallery
//
//  Created by Aleksandr on 28/02/2019.
//  Copyright © 2019 Aleksandr Ruzmanov. All rights reserved.
//

import UIKit

class GalleryDocument: UIDocument {
    
    var gallery: Gallery?
    var thumbnailImage: UIImage?
    
    override func contents(forType typeName: String) throws -> Any {
        return gallery?.json ?? Data()
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        if let json = contents as? Data {
            gallery = Gallery(json: json)
        }
    }
}

