/**
 * \file    recording_manager.swift
 * \author  Mauricio Villarroel
 * \date    Created: Jan 9, 2022
 * ____________________________________________________________________________
 *
 * Copyright (C) 2022 Mauricio Villarroel. All rights reserved.
 *
 * SPDX-License-Identifer:  GPL-2.0-only
 * ____________________________________________________________________________
 */

import SwiftUI
import UIKit
import Combine
import Accelerate
import ThermalSDK
import SensorRecordingUtils


@MainActor
public final class Recording_manager : Device_manager
{
    
    @Published private(set) var device_state_message : String?
    
    @Published private(set) var max_temperature: Double
    @Published private(set) var min_temperature: Double
    
    @Published private(set) var preview_image  : UIImage
    
    @Published private(set) var avg_frame_rate : Double
    
    @Published private(set) var battery_percentage : Int
    
    @Published private(set) var battery_state : UIDevice.BatteryState
    @Published private(set) var camera_state  : Camera_state
    @Published private(set) var shutter_state : FLIRShutterState
    
    @Published private(set) var number_of_frames_lost : Int = 0
    
    @Published private(set) var total_number_of_frames_lost : Int = 0
    
    /**
     * Unique identifier for the FLIR camera used throughout the app.
     * Only one instance of the camera is allowed.
     */
    static let camera_identifier:  Device.ID_type = "flir"
    
    
    /**
     * The maximum resolution of the FLIR one PRO LT camera
     */
    static let max_camera_resolution = CGSize(width: 160, height: 120)
    
    
    /**
     * Class initialisation
     */
    public init(
            orientation          : UIDeviceOrientation,
            preview_mode         : Device.Content_mode,
            device_state         : Device.Recording_state,
            connection_timeout   : Double,
            device_state_message : String?  = nil,
            max_temperature      : Double   = 40.0,
            min_temperature      : Double   = 20.0,
            default_image        : UIImage? = nil,
            avg_frame_rate       : Double   = 0.0,
            battery_percentage   : Int      = 0,
            battery_state        : UIDevice.BatteryState = .unknown,
            camera_state         : Camera_state          = .unknown,
            shutter_state        : FLIRShutterState      = .on
        )
    {
        
        self.device_state_message = device_state_message
        self.max_temperature      = max_temperature
        self.min_temperature      = min_temperature
        
        if let new_image = default_image
        {
            self.preview_image = new_image
        }
        else
        {
            // Create a temp image with the max resolution of the
            // FLIR one camera
            self.preview_image = UIColor.white.image(Self.max_camera_resolution)
        }
        
        self.avg_frame_rate     = avg_frame_rate
        self.battery_percentage = battery_percentage
        self.battery_state      = battery_state
        self.camera_state       = camera_state
        self.shutter_state      = shutter_state
        
        
        // Cache the configuration
        
        
        camera_position               = settings.camera_position
        recording_enabled             = settings.recording_enabled
        recording_frame_rate          = settings.frame_rate
        display_enabled               = settings.display_enabled
        display_image_statistics      = settings.display_image_statistics
        statistics_reporting_interval = settings.statistics_reporting_interval
        statistics_buffer_size        = settings.statistics_buffer_size
        
        flir_recording_fusion_mode = settings.recordig_fusion_mode.to_FUSION_MODE
        flir_display_fusion_mode   = settings.display_fusion_mode.to_FUSION_MODE
        
        
        thermal_actor = Thermal_streamer_actor(Self.camera_identifier)
        
        video_camera = Video_camera(
                device_identifier  : Self.camera_identifier,
                thermal_actor      : thermal_actor,
                battery_percentage : battery_percentage,
                battery_state      : battery_state,
                camera_state       : camera_state,
                shutter_state      : shutter_state
            )
        
        
        if display_enabled
        {
            buffer_len = statistics_buffer_size * recording_frame_rate
            
            reporting_interval_len = statistics_reporting_interval *
                recording_frame_rate
        }
        else
        {
            buffer_len             = 0
            reporting_interval_len = 0
        }
        
        
        super.init(
                identifier   : Self.camera_identifier,
                sensor_type  : .video_camera,
                settings     : self.settings,
                orientation  : orientation,
                preview_mode : preview_mode,
                device_state : device_state,
                connection_timeout: connection_timeout
            )
        
     
        video_camera.$device_state_message.receive(on: RunLoop.main)
           .assign(to: &$device_state_message)
        
        video_camera.$manager_event.receive(on: RunLoop.main)
            .assign(to: &$manager_event)
        
        video_camera.$battery_percentage.receive(on: RunLoop.main)
           .assign(to: &$battery_percentage)
        
        video_camera.$battery_state.receive(on: RunLoop.main)
           .assign(to: &$battery_state)
        
        video_camera.$camera_state.receive(on: RunLoop.main)
           .assign(to: &$camera_state)
        
    }
    
    
    // MARK: - Device life cycle management methods
    
    
    public override func device_check_access() async throws
    {
    }

    
    public override func device_connect(recording_path: URL) async throws
    {
        
        output_folder_path = recording_path
        
        try await video_camera.connect()
        
        // Set the device manager as connected here, so we can later
        // gracefully disconnect from the FLIR camera as part of the
        // normal Device Manager's life cycle management
        
        set_device_connected()
        
        try await video_camera.configure_for_data_stream(frame_rate: recording_frame_rate)
        
    }
    
    
    public override func device_start_recording() async throws
    {
        
        if is_recording
        {
            return
        }
                        
        flir_recording_task = Task.detached(priority: .high)
        {
            [weak self] in
            
            await self?.start_data_stream()
        }
        
        is_recording = true
        
    }
    
    
    public override func device_stop_recording() async throws
    {
        
        flir_recording_task?.cancel()
        flir_recording_task = nil
        
        await video_camera.stop_data_stream()
        await thermal_actor.end_camera_stream()
        
        is_recording = false
        
    }
    
    
    public override func device_disconnect() async throws
    {
        
        video_camera.disconnect()
        
        for ui_subscription in ui_changes_subscriptions
        {
            ui_subscription.cancel()
        }
        
        ui_changes_subscriptions.removeAll()
        
    }
    
    
    // MARK: - Private state
    
    
    /**
     * The recording settings for the camera
     */
    private let settings = Recording_settings()
    
