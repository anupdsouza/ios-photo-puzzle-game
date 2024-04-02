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
    var body: some View {
        VStack {
            
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
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
        }
    }
    
    func processImage() {
        if let image = selectedImage {
            let size = min(image.size.width, image.size.height)
            // TODO: Clip portion of the image from the center as a square of the given size
        }
    }
}

#Preview {
    ContentView()
}
