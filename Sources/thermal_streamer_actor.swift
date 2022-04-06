/**
 * \file    flir_thermal_actor.swift
 * \author  Mauricio Villarroel
 * \date    Created: Mar 16, 2022
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


actor Thermal_streamer_actor
{
    
    
    init( _  device_identifier : Device.ID_type )
    {
        
        self.device_identifier = device_identifier
        
    }
    
    
    deinit
    {
        thermal_streamer = nil
    }
    
    
    // MARK: - Public interface
    
    
    func add_camera_stream( _ stream : FLIRStream )
    {

        thermal_streamer = FLIRThermalStreamer(stream: stream)
        
    }
    
    
    func end_camera_stream()
    {

        thermal_streamer = nil
        
    }
    
    
    func update_streamer() throws -> Date
    {

        guard let data_streamer = thermal_streamer
            else
            {
                throw Device.Recording_error.fatal_error_while_recording(
                    device_id   : device_identifier,
                    description : "Thermal streamer is not initialised"
                )
            }

        do
        {
            try data_streamer.update()
        }
        catch
        {
            throw Device.Recording_error.fatal_error_while_recording(
                device_id   : device_identifier,
                description : "Can't update thermal streamer: " +
                              error.localizedDescription
            )
        }

        var frame_timestamp : Date?
        
        data_streamer.withThermalImage()
        {
            image in
            frame_timestamp = image.getDateTaken()
        }

        guard let timestamp = frame_timestamp
            else
            {
                throw Device.Recording_error.fatal_error_while_recording(
                    device_id   : device_identifier,
                    description : "Can't read image timestamp."
                )
            }
        
        return timestamp
        
    }
    
    
    func save_image(
            _  output_file : URL,
            _  fusion_mode : FusionMode
        ) throws
    {
            
        guard let data_streamer = thermal_streamer
            else
            {
                return
            }
        

        var writing_error : Error? = nil
        
        data_streamer.withThermalImage()
        {
            image in

            image.getFusion()?.setFusionMode(fusion_mode)

            do
            {
                try image.save(as: output_file.path)
            }
            catch
            {
                writing_error = error
            }
        }
        
        if let error = writing_error
        {
            throw Device.Recording_error.fatal_error_while_recording(
                device_id   : device_identifier,
                description : "[EE] Failed to write FLIR frame to disk: " +
                              error.localizedDescription
            )
        }
        
    }
    
    
    func get_image_for_display(
            _  fusion_mode : FusionMode
        ) -> UIImage?
    {
        
        guard let data_streamer = thermal_streamer
            else
            {
                return nil
            }

        data_streamer.withThermalImage()
        {
            image in

            image.getFusion()?.setFusionMode(fusion_mode)
            image.palette = image.paletteManager?.iron
        }
        
        // FIXME: Eventhough FLIR's documentation says this method returns a
        // deepcopy of the image, it is not true
        return data_streamer.getImage()
        
    }
    
    
    func get_temperatute_range() -> (min : Double, max : Double)
    {
        
        guard let data_streamer = thermal_streamer
            else
            {
                return (0,0)
            }
        
        
        // Update image statistics
        
        var min_temperature : Double = 0
        var max_temperature : Double = 0

        data_streamer.withThermalImage()
        {
            image in

            if let stats = image.getStatistics()
            {
                min_temperature = stats.getMin().asCelsius().value
                max_temperature = stats.getMax().asCelsius().value
            }
        }
        
        return (min_temperature, max_temperature)
        
    }
    
    
    // MARK: - Private state
    
    
    private let device_identifier : Device.ID_type
    private var thermal_streamer  : FLIRThermalStreamer? = nil
    
    
}
