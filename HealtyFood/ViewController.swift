//
//  ViewController.swift
//  HealtyFood
//
//  Created by Ula Kuczynska on 6/15/18.
//  Copyright © 2018 Ula Kuczynska. All rights reserved.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textDescriptionField: UITextView!
    
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary //TODO: change to .camera on a real phone
        imagePicker.allowsEditing = false //TODO: allow editing
        
    }
    
    //MARK: - Picking and image from source
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageView.image = pickedImage
            imageView.adjustsImageSizeForAccessibilityContentSizeCategory = false
            
            guard let ciimage = CIImage(image: pickedImage) else {
                fatalError("Could not convert to CIImage")
            }
            
            detect(image: ciimage)
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
        adjustUITextViewHeight(arg: textDescriptionField)
    }
    
    
    // MARK: - Analyzing
    func detect(image: CIImage) {
        guard let model = try? VNCoreMLModel(for: Inceptionv3().model) else {
            fatalError("Loading CoreML model failed")
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("Results cannot be classificated")
            }
            
            guard let firstResult = results.first else {
                fatalError("Cannot get the results from CoreML")
            }
                
            if let firstPrediction = String(firstResult.identifier).components(separatedBy: ",").first {
                let confidence = firstResult.confidence
                
                switch confidence {
                case (0...0.55):
                    let secondResult = results[1]
                    self.textDescriptionField.text = String(" \(firstPrediction) \(Int(100 * firstResult.confidence))%\n \(secondResult.identifier) \(Int(100 * secondResult.confidence))%")
                    self.adjustUITextViewHeight(arg: self.textDescriptionField)
                case (0.56...0.8):
                    self.textDescriptionField.text = String(" \(firstPrediction) \(100 * firstResult.confidence)%")
                    self.adjustUITextViewHeight(arg: self.textDescriptionField)
                default:
                    self.textDescriptionField.text = "Image cannot be identified at this time 😔"
                    self.adjustUITextViewHeight(arg: self.textDescriptionField)
                }
                
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
            try handler.perform([request])
        }
        catch {
            print(error)
        }
    }

    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    
    // MARK: - Helpers for UI
    func adjustUITextViewHeight(arg : UITextView)
    {
        arg.translatesAutoresizingMaskIntoConstraints = true
        arg.sizeToFit()
        arg.isScrollEnabled = false
        arg.textAlignment = .center
        arg.increaseSize(2)
    }
    
}

