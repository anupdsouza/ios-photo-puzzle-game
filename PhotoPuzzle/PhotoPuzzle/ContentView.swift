//
//  ContentView.swift
//  PhotoPuzzle
//
//  Created by Anup D'Souza on 02/04/24.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var croppedImage: UIImage?
    var body: some View {
        VStack {
            
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            }
            if let image = croppedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 350, height: 350)
            }

            PhotosPicker(selection: $selectedItem, matching: .images) {
                Image(systemName: "photo.stack.fill")
                    .frame(width: 40, height: 25)
            }
            .onChange(of: selectedItem, loadImage)
        }
        .padding()
    }
    
    func loadImage() {
        Task {
            guard let imageData = try await selectedItem?.loadTransferable(type: Data.self) else { return }
            guard let inputImage = UIImage(data: imageData) else { return }
            selectedImage = inputImage
            processImage()
        }
    }
    
    func processImage() {
        if let image = selectedImage {
            let minLength = min(image.size.width, image.size.height)
            let x = image.size.width / 2 - minLength / 2
            let y = image.size.height / 2 - minLength / 2
            let croppingRect = CGRect(x: x, y: y, width: minLength, height: minLength)
            
            if let croppedCGImage = image.cgImage?.cropping(to: croppingRect) {
                croppedImage = UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
            }
        }
    }
}

#Preview {
    ContentView()
}
