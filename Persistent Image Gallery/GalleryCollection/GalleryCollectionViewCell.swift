//
//  GalleryCollectionViewCell.swift
//  Image Gallery
//
//  Created by Aleksandr on 15/02/2019.
//  Copyright © 2019 Aleksandr Ruzmanov. All rights reserved.
//

import UIKit

class GalleryCollectionViewCell: UICollectionViewCell {
    
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var imageView: UIImageView!
    
    var cellWidth: CGFloat = 128.0
    
    var cache: URLCache?
    
    var imageURL: URL?
    
    var aspectRatio: CGFloat? {
        didSet {
            if self.aspectRatio != nil {
                var cellFrameSize = self.frame.size
                cellFrameSize.width = cellWidth
                cellFrameSize.height = cellFrameSize.width * self.aspectRatio!
                self.frame.size = cellFrameSize
                imageView.sizeToFit()
            }
        }
    }
    
    func setupImageViewFor(_ item: GalleryItem, width: CGFloat, using cache: URLCache) {
        self.cache = cache
        let session = URLSession(configuration: .default)
        activityIndicator.startAnimating()
        imageURL = nil
        aspectRatio = nil
        cellWidth = width
        imageURL = item.url.imageURL
        aspectRatio = CGFloat(item.aspectRatio)
        if self.imageURL != nil {
            let request = URLRequest(url: self.imageURL!)
            if let cashedResponse = cache.cachedResponse(for: request), let image = UIImage(data: cashedResponse.data) {
                // if image is in cache
                self.imageView.image = image
                let aspectRatio = image.size.height / image.size.width
                self.aspectRatio = aspectRatio
                self.activityIndicator.stopAnimating()
            } else {
                // if image isn't in cache
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    let task = session.dataTask(with: request, completionHandler: { (urlData, urlResponse, urlError) in
                        DispatchQueue.main.async {
                            if urlError != nil {
                                print("Data request failed with error \(urlError!)")
                            }
                            if let data = urlData, let image = UIImage(data: data) {
                                if let response = urlResponse {
                                    self?.cache?.storeCachedResponse(CachedURLResponse(response: response, data: data), for: request)
                                }
                                self?.imageView.image = image
                                let aspectRatio = image.size.height / image.size.width
                                self?.aspectRatio = aspectRatio
                            } else {
                                self?.backgroundColor = UIColor.red
                            }
                            self?.activityIndicator.stopAnimating()
                        }
                    })
                    task.resume()
                }
            }
        }
    }
}
