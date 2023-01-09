//
//  ViewController.swift
//  recognizing_text_in_images
//
//  Created by dexiong on 2023/1/9.
//

import UIKit
import Vision

class ViewController: UIViewController {
    
    private var image: UIImage = .init(named: "image.png")!
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: image)
        return imageView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(imageView)
        imageView.frame = .init(x: 100, y: 100, width: image.size.width * 0.5, height: image.size.height * 0.5)
        
        guard let cgImage = image.cgImage else { return }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        let rtq = VNRecognizeTextRequest { request, error in
            if let error = error {
                print(error)
            } else if let results = request.results as? [VNRecognizedTextObservation] {
                var texts: [(String, CGRect)] = []
                for result in results {
                    guard let recognizedText = result.topCandidates(1).first,
                            recognizedText.string.contains("ViewController.swift") else { continue }
                    let range = recognizedText.string.startIndex..<recognizedText.string.endIndex
                    let box = try? recognizedText.boundingBox(for: range)
                    let bounding = box?.boundingBox ?? .zero
                    let rect = self.getConvertedRect(boundingBox: bounding, inImage: self.image.size, containedIn: self.imageView.bounds.size)
                    texts.append((recognizedText.string, rect))
                }
                
                for str in texts {
                    let view = UIView()
                    view.layer.borderWidth = 1
                    view.layer.borderColor = UIColor.red.cgColor
                    self.imageView.addSubview(view)
                    view.frame = str.1 
                    print(str)
                }
                
            }
        }
        
        do {
            try requestHandler.perform([rtq])
        } catch {
            print(error)
        }
    }

    func getConvertedRect(boundingBox: CGRect, inImage imageSize: CGSize, containedIn containerSize: CGSize) -> CGRect {
        
        let rectOfImage: CGRect
        
        let imageAspect = imageSize.width / imageSize.height
        let containerAspect = containerSize.width / containerSize.height
        
        if imageAspect > containerAspect { /// image extends left and right
            let newImageWidth = containerSize.height * imageAspect /// the width of the overflowing image
            let newX = -(newImageWidth - containerSize.width) / 2
            rectOfImage = CGRect(x: newX, y: 0, width: newImageWidth, height: containerSize.height)
            
        } else { /// image extends top and bottom
            let newImageHeight = containerSize.width * (1 / imageAspect) /// the width of the overflowing image
            let newY = -(newImageHeight - containerSize.height) / 2
            rectOfImage = CGRect(x: 0, y: newY, width: containerSize.width, height: newImageHeight)
        }
        
        let newOriginBoundingBox = CGRect(
        x: boundingBox.origin.x,
        y: 1 - boundingBox.origin.y - boundingBox.height,
        width: boundingBox.width,
        height: boundingBox.height
        )
        
        var convertedRect = VNImageRectForNormalizedRect(newOriginBoundingBox, Int(rectOfImage.width), Int(rectOfImage.height))
        
        /// add the margins
        convertedRect.origin.x += rectOfImage.origin.x
        convertedRect.origin.y += rectOfImage.origin.y
        
        return convertedRect
    }
}

