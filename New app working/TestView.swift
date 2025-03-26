//
//  TestView.swift
//  NewApp
//
//  Created by AB on 1/9/25.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct TestView: View {
    @State private var qrCodeImage: UIImage? = nil
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()
    
    // Random single-digit numbers for each box
    @State private var randomNumbers: [Int] = Array(repeating: 0, count: 4)
    
    var body: some View {
        VStack(spacing: 20) { // Adds spacing between elements
            // QR Code Image
            if let qrCodeImage = qrCodeImage {
                Image(uiImage: qrCodeImage)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 300, height: 300)
            } else {
                Text("Generating QR Code...")
                    .font(.headline)
            }
            
            // Row of 4 White Rectangles with One Random Number Each
            HStack(spacing: 15) { // Horizontal layout for boxes
                ForEach(0..<4, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white)
                        .frame(width: 60, height: 60)
                        .shadow(radius: 5)
                        .overlay(
                            Text("\(randomNumbers[index])")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                        )
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2)) // Light background for contrast
        .onAppear {
            generateQRCode(from: "https://example.com") // Change QR content
            generateRandomNumbers()
        }
    }
    
    func generateQRCode(from string: String) {
        filter.message = Data(string.utf8)
        
        if let outputImage = filter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                DispatchQueue.main.async {
                    self.qrCodeImage = UIImage(cgImage: cgimg)
                }
            }
        }
    }
    
    func generateRandomNumbers() {
        randomNumbers = (0..<4).map { _ in Int.random(in: 0...9) } // Generates a single digit (0-9)
    }
}

struct TestView_Previews: PreviewProvider {
    static var previews: some View {
        TestView()
    }
}