    private let thermal_actor : Thermal_streamer_actor
    private var video_camera  : Video_camera
        
    /**
     * The collection of subscriptions to publishers for events from the UI
     */
    private var ui_changes_subscriptions = Set<AnyCancellable>()
    
    private var flir_recording_task  : Task<Void, Never>? = nil
    private var is_recording = false
    
    
    // Cached settings
    
    
    private let camera_position               : Camera.Position
    private let recording_enabled             : Bool
    private let recording_frame_rate          : Int
    private let display_enabled               : Bool
    private let display_image_statistics      : Bool
    private let statistics_reporting_interval : Int
    private let statistics_buffer_size        : Int
    
    
    private let flir_recording_fusion_mode    : FusionMode
    private let flir_display_fusion_mode      : FusionMode
    
    
    private var output_folder_path : URL = URL(fileURLWithPath: "")
    
    
    // MARK: - Parameters for reporting image statistics
    
    
    var previous_frame_timestamp  : TimeInterval = Date().epoch()
    var previous_frame_sequence   : UInt64 = 0
    
    
    var frame_rate_buffer      : [Double] = []
    var min_temperature_buffer : [Double] = []
    var max_temperature_buffer : [Double] = []

    let buffer_len   : Int
    var buffer_index : Int = 0
    
    
    let reporting_interval_len : Int
    var reporting_index    = 0
    
    
    var lost_frames_counter = 0
    
    
    // MARK: - Private interface
    
    
    
