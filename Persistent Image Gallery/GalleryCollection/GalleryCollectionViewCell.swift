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
    
    private var cellWidth: CGFloat = 128.0
    
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
    
    func setupImageViewFor(_ item: GalleryItem, width: CGFloat) {
        activityIndicator.startAnimating()
        imageURL = nil
        aspectRatio = nil
        cellWidth = width
        imageURL = item.url.imageURL
        aspectRatio = CGFloat(item.aspectRatio)
        DispatchQueue.global(qos: .userInitiated).async {
            if self.imageURL != nil {
                let urlContent = try? Data(contentsOf: self.imageURL!)
                DispatchQueue.main.async {
                    if let imageData = urlContent, item.url.imageURL == self.imageURL {
                        let image = UIImage(data: imageData)
                        if image != nil {
                            self.imageView.image = image
                            let aspectRatio = image!.size.height / image!.size.width
                            self.aspectRatio = aspectRatio
                        } else {
                            self.backgroundColor = UIColor.red
                        }
                        self.activityIndicator.stopAnimating()
                    }
                }
            }
        }
    }
}
