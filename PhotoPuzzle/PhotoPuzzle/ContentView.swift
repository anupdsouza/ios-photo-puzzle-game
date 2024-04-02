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
    @State private var imageTiles: [[UIImage]] = []
    private let tileSpacing = 5.0
    
    var body: some View {
        VStack {
            if let image = croppedImage {
                Text("Visual Hint")
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
            }
            if !imageTiles.isEmpty {
                GeometryReader { geometry in
                    VStack(spacing: tileSpacing) {
                        ForEach(0..<3, id: \.self) { row in
                            HStack(spacing: tileSpacing) {
                                ForEach(0..<3, id: \.self) { column in
                                    Image(uiImage: imageTiles[row][column])
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: (geometry.size.width - (tileSpacing*2)) / 3, height: (geometry.size.width - (tileSpacing*2)) / 3)
                                }
                            }
                        }
                    }
                }
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
                imageTiles = tilesFromImage(image: croppedImage!, size: CGSize(width: minLength/3, height: minLength/3))
            }
        }
    }
    
    func tilesFromImage(image: UIImage, size: CGSize) -> [[UIImage]] {
        let hRowCount = Int(image.size.width / size.width)
        let vRowCount = Int(image.size.height / size.height)
        let tileSize = size.width
        
        
        var tiles = [[UIImage]](repeating: [], count: vRowCount)
        for vIndex in 0..<vRowCount {
            for hIndex in 0..<hRowCount {
                let imagePoint = CGPoint(x: CGFloat(hIndex) * tileSize * -1, y: CGFloat(vIndex) * tileSize * -1)
                UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
                image.draw(at: imagePoint)
                if let newImage = UIGraphicsGetImageFromCurrentImageContext() {
                    tiles[vIndex].append(newImage)
                }
                UIGraphicsEndImageContext()
            }
        }
        
        return tiles
    }
}

#Preview {
    ContentView()
}
