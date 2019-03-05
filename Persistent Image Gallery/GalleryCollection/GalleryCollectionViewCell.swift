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
    
    var aspectRatio: CGFloat? {
        didSet {
            if self.aspectRatio != nil {
                var cellFrameSize = self.frame.size
                cellFrameSize.height = cellFrameSize.width * self.aspectRatio!
                self.frame.size = cellFrameSize
            }
        }
    }
    
    func setImageFor(_ item: GalleryItem,  using imageFetcher: ImageFetcher) {
        activityIndicator.startAnimating()
        aspectRatio = CGFloat(item.aspectRatio)
        imageFetcher.fetchImageFor(item) { [weak self] (image) in
            if image != nil {
                self?.imageView.image = image
                self?.aspectRatio = image!.size.height / image!.size.width
            } else {
                self?.imageView.backgroundColor = UIColor.red
            }
            self?.activityIndicator.stopAnimating()
        }
    }
}
