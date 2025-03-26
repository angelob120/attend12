//
//  iPadDashboardView.swift
//  ipadapp
//
//  Created by AB on 2/17/25.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct iPadDashboardView: View {
    let numericCode = "9146"
    let todayDate = formattedDate()
    
    var body: some View {
        VStack {
            Spacer()
            Spacer()
            
            Text("Please Clock In")
                .font(.largeTitle)
                .bold()
                .padding(.top, 30)
                .foregroundColor(.primary) // adapts to light/dark mode
            
            Text("Using the QR Code")
                .font(.title)
                .foregroundColor(.primary)
                .padding(.bottom, 30)
            
            VStack {
                QRCodeView(data: todayDate) // Dynamic QR Code
                    .frame(width: 500, height: 500)
                    .padding()
                    .background(Color(UIColor.systemBackground)) // dynamic background
                    .cornerRadius(40)
                
                Text("or Numeric Code")
                    .font(.title)
                    .foregroundColor(.primary)
                    .padding(.top, 20)
                
                HStack {
                    ForEach(numericCode.map { String($0) }, id: \.self) { digit in
                        Text(digit)
                            .font(.largeTitle)
                            .bold()
                            .frame(width: 100, height: 100)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.primary, lineWidth: 4)
                            )
                    }
                }
                .padding()
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(40)
            
            Spacer()
            
            RecentActivityView()
                .padding(.horizontal)
            
            Spacer()
        }
        // Use systemBackground to automatically adapt to light/dark mode.
        .background(Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all))
    }
}

// MARK: - QR Code Generator
struct QRCodeView: View {
    let data: String
    
    var body: some View {
        if let qrImage = generateQRCode(from: data) {
            Image(uiImage: qrImage)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
        } else {
            Text("QR Code Error")
                .foregroundColor(.red)
                .font(.headline)
        }
    }
}

func generateQRCode(from string: String) -> UIImage? {
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    filter.message = Data(string.utf8)
    
    if let outputImage = filter.outputImage {
        if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cgImage)
        }
    }
    return nil
}

func formattedDate() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM-dd-yyyy" // e.g., 02-17-2025
    return formatter.string(from: Date())
}

// MARK: - Recent Activity
struct RecentActivityView: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Recent Activity")
                .font(.title2)
                .bold()
                .foregroundColor(.secondary)
                .padding(.leading)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ActivityCard(name: "Marquis Wilkins", status: "Clocked In", color: .green)
                    ActivityCard(name: "Shayla Monet", status: "Clocked Out", color: .gray)
                    ActivityCard(name: "Steve Holmes", status: "Clocked In", color: .green)
                }
                .padding(.horizontal)
            }
        }
    }
}

struct ActivityCard: View {
    var name: String
    var status: String
    var color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 20, height: 20)
            
            VStack(alignment: .leading) {
                Text(name)
                    .font(.title2)
                    .bold()
                    .foregroundColor(.primary)
                Text(status)
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .padding(.leading, 10)
            
            Spacer()
        }
        .padding()
        .frame(width: 400, height: 120)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(25)
    }
}

// MARK: - Preview
struct iPadDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        iPadDashboardView()
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
