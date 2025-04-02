// QRCodeScannerManager.swift

import SwiftUI
import AVFoundation

class QRCodeScannerManager: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    @Published var isScanning = false
    @Published var scannedCode: String?
    @Published var scanError: String?
    @Published var showManualEntrySheet = false
    @Published var manualCode: String = ""
    @Published var isProcessingManualCode = false
    @Published var invalidCodeError = false

    var captureSession: AVCaptureSession?
    
    // Add a flag to track initialization status
    private var isInitialized = false

    func startScanning() {
        // Reset state
        scannedCode = nil
        scanError = nil
        invalidCodeError = false
        
        // Only initialize once
        if isInitialized && captureSession != nil {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession?.startRunning()
                DispatchQueue.main.async {
                    self.isScanning = true
                }
            }
            return
        }
        
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if granted {
                DispatchQueue.main.async {
                    self.setupScanner()
                }
            } else {
                DispatchQueue.main.async {
                    self.scanError = "Camera access denied."
                }
            }
        }
    }

    private func setupScanner() {
        // Start fresh with a new capture session
        let session = AVCaptureSession()
        
        // Use high resolution if possible
        if session.canSetSessionPreset(.high) {
            session.sessionPreset = .high
        }
        
        self.captureSession = session

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            self.scanError = "Cannot access the camera."
            return
        }
        
        // Configure camera input
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
            } else {
                self.scanError = "Failed to add camera input."
                return
            }
        } catch {
            self.scanError = "Error setting up camera: \(error.localizedDescription)"
            return
        }

        // Configure metadata output for QR codes
        let metadataOutput = AVCaptureMetadataOutput()
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            
            // Must set delegate after adding output
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr, .ean8, .ean13, .pdf417] // Add multiple code types for better detection
        } else {
            self.scanError = "Failed to add QR scanning capability."
            return
        }

        // Mark as initialized
        isInitialized = true

        // Start the session in a background thread to avoid UI freezing
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
            DispatchQueue.main.async {
                self.isScanning = true
            }
        }
    }

    func stopScanning() {
        // Stop scanning in a background thread
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession?.stopRunning()
            DispatchQueue.main.async {
                self.isScanning = false
            }
        }
    }

    // Process manual code entry
    func processManualEntry() {
        isProcessingManualCode = true
        
        // Check if the code is valid - accept only these specific codes
        let validCodes = ["0000", "9146", "MM-dd-yyyy"] // Add any other valid codes here
        
        // For date format code, also check current date
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy"
        let todayCode = formatter.string(from: today)
        
        if validCodes.contains(manualCode) || manualCode == todayCode {
            // Valid code, set it as the scanned code
            scannedCode = manualCode
            showManualEntrySheet = false
            isProcessingManualCode = false
            invalidCodeError = false
        } else {
            // Invalid code, show error
            invalidCodeError = true
            isProcessingManualCode = false
            
            // Keep the sheet open to allow the user to retry
            // The error message will be displayed in the sheet
        }
    }

    // Delegate method that gets called when a QR code is detected
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Check if we have a valid QR code
        guard !metadataObjects.isEmpty,
              let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let code = metadataObject.stringValue, !code.isEmpty else {
            return
        }

        // We got a valid code - stop scanning
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession?.stopRunning()
            DispatchQueue.main.async {
                self.scannedCode = code
                self.isScanning = false
                print("QR Code scanned successfully: \(code)")
            }
        }
    }
    
    // Diagnostic function to help identify issues
    func diagnoseSession() {
        guard let session = self.captureSession else {
            print("⚠️ No capture session available")
            return
        }
        
        print("📷 Capture session running: \(session.isRunning)")
        print("📷 Capture session preset: \(session.sessionPreset.rawValue)")
        
        // Check inputs
        print("📷 Inputs: \(session.inputs.count)")
        for (index, input) in session.inputs.enumerated() {
            if let deviceInput = input as? AVCaptureDeviceInput {
                print("📷   Input \(index): \(deviceInput.device.localizedName)")
            } else {
                print("📷   Input \(index): \(type(of: input))")
            }
        }
        
        // Check outputs
        print("📷 Outputs: \(session.outputs.count)")
        for (index, output) in session.outputs.enumerated() {
            print("📷   Output \(index): \(type(of: output))")
            
            if let metadataOutput = output as? AVCaptureMetadataOutput {
                print("📷     Metadata types: \(metadataOutput.metadataObjectTypes)")
            }
        }
    }
}

// Enhanced QRScannerView to provide better user feedback
struct QRScannerView: View {
    @ObservedObject var scannerManager: QRCodeScannerManager
    var onScanCompleted: (String) -> Void
    @Environment(\.presentationMode) var presentationMode
    @State private var hasAttemptedScan = false

