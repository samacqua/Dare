//
//  DareViewController.swift
//  Dare
//
//  Created by Sam Acquaviva on 1/6/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import UIKit
import MobileCoreServices
import AVFoundation

class CameraView: UIView, AVCaptureFileOutputRecordingDelegate {
    
    var parentViewController: UIViewController!
        
        var exitButton: UIButton!
        var flashButton: UIButton!
        var reverseCameraButton: UIButton!
        var uploadVideoButton: UIButton!
        var recordVideoButton: UIButton!
        var chooseDareButton: UIButton!
        
        var videoURL : URL?
        
        var camPreview: UIView!
        let captureSession = AVCaptureSession()
        let movieOutput = AVCaptureMovieFileOutput()
        var previewLayer: AVCaptureVideoPreviewLayer?
        var activeInput: AVCaptureDeviceInput!
        var outputURL: URL!
        
        var dare = Dare()
        var dareTitle: UILabel!
        
        var isFlashOn = false
        var isBackCamera = true
        
        // MARK: - Setup
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            setUpElements()
            setUpConstraints()
            
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func setUpElements() {
            self.backgroundColor = .black
            
            exitButton = UIButton(type: .system)
            let exitImage = UIImage(named: "exit_cross")
            exitButton.setImage(exitImage, for: .normal)
            exitButton.tintColor = .white
            exitButton.translatesAutoresizingMaskIntoConstraints = false
            exitButton.addTarget(self, action: #selector(exitTouchUpInside), for: .touchUpInside)
            self.addSubview(exitButton)
            
            camPreview = UIView()
            camPreview.translatesAutoresizingMaskIntoConstraints = false
            camPreview.bounds = self.bounds
            self.insertSubview(camPreview, at: 0)
            
            dareTitle = UILabel()
            dareTitle.text = dare.dareNameFull ?? ""
            dareTitle.font = UIFont.boldSystemFont(ofSize: 20)
            dareTitle.textColor = .white
            dareTitle.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(dareTitle)
            
            flashButton = UIButton(type: .system)
            let flashImage = UIImage(named: "Flash_Icon")
            flashButton.setImage(flashImage, for: .normal)
            flashButton.tintColor = .white
            flashButton.translatesAutoresizingMaskIntoConstraints = false
            flashButton.addTarget(self, action: #selector(flashTouchUpInside), for: .touchUpInside)
            self.addSubview(flashButton)
            
            reverseCameraButton = UIButton(type: .system)
            let reverseCameraImage = UIImage(named: "Flip_Camera")
            reverseCameraButton.setImage(reverseCameraImage, for: .normal)
            reverseCameraButton.tintColor = .white
            reverseCameraButton.translatesAutoresizingMaskIntoConstraints = false
            reverseCameraButton.addTarget(self, action: #selector(reverseCameraTouchUpInside), for: .touchUpInside)
            self.addSubview(reverseCameraButton)
            
            uploadVideoButton = UIButton(type: .system)
            let uploadVideoImage = UIImage(named: "Upload")
            uploadVideoButton.setImage(uploadVideoImage, for: .normal)
            uploadVideoButton.tintColor = .white
            uploadVideoButton.translatesAutoresizingMaskIntoConstraints = false
            uploadVideoButton.addTarget(self, action: #selector(uploadVideoTouchUpInside), for: .touchUpInside)
            self.addSubview(uploadVideoButton)
            
            recordVideoButton = UIButton(type: .system)
            let recordVideoImage = UIImage(named: "Record_Button")
            recordVideoButton.setImage(recordVideoImage, for: .normal)
            recordVideoButton.translatesAutoresizingMaskIntoConstraints = false
            recordVideoButton.addTarget(self, action: #selector(recordTouchUpInside), for: .touchUpInside)
            self.addSubview(recordVideoButton)
            
            chooseDareButton = UIButton(type: .system)
            let chooseDareImage = UIImage(named: "Choose_Dare")
            chooseDareButton.setImage(chooseDareImage, for: .normal)
            chooseDareButton.tintColor = .white
            chooseDareButton.translatesAutoresizingMaskIntoConstraints = false
            chooseDareButton.addTarget(self, action: #selector(chooseDareTouchUpInside), for: .touchUpInside)
            self.addSubview(chooseDareButton)
        }
        
        // MARK: - Actions
        
        @objc func exitTouchUpInside() {
            parentViewController.tabBarController?.selectedIndex = 0
        }
        
        @objc func flashTouchUpInside() {
            if self.isFlashOn {
                let flashImage = UIImage(named: "Flash_Icon")
                flashButton.setImage(flashImage, for: .normal)
                self.isFlashOn = false
            } else {
                let flashImage = UIImage(named: "Flash_Icon_Filled")
                flashButton.setImage(flashImage, for: .normal)
                self.isFlashOn = true
            }
            if isBackCamera {
                toggleFlash()
            }
        }
        
        @objc func reverseCameraTouchUpInside() {
            if isFlashOn {
                let flashImage = UIImage(named: "Flash_Icon")
                flashButton.setImage(flashImage, for: .normal)
                self.isFlashOn = false
                
                toggleFlash()
            }
            reverseCameraInput()
            if isBackCamera {
                isBackCamera = false
            } else {
                isBackCamera = true
            }
        }
        
        @objc func uploadVideoTouchUpInside() {
            let pickerController = UIImagePickerController()
            pickerController.delegate = self
            pickerController.allowsEditing = true
            pickerController.mediaTypes = [(kUTTypeMovie as String)]
            pickerController.videoMaximumDuration = 30
            pickerController.videoQuality = .type640x480
            parentViewController.present(pickerController, animated: true, completion: nil)
        }
        
        @objc func recordTouchUpInside() {
            startRecording()
        }
        
        @objc func chooseDareTouchUpInside() {
            let chooseDareVC = ChooseDareViewController()
            parentViewController.navigationController?.show(chooseDareVC, sender: self)
        }
        
        // MARK: - Functions
        
        func reverseCameraInput() {
            //Remove existing input
            guard let currentCameraInputs = captureSession.inputs as? [AVCaptureDeviceInput] else {
                return
            }
            
            //Indicate that some changes will be made to the session
            captureSession.beginConfiguration()
            for input in currentCameraInputs {
                captureSession.removeInput(input)
            }
            
            //Get new input
            var newCamera: AVCaptureDevice! = nil
            if let input = currentCameraInputs.first {
                if (input.device.position == .back) {
                    newCamera = cameraWithPosition(position: .front)
                } else {
                    newCamera = cameraWithPosition(position: .back)
                }
            }
            
            //Add input to session
            var err: NSError?
            var newVideoInput: AVCaptureDeviceInput!
            do {
                newVideoInput = try AVCaptureDeviceInput(device: newCamera)
            } catch let err1 as NSError {
                err = err1
                newVideoInput = nil
            }
            
            if newVideoInput == nil || err != nil {
                print("Error creating capture device input: \(err?.localizedDescription ?? "")")
            } else {
                captureSession.addInput(newVideoInput)
            }
            
            //Commit all the configuration changes at once
            captureSession.commitConfiguration()
        }
        
        func cameraWithPosition(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
            let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .unspecified)
            for device in discoverySession.devices {
                if device.position == position {
                    return device
                }
            }
            
            return nil
        }
        
        func toggleFlash() {
            guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
            guard device.hasTorch else { return }
            
            do {
                try device.lockForConfiguration()
                
                if (device.torchMode == AVCaptureDevice.TorchMode.on) {
                    device.torchMode = AVCaptureDevice.TorchMode.off
                } else {
                    do {
                        try device.setTorchModeOn(level: 1.0)
                    } catch {
                        print(error)
                    }
                }
                
                device.unlockForConfiguration()
            } catch {
                print(error)
            }
        }
        
        func setupPreview() {
            // Configure previewLayer
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.frame = camPreview.bounds
            previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            camPreview.layer.addSublayer(previewLayer!)
        }
        
        func setupSession() -> Bool {
            
            captureSession.sessionPreset = AVCaptureSession.Preset.high
            
            // Setup Camera
            let camera = AVCaptureDevice.default(for: AVMediaType.video)!
            
            do {
                
                let input = try AVCaptureDeviceInput(device: camera)
                
                if captureSession.canAddInput(input) {
                    captureSession.addInput(input)
                    activeInput = input
                }
            } catch {
                print("Error setting device video input: \(error)")
                return false
            }
            
            // Setup Microphone
            let microphone = AVCaptureDevice.default(for: AVMediaType.audio)!
            
            do {
                let micInput = try AVCaptureDeviceInput(device: microphone)
                if captureSession.canAddInput(micInput) {
                    captureSession.addInput(micInput)
                }
            } catch {
                print("Error setting device audio input: \(error)")
                return false
            }
            
            
            // Movie output
            if captureSession.canAddOutput(movieOutput) {
                captureSession.addOutput(movieOutput)
            }
            
            return true
        }
        
        func setupCaptureMode(_ mode: Int) {
            // Video Mode
            
        }
        
        func startSession() {
            
            if !captureSession.isRunning {
                videoQueue().async {
                    self.captureSession.startRunning()
                }
            }
        }
        
        func stopSession() {
            if captureSession.isRunning {
                videoQueue().async {
                    self.captureSession.stopRunning()
                }
            }
        }
        
        func videoQueue() -> DispatchQueue {
            return DispatchQueue.main
        }
        
        func tempURL() -> URL? {
            let directory = NSTemporaryDirectory() as NSString
            
            if directory != "" {
                let path = directory.appendingPathComponent(NSUUID().uuidString + ".mp4")
                return URL(fileURLWithPath: path)
            }
            
            return nil
        }
        
        func startRecording() {
            
            if movieOutput.isRecording == false {
                
                recordVideoButton.alpha = 0.4
                exitButton.isHidden = true
                flashButton.isHidden = true
                reverseCameraButton.isHidden = true
                uploadVideoButton.isHidden = true
                chooseDareButton.isHidden = true
                
                let connection = movieOutput.connection(with: AVMediaType.video)
                connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                
                if (connection?.isVideoStabilizationSupported)! {
                    connection?.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.auto
                }
                
                let device = activeInput.device
                
                if (device.isSmoothAutoFocusSupported) {
                    
                    do {
                        try device.lockForConfiguration()
                        device.isSmoothAutoFocusEnabled = false
                        device.unlockForConfiguration()
                    } catch {
                        print("Error setting configuration: \(error)")
                    }
                    
                }
                
                outputURL = tempURL()
                movieOutput.startRecording(to: outputURL, recordingDelegate: self)
                
            }
            else {
                recordVideoButton.alpha = 1
                exitButton.isHidden = false
                flashButton.isHidden = false
                reverseCameraButton.isHidden = false
                uploadVideoButton.isHidden = false
                chooseDareButton.isHidden = false
                stopRecording()
            }
            
        }
        
        func stopRecording() {
            
            if movieOutput.isRecording == true {
                movieOutput.stopRecording()
            }
        }
        
        func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
            
        }
        
        func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
            
            if (error != nil) {
                
                print("Error recording movie: \(error!.localizedDescription)")
                
            } else {
                
                let videoRecorded = outputURL! as URL
                let videoPlaybackVC = VideoPlayback()
                videoPlaybackVC.videoURL = videoRecorded
                videoPlaybackVC.dare = self.dare
                parentViewController.navigationController?.show(videoPlaybackVC, sender: self)
            }
            
        }
        
        // MARK: - Layout
        
        func setUpConstraints() {
            NSLayoutConstraint.activate([
                camPreview.topAnchor.constraint(equalTo: self.topAnchor),
                camPreview.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor),
                camPreview.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor),
                camPreview.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor),
                
                exitButton.heightAnchor.constraint(equalToConstant: 33),
                exitButton.widthAnchor.constraint(equalToConstant: 33),
                exitButton.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 10),
                exitButton.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 20),
                
                dareTitle.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 8),
                dareTitle.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                
                flashButton.heightAnchor.constraint(equalToConstant: 55),
                flashButton.widthAnchor.constraint(equalToConstant: 31),
                flashButton.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 10),
                flashButton.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant: -22),
                
                reverseCameraButton.heightAnchor.constraint(equalToConstant: 39),
                reverseCameraButton.widthAnchor.constraint(equalToConstant: 45),
                reverseCameraButton.topAnchor.constraint(equalTo: flashButton.bottomAnchor, constant: 22),
                reverseCameraButton.centerXAnchor.constraint(equalTo: flashButton.centerXAnchor),
                
                uploadVideoButton.heightAnchor.constraint(equalToConstant: 85),
                uploadVideoButton.widthAnchor.constraint(equalToConstant: 57),
                uploadVideoButton.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor),
                uploadVideoButton.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 20),
                
                recordVideoButton.heightAnchor.constraint(equalToConstant: 130),
                recordVideoButton.widthAnchor.constraint(equalToConstant: 130),
                recordVideoButton.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor),
                recordVideoButton.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                
                chooseDareButton.heightAnchor.constraint(equalToConstant: 82),
                chooseDareButton.widthAnchor.constraint(equalToConstant: 82),
                chooseDareButton.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: -10),
                chooseDareButton.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant: -20)
                
            ])
        }
    }

    // MARK:-Image Picker Extension
    extension CameraView: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if info[UIImagePickerController.InfoKey.mediaURL] != nil {
                videoURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL
                parentViewController.dismiss(animated: true, completion: nil)
                let darePostVC = VideoPlayback()
                darePostVC.videoURL = videoURL
                darePostVC.dare = self.dare
                parentViewController.navigationController?.show(darePostVC, sender: self)
            } else {
                parentViewController.dismiss(animated: true, completion: nil)
                print("Failed to get video URL")
            }
        }
}
