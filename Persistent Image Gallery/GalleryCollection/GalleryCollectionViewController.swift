//
//  GalleryCollectionViewController.swift
//  Image Gallery
//
//  Created by Aleksandr on 15/02/2019.
//  Copyright © 2019 Aleksandr Ruzmanov. All rights reserved.
//

import UIKit

class GalleryCollectionViewController: UICollectionViewController, UICollectionViewDropDelegate, UICollectionViewDragDelegate, UICollectionViewDelegateFlowLayout, UIDropInteractionDelegate {
    
    // model
    
    var gallery = Gallery()
    
    // URL cache
    
    private var cache = URLCache.shared {
        didSet {
            imageLoader.cache = cache
        }
    }
    
    // image loader
    
    private var imageLoader = ImageFetcher()
    
    
    
    // document handling
    
    var document: GalleryDocument?
    
    @IBAction private func close(_ sender: UIBarButtonItem) {
        saveDocument()
        dismiss(animated: true) {
            self.document?.close()
        }
    }
    
    private func saveDocument() {
        print("Save document")
        document?.gallery = gallery
        if document?.gallery != nil {
            document?.updateChangeCount(.done)
            if let galleryCell = collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? GalleryCollectionViewCell, let image = galleryCell.imageView.image {
                document?.thumbnailImage = image
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        document?.open(completionHandler: { (success) in
            if success {
                if let gallery = self.document?.gallery {
                    self.title = self.document?.localizedName
                    self.gallery = gallery
                    self.collectionView.reloadData()
                    self.flowLayout?.invalidateLayout()
                }
            }
        })
    }
    
    
    
    // collectionView data loading
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gallery.itemsCount()
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath)
        if let imageGalleryCell = cell as? GalleryCollectionViewCell {
            if let item = gallery.getItem(at: indexPath.item) {
                imageGalleryCell.setImageFor(item, using: imageLoader)
            }
        }
        return cell
    }

    
    
    // collectionView cells laying out
    
    private var flowLayout: UICollectionViewFlowLayout? {
        return self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var size: CGSize? = flowLayout?.itemSize
        if let aspectRatio = gallery.getItem(at: indexPath.item)?.aspectRatio, size != nil {
            size = CGSize(width: cellWidth, height: cellWidth * CGFloat(aspectRatio))
            return size!
        }
        return  CGSize.zero
    }
    
    
    
    
    
    // collectionView zooming
    
    private var cellWidth: CGFloat = 128.0 {
        didSet {
            cellWidth = max(min(cellWidth, collectionView.bounds.width), collectionView.bounds.width/10)
        }
    }
    
    @objc private func zoomByPinch(sender: UIPinchGestureRecognizer) {
        switch sender.state {
        case .changed, .ended:
            cellWidth *= sender.scale
            sender.scale = 1.0
            flowLayout?.invalidateLayout()
        default:
            break
        }
    }
    
    
    
