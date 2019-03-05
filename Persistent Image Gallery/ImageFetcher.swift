//
//  ImageFetcher.swift
//  Persistent Image Gallery
//
//  Created by Aleksandr on 05/03/2019.
//  Copyright © 2019 Aleksandr Ruzmanov. All rights reserved.
//

import UIKit

class ImageFetcher {
    
    var cache: URLCache?
    
    func fetchImageFor(_ item: GalleryItem, finished: @escaping (UIImage?) -> ()) {
        var image: UIImage? {
            didSet {
                DispatchQueue.main.async {
                    finished(image)
                }
            }
        }
        assert(!(item.imageData == nil && item.url == nil), "Item has neither URL nor imageData!")
            if let url = item.url {
                let session = URLSession(configuration: .default)
                let request = URLRequest(url: url.imageURL)
                if let cashedResponse = cache?.cachedResponse(for: request), let fetchedImage = UIImage(data: cashedResponse.data) {
                    // if image is in cache
                    image = fetchedImage
                } else {
                    // if image isn't in cache
                    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                        let task = session.dataTask(with: request, completionHandler: { (urlData, urlResponse, urlError) in
                            if urlError != nil {
                                print("Data request failed with error \(urlError!)")
                            }
                            if let data = urlData, let fetchedImage = UIImage(data: data) {
                                if let response = urlResponse {
                                    self?.cache?.storeCachedResponse(CachedURLResponse(response: response, data: data), for: request)
                                }
                                image = fetchedImage
                            }
                        })
                        task.resume()
                    }
                }
            } else if let imageData = item.imageData, let fetchedImage = UIImage(data: imageData) {
                // if image is represented as Data
                image = fetchedImage
            }
    }
}
