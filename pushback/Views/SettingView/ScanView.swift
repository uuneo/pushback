//
//  ScanView.swift
//  Meow
//
//  Created by He Cho on 2024/8/10.
//


import SwiftUI
import AVFoundation
import QRScanner
import UIKit

struct ScanView: View {
    @Environment(\.dismiss) var dismiss
    @State private var torchIsOn = false
    @State private var restart = false
    @State private var scanCode = ""
    @State private var showActive = false
    var startConfig: (String)->Void
    var body: some View {
        ZStack{
            QRScannerSampleView(restart: $restart,flash: $torchIsOn,value: $scanCode)
                .onChange(of: scanCode) { value in
#if DEBUG
                    debugPrint(scanCode)
#endif
					if scanCode.isValidURL() == .remote{
                        startConfig(scanCode)
                        self.dismiss()
                    }else{
                        self.showActive.toggle()
                    }
                   
                }
                .actionSheet(isPresented: $showActive) {
                
                    
                    ActionSheet(title: Text(String(localized: "不正确的地址")),buttons: [
                        
                        .default(Text(String(localized: "重新扫码")), action: {
#if DEBUG
                            debugPrint(self.scanCode)
#endif
                            self.scanCode = ""
                            self.restart.toggle()
                            self.showActive.toggle()
                        }),
                        
                        .cancel({
                            self.dismiss()
                        })
                    ])
                }
           
            
                
            VStack{
                HStack{
                    
                    Spacer()
                    CloseButton()
                        .onTapGesture {
                            self.dismiss()
                        }
                        
                }
                .padding()
                .padding(.top,50)
                Spacer()
                
                Button{
                    self.torchIsOn.toggle()
                }label: {
                    Image(systemName: "flashlight.\(torchIsOn ? "on" : "off").circle")
                        .font(.system(size: 50))
                        .padding(.bottom, 80)
                }

                
            }
            
        }.ignoresSafeArea()
    }
}

struct CloseButton: View {
	var body: some View {
		Image(systemName: "xmark")
			.font(.system(size: 17, weight: .bold))
			.foregroundColor(.secondary)
			.padding(8)
			.background(.ultraThinMaterial, in: Circle())
			.backgroundStyle(cornerRadius: 18)
	}
}

struct QRScannerSampleView: UIViewControllerRepresentable {
    @Binding var restart:Bool
    @Binding var flash:Bool
    @Binding var value:String
    func makeUIViewController(context: Context) -> QRScannerViewController {
        let qrview = QRScannerViewController()
        qrview.valueChange = changeValue
        return qrview
    }
    
    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {
        // Here you can update the controller if needed.
        if restart {
            uiViewController.QRView?.rescan()
			self.restart = false
            
        }
        uiViewController.toggleTorch(on: flash)
        
    }
    
    func changeValue(_ value: String){
        self.value = value
    }
    
    func restartScan(_ value: Bool){
        if value{
            
        }
        
    }
}


final class QRScannerViewController: UIViewController {
    var QRView:QRScannerView?
    var flash: Bool = false
    var valueChange:((String)-> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupQRScanner()
    }

    private func setupQRScanner() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupQRScannerView()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async { [weak self] in
                        self?.setupQRScannerView()
                    }
                }
            }
        default:
            showAlert()
        }
    }

    private func setupQRScannerView() {
        self.QRView = QRScannerView(frame: view.bounds)
        view.addSubview(self.QRView!)
        self.QRView?.configure(delegate: self, input: .init(isBlurEffectEnabled: true))
        self.QRView?.startRunning()
    }

    private func showAlert() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            let alert = UIAlertController(title: "Error", message: "Camera is required to use in this application", preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .default))
            self?.present(alert, animated: true)
        }
    }
    
    
    func toggleTorch(on: Bool) {
           guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }

           do {
               try device.lockForConfiguration()

               device.torchMode = on ? .on : .off

               device.unlockForConfiguration()
           } catch {
#if DEBUG
               print("Torch could not be used")
#endif
              
           }
       }
}

extension QRScannerViewController: QRScannerViewDelegate {
    func qrScannerView(_ qrScannerView: QRScannerView, didFailure error: QRScannerError) {
#if DEBUG
        print(error)
#endif
        
    }

    func qrScannerView(_ qrScannerView: QRScannerView, didSuccess code: String) {
        self.valueChange?(code)
    }
    
    func qrScannerView(_ qrScannerView: QRScannerView, didChangeTorchActive isOn: Bool) {
        self.toggleTorch(on: isOn)
    }
}


final class FlashButton: UIButton {
    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        settings()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        settings()
    }

    // MARK: - Properties
    override var isSelected: Bool {
        didSet {
            let color: UIColor = isSelected ? .gray : .lightGray
            backgroundColor = color.withAlphaComponent(0.7)
        }
    }
}

// MARK: - Private
private extension FlashButton {
    func settings() {
        setTitleColor(.darkGray, for: .normal)
        setTitleColor(.white, for: .selected)
        setTitle("OFF", for: .normal)
        setTitle("ON", for: .selected)
        tintColor = .clear
        titleLabel?.font = .boldSystemFont(ofSize: 16)
        layer.cornerRadius = frame.size.width / 2
        isSelected = false
    }
}

#Preview {
    ScanView { _ in
        
    }
}

