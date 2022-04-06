/**
 * \file    camera_reader.swift
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


/**
 * Receives the content of the image data from the FLIR camera stream
 */
@MainActor
final class Camera_reader : ObservableObject
{
    
    @Published private(set) var image : UIImage = UIImage()
    
    @Published private(set) var battery_percentage : Int = 0
    
    @Published private(set) var max_temperature: Double = 40.0
    @Published private(set) var min_temperature: Double = 20.0
    
    @Published private(set) var frame_rate : Double = 0.0
    
    
    /**
     * Class initialiser
     */
    init(
            device_identifier             : Device.ID_type ,
            camera_service                : Video_camera,
            thermal_streamer              : Thermal_streamer_actor,
            camera_position               : Camera.Position,
            recording_enabled             : Bool,
            recording_frame_rate          : Int,
            display_enabled               : Bool,
            display_image_statistics      : Bool,
            statistics_reporting_interval : Int,
            statistics_buffer_size        : Int
        )
    {
        
        self.device_identifier = device_identifier
        self.camera_service    = camera_service
        self.thermal_streamer  = thermal_streamer
        self.camera_position   = camera_position
        
        self.recording_enabled        = recording_enabled
        self.recording_frame_rate     = recording_frame_rate
        
        self.display_enabled          = display_enabled
        self.display_image_statistics = display_image_statistics
        
        self.statistics_reporting_interval = statistics_reporting_interval
        self.statistics_buffer_size        = statistics_buffer_size
        
    }
    
    
    deinit
    {
    }
    
    
    // MARK: - Public interface
    
    
    func set_interface_orientation(
            _  orientation : UIDeviceOrientation
        )
    {
        interface_orientation = orientation
    }
    
    
    func start() async throws
    {
        if is_recording
        {
            return
        }
        
        // Clean up previous task if it exists
        
        start_recording_task?.cancel()
        start_recording_task = nil
        
        start_recording_task = Task
        {
            [weak self] in
            
            await self?.start_recording()
        }
        
        is_recording = true
        
    }
    
    
    func stop() async throws
    {
        
        defer
        {
            // Clean up previous task if it exists
            
            start_recording_task?.cancel()
            start_recording_task = nil
        }
        
        
        if is_recording
        {
            //camera_service.stop_data_stream()
            is_recording = false
        }
        
    }
    
    
    // MARK: - Private state
    
    
    /**
     * Unique identifier for the device.
     */
    private let device_identifier  : Device.ID_type
    
    private let camera_service    : Video_camera
    private let thermal_streamer  : Thermal_streamer_actor
    private let camera_position   : Camera.Position
    
    private let recording_enabled        : Bool
    private let recording_frame_rate     : Int
    private let display_enabled          : Bool
    private let display_image_statistics : Bool
    private let statistics_reporting_interval  : Int
    private let statistics_buffer_size       : Int
    
    
    private var image_sequence      : UInt64 = 0
    private var interface_orientation : UIDeviceOrientation = .landscapeLeft

    private var start_recording_task  : Task<Void, Never>? = nil
    private var is_recording = false
    
    
    /**
     * Only show changes in 0.1 celsius
     */
    private let max_temp_diff : Double = 0.1
    
    
    // MARK: - Private interface
    
    
    // FIXME: Implement handling of errors
    private func start_recording() async
    {
        
//        do
//        {
//
//            // Initialise image statistics buffers
//
//
//            let buffer_len = statistics_buffer_size * recording_frame_rate
//
//
//            var frame_rate_buffer : [Double] = Array(
//                    repeating: 0, count: buffer_len
//                )
//
//            var min_temperature_buffer : [Double] = Array(
//                    repeating: 0, count: buffer_len
//                )
//
//            var max_temperature_buffer : [Double] = Array(
//                    repeating: 0, count: buffer_len
//                )
//
//            var buffer_index = 0
//
//            let reporting_interval_len = statistics_reporting_interval * recording_frame_rate
//
//            var reporting_index = 0
//
//            var previous_timestamp : Double = 0
//
//
//            // Start receiving image frames
//
//
//            for try await frame_metadata in camera_service.start_data_stream()
//            {
//                await thermal_streamer.update_streamer()
//
//                if recording_enabled
//                {
//                    await thermal_streamer.save_image(
//                            frame_timestamp : frame_metadata.timestamp,
//                            frame_sequence  : frame_metadata.sequence
//                        )
//                }
//
//
//                if  ( display_enabled == true )  ,
//                    let new_image = await thermal_streamer.get_image_for_display()
//                {
//                    image = rotate_image(new_image)
//                }
//
//
//                if display_image_statistics
//                {
//
//                    // Frame rate
//
//                    let new_timestamp = frame_metadata.timestamp.to_seconds
//
//                    let new_fps = 1.0 / (new_timestamp - previous_timestamp)
//
//                    if buffer_index >= buffer_len
//                    {
//                        buffer_index = 0
//                    }
//
//                    frame_rate_buffer[buffer_index] = new_fps
//
//                    // Temperature
//
//                    let (new_min, new_max) = await thermal_streamer.get_temperatute_range()
//
//                    min_temperature_buffer[buffer_index] = new_min
//                    max_temperature_buffer[buffer_index] = new_max
//
//
//                    if reporting_index >= reporting_interval_len
//                    {
//                        var sum = frame_rate_buffer.reduce(0, +)
//                        frame_rate = sum / Double(frame_rate_buffer.count)
//
//                        sum = min_temperature_buffer.reduce(0, +)
//                        min_temperature = sum / Double(frame_rate_buffer.count)
//
//                        sum = max_temperature_buffer.reduce(0, +)
//                        max_temperature = sum / Double(frame_rate_buffer.count)
//
//                        reporting_index = 0
//                    }
//
//                    buffer_index    += 1
//                    reporting_index += 1
//                    previous_timestamp = new_timestamp
//
//                }
//
//            }
//
//
//        }
//        catch let error as Device.Recording_error
//        {
//            //throw error
//            print("\(Date()) : \(String(describing: Self.self)) : \(#function) : " +
//                  "Recording_error = \(error) : " + error.localizedDescription
//                )
//        }
//        catch
//        {
//            print(
//                "\(Date()) : \(String(describing: Self.self)) : \(#function) : " +
//                "Couldn't not start recording : \(error) : " +
//                error.localizedDescription
//                )
//
////            throw Device.Recording_error.failed_to_start(
////                device_id  : device_identifier,
////                description: "Couldn't not subscrebe to notifications for " +
////                             "characteristic \(characteristic_id)"
////            )
//        }

    }
    
    
    // FIXME: Rotation works only if you rotate the phone clockwise
    @inline(__always)
    private func rotate_image( _ old_image: UIImage ) -> UIImage
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
        
        
        let new_image : UIImage
        
        if rotate_flag
        {
            new_image = UIImage(
                cgImage     : old_image.cgImage!,
                scale       : old_image.scale,
                orientation : new_orientation
            )
        }
        else
        {
            new_image = old_image
        }
        
        return new_image
        
    }
    
}
