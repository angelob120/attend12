//  CameraCaptureView.swift
//  New app working
//
//  Created by AB on 1/15/25.
//

import SwiftUI
import AVFoundation

struct CameraCaptureView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var cameraManager = CameraManager()
    @State private var capturedImage: UIImage? = nil

    var onPhotoCaptured: () -> Void

    var body: some View {
        ZStack {
            CameraPreview(session: cameraManager.session)
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()
                
                // Capture Button
                Button(action: {
                    cameraManager.capturePhoto { image in
                        if let image = image {
                            self.capturedImage = image
                            onPhotoCaptured()  // Notify that the photo has been captured
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }) {
                    Circle()
                        .fill(Color.blue) // Changed from White to Blue
                        .frame(width: 75, height: 75)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                                .frame(width: 90, height: 90)
                        )
                        .shadow(radius: 10)
                        .padding(.bottom, 30)
                }
            }
        }
        .onAppear {
            cameraManager.checkPermissions()
            cameraManager.startSession()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .background(Color(.systemBackground)) // Adapts to Light & Dark Mode
    }
}

// MARK: - Camera Preview
struct CameraPreview1: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.frame
        view.layer.addSublayer(previewLayer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - Camera Manager
class CameraManager: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private let queue = DispatchQueue(label: "cameraQueue")

    override init() {
        super.init()
        setupSession()
    }

    private func setupSession() {
        session.sessionPreset = .photo
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
           let input = try? AVCaptureDeviceInput(device: device) {
            if session.canAddInput(input) && session.canAddOutput(output) {
                session.addInput(input)
                session.addOutput(output)
            }
        }
    }

    func checkPermissions() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if !granted {
                print("Camera access denied")
            }
        }
    }

    func startSession() {
        queue.async {
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    func stopSession() {
        queue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)

        output.completionHandler = { image in
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            return
        }
        output.completionHandler?(image)
    }
}

private extension AVCapturePhotoOutput {
    typealias PhotoCaptureCompletionHandler = (UIImage?) -> Void
    private struct AssociatedKeys {
        static var completionHandler = "completionHandler"
    }

    var completionHandler: PhotoCaptureCompletionHandler? {
        get {
            objc_getAssociatedObject(self, &AssociatedKeys.completionHandler) as? PhotoCaptureCompletionHandler
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.completionHandler, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
