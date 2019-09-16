//
//  CameraController.swift
//  WenQu
//
//  Created by captain on 9/16/19.
//  Copyright © 2019 TDG. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

class CameraController{
    var captureSession: AVCaptureSession?
    var frontCamera: AVCaptureDevice?
    var rearCamera: AVCaptureDevice?
    
    var currentCameraPosition: CameraPosition?
    var frontCameraInput: AVCaptureDeviceInput?
    var rearCameraInput: AVCaptureDeviceInput?
    
    var photoOutput: AVCapturePhotoOutput?
    
    var previewLayer: AVCaptureVideoPreviewLayer?
}

extension CameraController{
    func prepare(completionHandler: @escaping(Error?) -> Void){
        self.captureSession = AVCaptureSession()
        
        func createCaptureSession() { }
        func configureCaptureDevices() throws {
            
            //1
            let session = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .unspecified)
            //guard let cameras = (session.devices.compactMap { $0 }), !cameras.isEmpty else { throw CameraControllerError.noCamerasAvailable }
            
            let cameras = (session.devices.compactMap { $0 })
            if cameras.isEmpty { throw CameraControllerError.noCamerasAvailable }
            
            //2
            for camera in cameras {
                if camera.position == .front {
                    self.frontCamera = camera
                }
                
                if camera.position == .back {
                    self.rearCamera = camera
                    
                    try camera.lockForConfiguration()
                    camera.focusMode = .continuousAutoFocus
                    camera.unlockForConfiguration()
                }
            }
        }
        func configureDeviceInputs() throws { }
        func configurePhotoOutput() throws { }
        
        DispatchQueue(label: "prepare").async {
            do {
                createCaptureSession()
                try configureCaptureDevices()
                try configureDeviceInputs()
                try configurePhotoOutput()
            }
                
            catch {
                DispatchQueue.main.async {
                    completionHandler(error)
                }
                
                return
            }
            
            DispatchQueue.main.async {
                completionHandler(nil)
            }
        }
    }
    
    func configureDeviceInputs() throws {
        //3
        guard let captureSession = self.captureSession else { throw CameraControllerError.captureSessionIsMissing }
        
        //4
        if let rearCamera = self.rearCamera {
            self.rearCameraInput = try AVCaptureDeviceInput(device: rearCamera)
            
            if captureSession.canAddInput(self.rearCameraInput!) { captureSession.addInput(self.rearCameraInput!) }
            
            self.currentCameraPosition = .rear
        }
            
        else if let frontCamera = self.frontCamera {
            self.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
            
            if captureSession.canAddInput(self.frontCameraInput!) { captureSession.addInput(self.frontCameraInput!) }
            else { throw CameraControllerError.inputsAreInvalid }
            
            self.currentCameraPosition = .front
        }
            
        else { throw CameraControllerError.noCamerasAvailable }
    }
    
    
    func configurePhotoOutput() throws {
        guard let captureSession = self.captureSession else { throw CameraControllerError.captureSessionIsMissing }
        
        self.photoOutput = AVCapturePhotoOutput()
        self.photoOutput!.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])], completionHandler: nil)
        
        if captureSession.canAddOutput(self.photoOutput!) { captureSession.addOutput(self.photoOutput!) } // here I have some issue -- Qi
        
        captureSession.startRunning()
    }
}

extension CameraController {
    enum CameraControllerError: Swift.Error {
        case captureSessionAlreadyRunning
        case captureSessionIsMissing
        case inputsAreInvalid
        case invalidOperation
        case noCamerasAvailable
        case unknown
    }
    
    public enum CameraPosition {
        case front
        case rear
    }
}

extension CameraController{
    func displayPreview(on view: UIView) throws {
        guard let captureSession = self.captureSession, captureSession.isRunning else { throw CameraControllerError.captureSessionIsMissing }
        
        self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.previewLayer?.connection?.videoOrientation = .portrait
        
        view.layer.insertSublayer(self.previewLayer!, at: 0)
        self.previewLayer?.frame = view.frame
    }
}
