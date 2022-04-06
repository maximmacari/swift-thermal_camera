/**
 * \file    video_camera.swift
 * \author  Mauricio Villarroel
 * \date    Created: Mar 8, 2022
 * ____________________________________________________________________________
 *
 * Copyright (C) 2022 Mauricio Villarroel. All rights reserved.
 *
 * SPDX-License-Identifer:  GPL-2.0-only
 * ____________________________________________________________________________
 */

import Foundation
import UIKit
import ThermalSDK
import SensorRecordingUtils



final class Video_camera
{

    
    @Published private(set) var device_state_message : String? = nil
    
    
    var is_connected : Bool
    {
        camera.isConnected()
    }
    
    
    init(
            device_identifier : Device.ID_type,
            delegate          : Camera_service_delegate,
            thermal_actor     : Thermal_streamer_actor?  = nil
        )
    {
        
        self.device_identifier = device_identifier
        self.thermal_actor     = thermal_actor
        self.delegate          = delegate
                        
        camera = FLIRCamera()
        camera.delegate = delegate
        
    }
    
    
    deinit
    {
    }
    
    
    // MARK: - Camera life cycle management
    
    
    func connect() async throws
    {

        let discovery_session = FLIRDiscovery()
        discovery_session.delegate = delegate
        
        defer
        {
            discovery_session.stop()
        }
        
        let identity = try await discover_camera_identity(discovery_session)
        
        try await connect_to_camera(with_identity: identity)
        
        await wait_until_camera_is_ready()
        
        let control     = try await initialise_remote_control()
        let calibration = try await disable_NUC(control)
        try subscribe_to_shutter_state_changes(calibration)
        try subscribe_to_battery_state_changes(control)
        try subscribe_to_camera_state_changes(control)
        
        device_state_message = "Connected to thermal camera"
        
    }
    
    
    func configure_for_data_stream( frame_rate : Int ) async throws
    {
        device_state_message = "Configuring camera to stream data"
        
        let data_stream = try await configure_camera_stream()
        try await configure_frame_rate(data_stream, frame_rate)
        
        device_state_message = "Camera ready to stream data"
        
    }
    
    
    func start_data_stream() -> AsyncThrowingStream<UInt64, Error>
    {
        
        return  AsyncThrowingStream
        {
            continuation in

            continuation.onTermination =
            {
                @Sendable _ in
                
                Task
                {
                    [weak self] in
                    
                    await self?.stop_data_stream()
                }
            }
            
            
            
            do
            {
                guard let data_stream = camera_stream
                    else
                    {
                        throw Device.Recording_error.failed_to_start(
                                device_id   : device_identifier,
                                description : "No data stream were configured"
                            )
                    }
                
                if data_stream.isStreaming
                {
                    throw Device.Recording_error.failed_to_start(
                            device_id   : device_identifier,
                            description : "Data stream is already in progress"
                        )
                }
                
                delegate.set_data_stream_continuation(continuation)
                
                try data_stream.start()
                
            }
            catch let error as Device.Recording_error
            {
                continuation.finish(throwing: error)
            }
            catch
            {
                let error = Device.Recording_error.failed_to_start(
                        device_id   : device_identifier,
                        description : "Data stream start error " +
                                      error.localizedDescription
                    )
                
                continuation.finish(throwing: error)
            }
            
        }
        
    }
    
    
    func stop_data_stream() async
    {
        
        delegate.end_data_stream()
        await thermal_actor?.end_camera_stream()
        
        if let data_stream = camera_stream  ,
           data_stream.isStreaming
        {
            data_stream.stop()
        }
        
    }
    
    
    func disconnect()
    {
        
        unsubscribe_from_flir_state_changes()
        
        if camera.isConnected()
        {
            camera.disconnect()
        }
        
        delegate.cancel_camera_discovery()
        
        flir_calibration = nil
        battery_control  = nil
        remote_control   = nil
        camera_stream    = nil
        
    }
    
    
    // MARK: - Private state
    
    
    /**
     * Unique identifier for the device.
     */
    private let device_identifier  : Device.ID_type
    private let delegate           : Camera_service_delegate
    private var camera             : FLIRCamera
            
    private var image_sequence   : UInt64 = 0
    
    private var camera_stream    : FLIRStream?          = nil
    
