/**
 * \file    video_camera_delegate.swift
 * \author  Mauricio Villarroel
 * \date    Created: Mar 18, 2022
 * ____________________________________________________________________________
 *
 * Copyright (C) 2022 Mauricio Villarroel. All rights reserved.
 *
 * SPDX-License-Identifer:  GPL-2.0-only
 * ____________________________________________________________________________
 */

import Foundation
import ThermalSDK
import SensorRecordingUtils



final class Video_camera_delegate :
        NSObject,
        FLIRDiscoveryEventDelegate,
        FLIRDataReceivedDelegate,
        FLIRRemoteDelegate,
        FLIRStreamDelegate
{
    
    @Published private(set) var manager_event : Device_manager_event
    
    @Published private(set) var battery_percentage : Int
    
    @Published private(set) var battery_state : UIDevice.BatteryState
    
    @Published private(set) var camera_state  : Camera_state
    
    @Published private(set) var shutter_state : FLIRShutterState
    
    
    init(
            device_identifier    : Device.ID_type,
            manager_event        : Device_manager_event  = .not_set,
            battery_percentage   : Int                   = 0,
            battery_state        : UIDevice.BatteryState = .unknown,
            camera_state         : Camera_state          = .unknown,
            shutter_state        : FLIRShutterState      = .on
        )
    {
        
        self.device_identifier  = device_identifier
        self.manager_event      = manager_event
        self.battery_percentage = battery_percentage
        self.battery_state      = battery_state
        self.camera_state       = camera_state
        self.shutter_state      = shutter_state
        
        super.init()
        
    }
    
    
    deinit
    {
        
        data_stream_continuation = nil
        discovery_continuation   = nil
        
    }
    
    
    // MARK: - Public interface
    
   
    func set_camera_discovery_continuation(
            _  continuation : CheckedContinuation<FLIRIdentity, Error>
        )
    {
        
        discovery_continuation = continuation
        
    }
    
    
    func cancel_camera_discovery()
    {
        
        if let continuation = discovery_continuation
        {
            
            continuation.resume(
                    throwing: Device.Connect_error.connection_cancelled(
                        device_id   : device_identifier,
                        description : "Camera discovery has been cancelled"
                    )
                )
                
        }
        
        discovery_continuation = nil
        
    }
    
    
    func set_data_stream_continuation(
        _  continuation : AsyncThrowingStream<UInt64, Error>.Continuation
        )
    {
        
        if data_stream_continuation != nil
        {
            end_data_stream()
        }
        
        data_stream_continuation = continuation
        image_sequence = 0
        
    }
    
    
    func end_data_stream()
    {
        
        data_stream_continuation?.finish()
        data_stream_continuation = nil
        
    }
    
    
    // MARK: - FLIRDiscoveryEventDelegate protocol methods
    
    
    func cameraFound( _ identity: FLIRIdentity )
    {
        
        switch identity.cameraType()
        {
            case .generic:
                
                discovery_continuation?.resume(
                    throwing: Thermal_error.incorrect_camera_discovered(
                        description: "Generic FLIR Camera found")
                    )
                
            case .flirOne:
                
                discovery_continuation?.resume(returning: identity)
                
            @unknown default:
                
                discovery_continuation?.resume(
                    throwing: Thermal_error.incorrect_camera_discovered(
                        description: "Unknown FLIR Camera found")
                    )
        }
        
        discovery_continuation = nil
        
    }
    
    
    func discoveryError(
            _                error              : String,
            netServiceError  nsnetserviceserror : Int32,
            on               iface              : FLIRCommunicationInterface
        )
    {
                
        discovery_continuation?.resume(
            throwing: Thermal_error.camera_discovery_error(
                code        : Int(nsnetserviceserror),
                description : error
                )
            )
        
        discovery_continuation = nil
        
    }
    
    
    func discoveryFinished(_ iface: FLIRCommunicationInterface)
    {
        
        print(
            """
            
            
            Camera_service_delegate : discoveryFinished
            iface is lightning ? = \( iface.contains(.lightning) )
            
            """
            )
        
    }

    
    func cameraLost(_ identity: FLIRIdentity)
    {
        
        print(
            """
            
            
            Camera_service_delegate : cameraLost
            identity = \( identity.deviceId() )
            
            """
            )
        
    }
    
    
    // MARK: - FLIRRemoteDelegate protocol methods
    
    
    func percentageChanged(_ percent: Int32)
    {
        
        let new_percentage = Int(percent)
        
        if new_percentage != battery_percentage
        {
            battery_percentage = new_percentage
        }
        
    }
    
    
    func chargingStateChanged( _ state: FLIRChargingState )
    {
        
        switch state
        {
            case .MANAGEDCHARGING:
                battery_state = .charging
                
            default:
                battery_state = .unknown
        }
        
    }
    
    
    func cameraStateChanged(_ newState: FLIRCameraState)
    {
        
        camera_state = Camera_state(from: newState)
        
    }
    
    
    
    func shutterStateChanged(_ state: FLIRShutterState)
    {
        
        shutter_state = state
        
    }
    
    
    // MARK: - FLIRDataReceivedDelegate protocol methods
    
    
    func onDisconnected(
            _          camera  : FLIRCamera,
            withError  error   : Error?
        )
    {
        
        manager_event = .device_disconnected(
            device_id   : device_identifier,
            description : error?.localizedDescription ?? ""
        )
        
    }
    
    
    // MARK: - FLIRStreamDelegate protocol methods
    
    
    func onError( _ error: Error )
    {
        
        data_stream_continuation?.finish(throwing: error)
        
    }
    
    
    func onImageReceived()
    {
        
        data_stream_continuation?.yield(image_sequence)
        image_sequence += 1
        
    }
    
    
    // MARK: - Private state
    
    
    /**
     * Unique identifier for the device.
     */
    private let device_identifier : Device.ID_type
            
    private var discovery_continuation :
        CheckedContinuation<FLIRIdentity, Error>?
        
    private var data_stream_continuation : AsyncThrowingStream<UInt64, Error>.Continuation?
    
    private var image_sequence : UInt64 = 0
    
        
    
    // MARK: - Private interface
    
    
    
}
