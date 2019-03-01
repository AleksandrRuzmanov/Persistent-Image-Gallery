//
//  ImageScrollViewController.swift
//  Image Gallery
//
//  Created by Aleksandr on 20/02/2019.
//  Copyright © 2019 Aleksandr Ruzmanov. All rights reserved.
//

import UIKit

class ImageScrollViewController: UIViewController, UIScrollViewDelegate {
    
    
    var url: URL? {
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
    
    var cache: URLCache?
    
    @IBOutlet private weak var scrollView: UIScrollView! {
        didSet {
            scrollView.delegate = self
            scrollView.minimumZoomScale = 0.5
            scrollView.maximumZoomScale = 2.0
            scrollView.addSubview(imageView)
        }
    }
    
    
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    private var imageView = UIImageView()
    
    private var image: UIImage? {
        get {
            return imageView.image
        } set {
            activityIndicator?.stopAnimating()
            imageView.image = newValue
            imageView.sizeToFit()
            scrollView?.contentSize = imageView.frame.size
        }
    }
    
    private func loadImage() {
        let session = URLSession(configuration: .default)
        activityIndicator.startAnimating()
        if let imageURL = url {
            let request = URLRequest(url: imageURL)
            if let cashedResponse = cache?.cachedResponse(for: request), let image = UIImage(data: cashedResponse.data) {
                // if image is in cache
                self.image = image
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
                                self?.image = image
                            } else {
                                self?.scrollView.backgroundColor = UIColor.red
                            }
                        }
                    })
                    task.resume()
                }
            }
        }
    }
}
