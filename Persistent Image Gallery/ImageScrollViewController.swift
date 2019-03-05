//
//  ImageScrollViewController.swift
//  Image Gallery
//
//  Created by Aleksandr on 20/02/2019.
//  Copyright © 2019 Aleksandr Ruzmanov. All rights reserved.
//

import UIKit

class ImageScrollViewController: UIViewController, UIScrollViewDelegate {
    
    var imageFetcher: ImageFetcher?
    
    var galleryItem: GalleryItem? {
        didSet {
            imageView.image = nil
            if view.window != nil {
                loadImage()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if imageView.image == nil {
            loadImage()
        }
    }
    
    @IBOutlet private weak var scrollView: UIScrollView! {
        didSet {
            scrollView.delegate = self
            scrollView.minimumZoomScale = 0.25
            scrollView.maximumZoomScale = 2.0
            scrollView.addSubview(imageView)
        }
    }
    
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    private var imageView = UIImageView()
    
    private func loadImage() {
        activityIndicator.startAnimating()
        if let item = galleryItem {
            imageFetcher?.fetchImageFor(item) { [weak self] (image) in
                if image != nil {
                    self?.imageView.image = image
                    self?.imageView.sizeToFit()
                    if let size = self?.imageView.frame.size {
                        self?.scrollView?.contentSize = size
                    }
                } else {
                    self?.imageView.backgroundColor = UIColor.red
                }
                self?.activityIndicator.stopAnimating()
            }
        }
    }
}