    var body: some View {
        ZStack {
            // Camera preview
            if let session = scannerManager.captureSession {
                CameraPreview(session: session)
                    .edgesIgnoringSafeArea(.all)
                
                // QR Code scanning frame
                Rectangle()
                    .stroke(Color.green, lineWidth: 3)
                    .frame(width: 250, height: 250)
                
                // Scanning animation
                if scannerManager.isScanning {
                    Rectangle()
                        .stroke(Color.green, lineWidth: 3)
                        .frame(width: 250, height: 2)
                        .offset(y: -125)
                        .animation(
                            Animation.linear(duration: 2.5)
                                .repeatForever(autoreverses: true),
                            value: scannerManager.isScanning
                        )
                }
            } else {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack {
                    if scannerManager.scanError != nil {
                        Text("Camera Error")
                            .font(.title)
                            .foregroundColor(.white)
                    } else {
                        Text("Initializing Camera...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
            }

            // Error display
            if let error = scannerManager.scanError {
                VStack {
                    Spacer()
                    Text(error)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(10)
                        .padding(.bottom, 100)
                }
            }

            // Bottom controls
            VStack {
                Spacer()
                HStack {
                    Button("Cancel") {
                        scannerManager.stopScanning()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    // Manual entry option
                    Button("Enter Code Manually") {
                        scannerManager.stopScanning()
                        scannerManager.showManualEntrySheet = true
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.bottom, 40)
            }
        }
        .onChange(of: scannerManager.scannedCode) { code in
            if let code = code, !hasAttemptedScan {
                hasAttemptedScan = true
                onScanCompleted(code)
                
                // Dismiss the sheet after handling the code
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .overlay(
            VStack {
                Spacer()
                Text(TimerService.shared.isTimerRunning ? "Scan QR Code to Clock Out" : "Scan QR Code to Clock In")
                    .font(.headline)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.bottom, 100)
            }
        )
        .onAppear {
            print("QRScannerView appeared")
            hasAttemptedScan = false
            scannerManager.startScanning()
            
            // Run diagnostics after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                scannerManager.diagnoseSession()
            }
        }
        .onDisappear {
            print("QRScannerView disappeared")
            scannerManager.stopScanning()
        }
        .sheet(isPresented: $scannerManager.showManualEntrySheet) {
            ManualCodeEntryView(scannerManager: scannerManager)
        }
    }
}

// Add a new view for manual code entry
struct ManualCodeEntryView: View {
    @ObservedObject var scannerManager: QRCodeScannerManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Enter Attendance Code")
                    .font(.title)
                    .padding(.top)
                
                TextField("Enter code", text: $scannerManager.manualCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.default)
                    .padding()
                
                if scannerManager.invalidCodeError {
                    Text("Invalid attendance code")
                        .foregroundColor(.red)
                        .padding()
                }
                
                Button(action: {
                    scannerManager.processManualEntry()
                }) {
                    Text("Submit")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding()
                .disabled(scannerManager.manualCode.isEmpty || scannerManager.isProcessingManualCode)
                
                if scannerManager.isProcessingManualCode {
                    ProgressView()
                        .padding()
                }
                
                Spacer()
                
                // Information about valid codes
                VStack(alignment: .leading, spacing: 10) {
                    Text("Valid Codes:")
                        .font(.headline)
                    
                    Text("• 0000 - Manual clock in")
                    Text("• 9146 - Standard code")
                    Text("• Today's date (MM-DD-YYYY)")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding()
            }
            .padding()
            .navigationBarTitle("Manual Entry", displayMode: .inline)
            .navigationBarItems(trailing: Button("Cancel") {
                scannerManager.showManualEntrySheet = false
            })
        }
    }
}

// Enhanced CameraPreview with better configuration
struct CameraPreview: UIViewRepresentable {
    class Coordinator: NSObject {
        var parent: CameraPreview
        
        init(_ parent: CameraPreview) {
            self.parent = parent
            super.init()
        }
    }
    
    let session: AVCaptureSession
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UIView {
        print("🔍 Creating camera preview view")
        
        // Create the container view
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .black
        
        // Create and configure the preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.videoOrientation = .portrait
        previewLayer.frame = view.bounds
        previewLayer.name = "cameraPreviewLayer" // Give it a name to find it easily
        
        // Test if we're correctly adding the layer
        print("🔍 Adding preview layer to view: \(previewLayer)")
        view.layer.addSublayer(previewLayer)
        
        // Force layout immediately
        view.layoutIfNeeded()
        
        print("🔍 Preview layer frame: \(previewLayer.frame)")
        print("🔍 View bounds: \(view.bounds)")
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        print("🔍 Updating camera preview view")
        
        // Find the preview layer by name
        if let previewLayer = uiView.layer.sublayers?.first(where: { $0.name == "cameraPreviewLayer" }) as? AVCaptureVideoPreviewLayer {
            // Update frame to match the view bounds
            DispatchQueue.main.async {
                CATransaction.begin()
                CATransaction.setAnimationDuration(0)
                previewLayer.frame = uiView.bounds
                CATransaction.commit()
                
                print("🔍 Updated preview layer frame: \(previewLayer.frame)")
            }
        } else {
            print("⚠️ Could not find preview layer in updateUIView")
        }
    }
}
