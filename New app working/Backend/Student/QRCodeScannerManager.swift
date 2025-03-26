//  QRCodeScannerManager.swift
//  New app working
//
//  Created by AB on 1/15/25.

import SwiftUI
import AVFoundation

class QRCodeScannerManager: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    @Published var isScanning = false
    @Published var scannedCode: String?
    @Published var scanError: String?

    var captureSession: AVCaptureSession?

    func startScanning() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    self.setupScanner()
                } else {
                    self.scanError = "Camera access denied."
                }
            }
        }
    }

    private func setupScanner() {
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
            self.scanError = "Cannot access the camera."
            return
        }

        if captureSession?.canAddInput(videoInput) == true {
            captureSession?.addInput(videoInput)
        } else {
            self.scanError = "Failed to add camera input."
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()
        if captureSession?.canAddOutput(metadataOutput) == true {
            captureSession?.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            self.scanError = "Failed to scan QR codes."
            return
        }

        captureSession?.startRunning()
        isScanning = true
    }

    func stopScanning() {
        captureSession?.stopRunning()
        isScanning = false
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let code = metadataObject.stringValue else { return }

        captureSession?.stopRunning()
        scannedCode = code
        isScanning = false
    }
}

struct QRScannerView: View {
    @ObservedObject var scannerManager: QRCodeScannerManager
    var onScanCompleted: (String) -> Void

    var body: some View {
        ZStack {
            if let session = scannerManager.captureSession {
                CameraPreview(session: session)
                    .edgesIgnoringSafeArea(.all)
            } else {
                Text("Unable to start camera")
                    .foregroundColor(.red)
                    .padding()
            }

            if let error = scannerManager.scanError {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }

            VStack {
                Spacer()
                Button("Cancel") {
                    scannerManager.stopScanning()
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .onChange(of: scannerManager.scannedCode) { code in
            if let code = code {
                onScanCompleted(code)
            }
        }
        .onAppear {
            scannerManager.startScanning()
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    var session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = UIScreen.main.bounds
        view.layer.addSublayer(previewLayer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
