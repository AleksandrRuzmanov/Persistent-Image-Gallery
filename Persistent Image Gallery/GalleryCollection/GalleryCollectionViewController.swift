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
    
    private var cache = URLCache.shared
    
    
    
    // document handling
    
    var document: GalleryDocument?
    
    @IBAction private func close(_ sender: UIBarButtonItem) {
        document?.gallery = gallery
        if document?.gallery != nil {
            document?.updateChangeCount(.done)
            document?.thumbnailImage = self.collectionView.snapshot
        }
        dismiss(animated: true) {
            self.document?.close()
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
                imageGalleryCell.setupImageViewFor(item, width: cellWidth, using: cache)
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
            let minBoundsSize = min(self.collectionView.bounds.width, self.collectionView.bounds.height)
            size!.width = min(cellWidth * scale, minBoundsSize)
            size!.height = size!.width * CGFloat(aspectRatio)
            return size!
        }
        return  CGSize.zero
    }
    
    
    
    
    
    // collectionView zooming
    
    private var cellWidth: CGFloat {
        if let cellWidth = self.collectionView.visibleCells.first?.frame.size.width {
            return cellWidth
        }
        return 250.0
    }
    
    private var scale: CGFloat = 1.0 {
        didSet {
            flowLayout?.invalidateLayout()
        }
    }
    
    @objc private func zoomByPinch(sender: UIPinchGestureRecognizer) {
        switch sender.state {
        case .changed, .ended:
            scale = sender.scale
            sender.scale = 1.0
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
        if segue.identifier == "ShowImageInScrollView", let galleryViewCell = sender as? GalleryCollectionViewCell {
            if let imageScrollViewController = segue.destination as? ImageScrollViewController {
                imageScrollViewController.url = galleryViewCell.imageURL
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
        if let imageGalleryCell = collectionView.cellForItem(at: indexPath) as? GalleryCollectionViewCell {
            if let url = imageGalleryCell.imageURL {
                let item = UIDragItem(itemProvider: NSItemProvider(object: url as NSURL))
                item.localObject = imageGalleryCell
                dragItems.append(item)
            }
        }
        return dragItems
    }
    
    
    
    // drop in collectionView
    
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return (session.canLoadObjects(ofClass: NSURL.self) && session.canLoadObjects(ofClass: UIImage.self)) || (session.localDragSession?.localContext as? UICollectionView == self.collectionView)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        let isSelf = ((session.localDragSession?.localContext as? UICollectionView) == self.collectionView)
        return UICollectionViewDropProposal(operation: isSelf ? .move : .copy, intent: .insertAtDestinationIndexPath)
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0)
        for item in coordinator.items {
            if let sourceIndexPath = item.sourceIndexPath, let imageViewCell = item.dragItem.localObject as? GalleryCollectionViewCell {
                // if source is local
                if let image = imageViewCell.imageView.image, let url = imageViewCell.imageURL {
                    let aspectRaio = Double(image.size.height / image.size.width)
                    collectionView.performBatchUpdates({
                        self.gallery.removeItem(at: sourceIndexPath.item)
                        self.gallery.addItemWith(aspectRatio: aspectRaio, url: url, at: destinationIndexPath.item)
                        collectionView.deleteItems(at: [sourceIndexPath])
                        collectionView.insertItems(at: [destinationIndexPath])
                    })
                    coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
                }
            } else {
                // if source isn't local
                var aspectRatio: Double?
                let placeholderContext = coordinator.drop(item.dragItem, to: UICollectionViewDropPlaceholder(insertionIndexPath: destinationIndexPath, reuseIdentifier: "PlaceholderCell"))
                item.dragItem.itemProvider.loadObject(ofClass: UIImage.self) { (provider, error) in
                    if let image = provider as? UIImage {
                        aspectRatio = Double(image.size.height / image.size.width)
                    }
                }
                item.dragItem.itemProvider.loadObject(ofClass: NSURL.self) { (provider, error) in
                    DispatchQueue.main.async {
                        if let url = provider as? URL, aspectRatio != nil {
                            placeholderContext.commitInsertion(dataSourceUpdates: { incertionIndexPath in
                                self.gallery.addItemWith(aspectRatio: aspectRatio!, url: url, at: incertionIndexPath.item)
                            })
                        } else {
                            placeholderContext.deletePlaceholder()
                        }
                    }
                }
            }
        }
    }
    
    
    
    // image deletion from collectionView by drag and drop
    
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