    // segueing
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let galleryViewCell = collectionView.cellForItem(at: indexPath) as? GalleryCollectionViewCell {
            performSegue(withIdentifier: "ShowImageInScrollView", sender: galleryViewCell)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowImageInScrollView", let galleryViewCell = sender as? GalleryCollectionViewCell, let indexPath = self.collectionView.indexPath(for: galleryViewCell), let galleryItem = gallery.getItem(at: indexPath.item) {
            if let imageScrollViewController = segue.destination as? ImageScrollViewController {
                imageScrollViewController.imageFetcher = imageLoader
                imageScrollViewController.galleryItem = galleryItem
            }
        }
    }
    
    
    
    // drag from collectionView
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        session.localContext = self.collectionView
        return dragItems(at: indexPath)
    }
    
    
    private func dragItems(at indexPath: IndexPath) -> [UIDragItem] {
        var dragItems: [UIDragItem] = []
        if let imageGalleryCell = collectionView.cellForItem(at: indexPath) as? GalleryCollectionViewCell, let galleryItem = gallery.getItem(at: indexPath.item) {
            if let url = galleryItem.url {
                let item = UIDragItem(itemProvider: NSItemProvider(object: url as NSURL))
                item.localObject = imageGalleryCell
                dragItems.append(item)
            } else if let imageData = galleryItem.imageData, let image = UIImage(data: imageData) {
                let item = UIDragItem(itemProvider: NSItemProvider(object: image))
                item.localObject = imageGalleryCell
                dragItems.append(item)
            }
        }
        return dragItems
    }
    
    
    
    // drop in collectionView
    
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: UIImage.self) || (session.localDragSession?.localContext as? UICollectionView == self.collectionView)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        let isSelf = ((session.localDragSession?.localContext as? UICollectionView) == self.collectionView)
        return UICollectionViewDropProposal(operation: isSelf ? .move : .copy, intent: .insertAtDestinationIndexPath)
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0)
        for item in coordinator.items {
            if let sourceIndexPath = item.sourceIndexPath {
                // if source is local
                if let galleryItem = gallery.getItem(at: sourceIndexPath.item) {
                    collectionView.performBatchUpdates({
                        self.gallery.removeItem(at: sourceIndexPath.item)
                        self.gallery.addItem(galleryItem, at: destinationIndexPath.item)
                        collectionView.deleteItems(at: [sourceIndexPath])
                        collectionView.insertItems(at: [destinationIndexPath])
                    })
                    saveDocument()
                    coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
                }
            } else {
                // if source isn't local
                var isIncertionCompleted: Bool? {
                    didSet {
                        if isIncertionCompleted == true {
                            saveDocument()
                        }
                    }
                }
                var url: URL?
                let placeholderContext = coordinator.drop(item.dragItem, to: UICollectionViewDropPlaceholder(insertionIndexPath: destinationIndexPath, reuseIdentifier: "PlaceholderCell"))
                item.dragItem.itemProvider.loadObject(ofClass: NSURL.self) { (provider, error) in
                    if let itemURL = provider as? URL {
                        url = itemURL
                    }
                }
                item.dragItem.itemProvider.loadObject(ofClass: UIImage.self) { (provider, error) in
                    DispatchQueue.main.async {
                        if let image = provider as? UIImage {
                            let aspectRatio = Double(image.size.height / image.size.width)
                            if url != nil {
                                // if it has URL
                                isIncertionCompleted = placeholderContext.commitInsertion(dataSourceUpdates: { incertionIndexPath in
                                    self.gallery.addItemWith(aspectRatio: aspectRatio, url: url, at: incertionIndexPath.item)
                                })
                            } else if let imageData = image.jpegData(compressionQuality: 1.0) {
                                // if it has only image (without URL)
                                isIncertionCompleted = placeholderContext.commitInsertion(dataSourceUpdates: { incertionIndexPath in
                                    self.gallery.addItemWith(aspectRatio: aspectRatio, imageData: imageData , at: incertionIndexPath.item)
                                })
                            } else {
                                placeholderContext.deletePlaceholder()
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    
    // image deletion from collectionView by dragging cell to trashCan
    
    @IBOutlet private weak var trashCan: UIBarButtonItem! {
        didSet {
            let dropInteraction = UIDropInteraction(delegate: self)
            trashCan.customView?.addInteraction(dropInteraction)
        }
    }
    
    
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.localDragSession?.localContext as? UICollectionView == self.collectionView
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .move)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        for item in session.items {
            if let collectionViewCell = item.localObject as? GalleryCollectionViewCell, let indexPath = collectionView.indexPath(for: collectionViewCell) {
                collectionView.performBatchUpdates({
                    self.gallery.removeItem(at: indexPath.row)
                    self.collectionView.deleteItems(at: [indexPath])
                    saveDocument()
                })
            }
        }
    }
    

    
    // lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(zoomByPinch(sender:)))
        self.collectionView.addGestureRecognizer(pinchGestureRecognizer)
        self.collectionView.dropDelegate = self
        self.collectionView.dragDelegate = self
        self.splitViewController?.preferredDisplayMode = .primaryOverlay
        self.collectionView.dragInteractionEnabled = true
        cache = URLCache(memoryCapacity: 10*1024*1024, diskCapacity: 100*1024*1024, diskPath: nil)
    }

}