    private var thermal_actor    : Thermal_streamer_actor?
    
    
    private var remote_control   : FLIRRemoteControl?   = nil
    private var battery_control  : FLIRBattery?         = nil
    private var flir_calibration : FLIRCalibration?     = nil
        
    
    // MARK: - Private interface
    
    
    private func discover_camera_identity(
            _  session : FLIRDiscovery
        ) async throws -> FLIRIdentity
    {
        
        device_state_message = "Searching for thermal camera ..."
        
        return try await withTaskCancellationHandler
        {
            
            [weak self] in
            
            self?.device_state_message = "Cancelling searching for camera ..."
            session.stop()
            self?.delegate.cancel_camera_discovery()
            
        }
        operation :
        {
            
            try await withCheckedThrowingContinuation
            {
                [weak self] continuation in
                
                guard let self = self
                    else
                    {
                        return
                    }
                
                do
                {
                    
                    if  session.isDiscovering()
                    {
                        throw Device.Connect_error.failed_to_connect_to_device(
                                device_id   : self.device_identifier,
                                description : "Camera discovery already in " +
                                              "progress"
                            )
                    }
                    
                    self.delegate.set_camera_discovery_continuation(continuation)
                    session.start(.lightning)
                    
                }
                catch let error as Device.Connect_error
                {
                    continuation.resume(throwing: error)
                }
                catch
                {
                    let error = Device.Connect_error.failed_to_connect_to_device(
                            device_id   : self.device_identifier,
                            description : "Cannot discover camera " +
                                          error.localizedDescription
                        )
                    
                    continuation.resume(throwing: error)
                }
            }
            
        }
        
    }
    
    
    private func connect_to_camera(
            with_identity  identity : FLIRIdentity
        ) async throws
    {
        
        device_state_message = "Thermal camera found, connecting ..."
        
        if camera.isConnected()
        {
            return
        }
        
        return try await withTaskCancellationHandler
        {
            Task
            {
                [weak self] in
                
                let is_connected = self?.camera.isConnected() ?? false
                
                if is_connected
                {
                    self?.camera.disconnect()
                }
            }
        }
        operation :
        {
            try await withCheckedThrowingContinuation
            {
                continuation in
                        
                Task
                {
                    [weak self] in
                    
                    guard let self = self
                        else
                        {
                            return
                        }
                    
                    
                    let formatter = NumberFormatter()
                    formatter.numberStyle = .ordinal
                    
                    var connection_attempt = 1
                    let wait_time_between_attempts : TimeInterval = 0.5
                    
                    do
                    {
                        
                        repeat
                        {
                            do
                            {
                                
                                try self.camera.connect(identity)
                                
                                if self.camera.isConnected()
                                {
                                    continuation.resume()
                                    break
                                }
                                
                            }
                            catch let ns_error as NSError
                            {
                                let error_is_timeout = (ns_error.code == 1) &&
                                    (ns_error.domain == "camera")
                                
                                if  error_is_timeout == false
                                {
                                    throw ns_error
                                }
                            }
                            
                            
                            // Connection failed, retry
                            
                            
                            connection_attempt += 1
                            
                            let count = formatter.string(for: connection_attempt) ?? "X"
                            
                            let status = check_camera_state()
                            
                            self.device_state_message =
                                "Connecting to thermal camera (\(count) attempt) ...\n\n" +
                                "Camera state is: \(status)"
                            
                            
                            do
                            {
                                try await Task.sleep(
                                        seconds: wait_time_between_attempts
                                    )
                            }
                            catch
                            {
                            }
                            
                        }
                        while (Task.isCancelled == false)        &&
                              (self.camera.isConnected() == false)
                        
                    }
                    catch
                    {
                        continuation.resume(
                            throwing: Device.Connect_error.failed_to_connect_to_device(
                                device_id   : self.device_identifier,
                                description :
                                    "Error type : \(String(describing: error)) " +
                                    " | \(error), error = \(error.localizedDescription)"
                            )
                        )
                    }
                    
                }
            }
            
        }

    }
    
    
    private func check_camera_state() -> String
    {
        
        guard let control = camera.getRemoteControl()
            else
            {
                return "Could not read status"
            }
        
        let camera_state :  String
        
        switch control.getCameraReady()
        {
            case .NOT_READY:
                camera_state = "NOT ready"
                
            case .COOLING:
                camera_state = "Cooling"
                
            case .READY:
                camera_state = "Ready"
                
            default:
                camera_state = "Unknown"
        }
        
        return camera_state
        
    }
    
    
    private func initialise_remote_control() async throws -> FLIRRemoteControl
    {
        
        device_state_message = "Getting camera remote controller ..."
        
        guard let control = camera.getRemoteControl()
            else
            {
                throw Device.Connect_error.failed_to_apply_configuration(
                        device_id   : device_identifier,
                        description : "failed to get FLIR remote controller "
                    )
            }
        
        remote_control = control
        remote_control?.delegate = delegate
        
        return control

    }
    
    
    private func wait_until_camera_is_ready() async
    {
        
        device_state_message = "Waiting for camera to be ready ..."
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        
        var connection_attempt = 1
        let wait_time_between_attempts : TimeInterval = 0.5
                
        repeat
        {
            if let control = camera.getRemoteControl()  ,
               control.getCameraReady() == .READY
            {
                break
            }
                
            connection_attempt += 1
            let count = formatter.string(for: connection_attempt) ?? "X"
            
            device_state_message = "Waiting for camera to be ready (\(count) attempt) ..."
            
            do
            {
                try await Task.sleep(seconds: wait_time_between_attempts)
            }
            catch
            {
            }
        }
        while (Task.isCancelled == false)

    }
    
    
    private func disable_NUC(
            _  control : FLIRRemoteControl
        ) async throws -> FLIRCalibration
    {
        
        device_state_message = "Disabling NUC ..."
        
        guard let calibration = control.getCalibration()
            else
            {
                throw Device.Connect_error.failed_to_apply_configuration(
                        device_id   : device_identifier,
                        description : "failed to get camera calibration interface"
                    )
            }
        
        flir_calibration = calibration
        
        do
        {
            try calibration.performNUC()
        }
        catch
        {
            throw Device.Connect_error.failed_to_apply_configuration(
                    device_id   : device_identifier,
                    description : "Cannot perform NUC: " +
                                  error.localizedDescription
                )
        }
        
        do
        {
            try calibration.setNucInterval(0)
        }
        catch
        {
            throw Device.Connect_error.failed_to_apply_configuration(
                    device_id   : device_identifier,
                    description : "Cannot disable NUC: " +
                                  error.localizedDescription
                )
        }
        
        return calibration
        
    }
    
    
    private func subscribe_to_shutter_state_changes(
            _  calibration : FLIRCalibration
        ) throws
    {
        
        do
        {
            try calibration.subscribeShutterState()
        }
        catch
        {
            throw Device.Connect_error.failed_to_apply_configuration(
                    device_id   : device_identifier,
                    description : "Cannot subscribe to shutter state " +
                                  "changes"
                )
        }
        
    }
    
    
    private func subscribe_to_battery_state_changes(
            _  control : FLIRRemoteControl
        ) throws
    {
        
        device_state_message = "Subscribing to battery state changes ..."
        
        guard let battery = control.getBattery()
            else
            {
                throw Device.Connect_error.failed_to_apply_configuration(
                        device_id   : device_identifier,
                        description : "Cannot get battery control interface"
                    )
            }
        
        
        battery_control = battery
        
        do
        {
            try battery_control?.subscribePercentage()
        }
        catch
        {
            throw Device.Connect_error.failed_to_apply_configuration(
                    device_id   : device_identifier,
                    description : "Cannot subscribe to battery percentage " +
                                  "notifications"
                )
        }
        
        
        do
        {
            try battery_control?.subscribeChargingState()
        }
        catch
        {
            throw Device.Connect_error.failed_to_apply_configuration(
                    device_id   : device_identifier,
                    description : "Cannot subscribe to battery charging " +
                                  "state notifications"
                )
        }
        
    }
    
    
    
    
    private func subscribe_to_camera_state_changes(
            _  control : FLIRRemoteControl
        ) throws
    {
        
        device_state_message = "Subscribing to camera state changes ..."
        
        do
        {
            try control.subscribeCameraState()
        }
        catch
        {
            throw Device.Connect_error.failed_to_connect_to_device(
                    device_id   : self.device_identifier,
                    description : "Cannot subscribe to camera " +
                                  "sate changes, error = " +
                                  error.localizedDescription
                )
        }
        
    }
    
    
    private func configure_camera_stream() async throws -> FLIRStream
    {
        
        device_state_message = "Configuring camera to stream data"

        guard let thermal_streamer = thermal_actor
            else
            {
                throw Device.Connect_error.failed_to_connect_to_device(
                        device_id   : device_identifier,
                        description : "No Thermal streamer actor found"
                    )
            }
        
        guard let data_stream = camera.getStreams().first
            else
            {
                throw Device.Connect_error.failed_to_connect_to_device(
                        device_id   : device_identifier,
                        description : "No data streams found for camera"
                    )
            }
            
        camera_stream  = data_stream
        camera_stream?.delegate = delegate
        
        await thermal_streamer.add_camera_stream(data_stream)
        
        return data_stream
        
    }
    
    
    private func configure_frame_rate(
            _  data_stream : FLIRStream,
            _  frame_rate  : Int
        ) async throws
    {
        
        device_state_message = "Configuring frame rate ..."
        
        do
        {
            try data_stream.setFrameRate( Double(frame_rate) )
        }
        catch
        {
            let min_fps = data_stream.getMinFrameRate()
            let max_fps = data_stream.getMaxFrameRate()
            
            throw Device.Connect_error.failed_to_apply_configuration(
                    device_id   : device_identifier,
                    description : "Can't set frame rate to \(frame_rate) FPS. " +
                    "The valid range is [\(min_fps) - \(max_fps)] , error " +
                        error.localizedDescription
                )
        }
        
    }
    
    
    private func unsubscribe_from_flir_state_changes()
    {
        
        battery_control?.unsubscribePercentage()
        battery_control?.unsubscribeChargingState()
        flir_calibration?.unsubscribeShutterState()
        
    }
    
}
