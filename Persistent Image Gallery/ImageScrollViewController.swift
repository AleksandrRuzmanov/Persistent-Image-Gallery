//
//  ImageScrollViewController.swift
//  Image Gallery
//
//  Created by Aleksandr on 20/02/2019.
//  Copyright © 2019 Aleksandr Ruzmanov. All rights reserved.
//

import UIKit

class ImageScrollViewController: UIViewController, UIScrollViewDelegate {
    
    
    var url: URL?
    
    @IBOutlet private weak var scrollView: UIScrollView! {
        didSet {
            scrollView.minimumZoomScale = 0.5
            scrollView.maximumZoomScale = 2.0
            scrollView.addSubview(imageView)
            scrollView.delegate = self
        }
    }
    
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    private func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    private var imageView = UIImageView()
    
    private func loadImage() {
        activityIndicator.startAnimating()
        DispatchQueue.global(qos: .userInitiated).async {
            if let imageURL = self.url {
                let urlContent = try? Data(contentsOf: imageURL)
                DispatchQueue.main.async {
                    if let imageData = urlContent,  imageURL == self.url {
                        let image = UIImage(data: imageData)
                        if image != nil {
                            self.imageView.image = image
                            self.imageView.sizeToFit()
                        } else {
                            self.imageView.backgroundColor = UIColor.red
                        }
                        self.scrollView.contentSize = self.imageView.frame.size
                        self.activityIndicator.stopAnimating()
                    }
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadImage()
    }
}