    private func initialise_image_statistics_buffers()
    {
        
        total_number_of_frames_lost = 0
        number_of_frames_lost       = 0
        lost_frames_counter         = 0
        
        previous_frame_timestamp = Date().epoch()
        previous_frame_sequence  = 0
        buffer_index       = 0
        reporting_index    = 0
        
        frame_rate_buffer      = Array(repeating: 0, count: buffer_len)
        min_temperature_buffer = Array(repeating: 0, count: buffer_len)
        max_temperature_buffer = Array(repeating: 0, count: buffer_len)
        
    }
    
    
    private func start_data_stream() async
    {
        
        do
        {
                        
            initialise_image_statistics_buffers()
            
            // Start receiving image frames
            
            for try await frame_sequence in video_camera.start_data_stream()
            {
                
                if Task.isCancelled
                {
                    break
                }
                
                let image_date_taken = try await thermal_actor.update_streamer()
                let frame_timestamp  = image_date_taken.epoch()
                
                
                if recording_enabled
                {
                    let file_sequence    = String(format: "%06d", frame_sequence)
                    let file_timestamp   = frame_timestamp.to_nanoseconds()
                    let file_fusion_mode = flir_recording_fusion_mode.description
                    
                    let file_name = "\(file_sequence)-\(file_timestamp)-\(file_fusion_mode)"
                    
                    let output_file = output_folder_path
                        .appendingPathComponent(file_name)
                        .appendingPathExtension("jpeg")
                    
                    
                    try await thermal_actor.save_image(
                            output_file, flir_recording_fusion_mode
                        )
                }
                
                async let stats_results = new_image_statistics(
                        frame_timestamp,
                        frame_sequence
                    )
                
                async let image_results = new_image_for_display()
                
                
                let _ = await [stats_results, image_results]
                
                previous_frame_timestamp = frame_timestamp
                previous_frame_sequence  = frame_sequence
                
            }
            
        }
        catch Device.Recording_error.fatal_error_while_recording(
                let device_id,
                let description
            )
        {
            
            manager_event = Device_manager_event.fatal_error(
                    device_id   : device_id,
                    description : description
                )
            
        }
        catch
        {
            
            manager_event = Device_manager_event.fatal_error(
                    device_id   : identifier,
                    description : "Error while receiving image frames: " +
                                  error.localizedDescription
                )
            
        }

    }
    
    
    private func new_image_for_display() async -> Bool
    {
        
        if display_enabled == false
        {
            return false
        }
        
        guard let new_image = await self.thermal_actor.get_image_for_display(
            self.flir_display_fusion_mode
        )
        else
        {
            return false
        }
        
        preview_image = rotate_image(new_image, camera_position, interface_orientation)
        
        return true
        
    }
    
    
    private func new_image_statistics(
            _  frame_timestamp     : TimeInterval,
            _  frame_sequence      : UInt64
        ) async  -> Bool
    {
        
        if display_image_statistics == false
        {
            return false
        }
        
        let (min_temp, max_temp) = await thermal_actor.get_temperatute_range()
        
        // fill the bufffers
        
        
        let frame_interval = frame_timestamp - previous_frame_timestamp
        
        let fps = (frame_interval == 0) ? 0 : (1.0 / frame_interval)

        if buffer_index >= buffer_len
        {
            buffer_index = 0
        }

        frame_rate_buffer[buffer_index]      = fps
        min_temperature_buffer[buffer_index] = min_temp
        max_temperature_buffer[buffer_index] = max_temp
        
        
        // Compute frames lost
        
        
        let is_interval_skipped = (frame_interval == 0)
        let number_of_intervals_skipped = is_interval_skipped ? 1 : 0

        let sequence_diff  = Int(frame_sequence - previous_frame_sequence)
        let sequences_skipped = (sequence_diff > 1) ? (sequence_diff - 1) : 0

        lost_frames_counter += max(number_of_intervals_skipped, sequences_skipped)


        // report statistics if needed

        
        if reporting_index >= reporting_interval_len
        {
            avg_frame_rate  = vDSP.mean(frame_rate_buffer)
            min_temperature = vDSP.mean(min_temperature_buffer)
            max_temperature = vDSP.mean(max_temperature_buffer)

            number_of_frames_lost = lost_frames_counter
            total_number_of_frames_lost += lost_frames_counter

            reporting_index   = 0
            lost_frames_counter = 0
        }

        buffer_index    += 1
        reporting_index += 1
        
        return true
        
    }
    
    
    @inline(__always)
    private func rotate_image(
            _  image: UIImage,
            _  camera_position       : Camera.Position,
            _  interface_orientation : UIDeviceOrientation
        ) -> UIImage
    {
        
        var rotate_flag = true
        
        let new_orientation : UIImage.Orientation
        
        switch interface_orientation
        {
            case .portrait:
                if camera_position == .back
                {
                    rotate_flag     = false
                    new_orientation = .up
                }
                else
                {
                    new_orientation = .upMirrored
                }
                
            case .portraitUpsideDown:
                new_orientation = (camera_position == .back) ? .downMirrored : .down
                
            case .landscapeLeft:
                new_orientation = (camera_position == .back) ? .left : .leftMirrored
                
            case .landscapeRight:
                new_orientation = (camera_position == .back) ? .right : .rightMirrored
                
            default:
                rotate_flag     = false
                new_orientation = .up
        }
        
        
        
        if rotate_flag
        {
            return UIImage(
                cgImage     : image.cgImage!,
                scale       : image.scale,
                orientation : new_orientation
            )
        }
        else
        {
            return image
        }
                
    }
    
    
}

