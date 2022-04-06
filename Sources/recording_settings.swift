/**
 * \file    recording_settings.swift
 * \author  Mauricio Villarroel
 * \date    Created: Jan 18, 2022
 * ____________________________________________________________________________
 *
 * Copyright (C) 2022 Mauricio Villarroel. All rights reserved.
 *
 * SPDX-License-Identifer:  GPL-2.0-only
 * ____________________________________________________________________________
 */

import Foundation
import SensorRecordingUtils


/**
 * Settings for the FLIR camera
 */
final class Recording_settings : Device_settings
{
    
    /**
     * Is displaying the video on screen enabled?
     */
    var display_enabled : Bool
    {
        get
        {
            return store.bool(forKey: display_enabled_key)
        }
        
        set(new_value)
        {
            store.set(new_value, forKey: display_enabled_key)
        }
    }
    
    
    /**
     * Display statistics such as temperature, frame rate, etc?
     */
    var display_image_statistics : Bool
    {
        get
        {
            return store.bool(forKey: display_image_statistics_key)
        }
        
        set(new_value)
        {
            store.set(new_value, forKey: display_image_statistics_key)
        }
    }
    
    
    /**
     * Compute and report image statistics (such as FPS, temperature, etc) every X seconds
     */
    var statistics_reporting_interval : Int
    {
        get
        {
            return store.integer(forKey: statistics_reporting_interval_key)
        }
        
        set(new_value)
        {
            store.set(new_value, forKey: statistics_reporting_interval_key)
        }
    }
    
    
    /**
     * The size, in seconds of the buffer for a given image statistic
     */
    var statistics_buffer_size : Int
    {
        get
        {
            return store.integer(forKey: statistics_buffer_size_key)
        }
        
        set(new_value)
        {
            store.set(new_value, forKey: statistics_buffer_size_key)
        }
    }
    
    
    /**
     * The location of the configured camera, i.e.: front, back ...
     */
    var camera_position : Camera.Position
    {
        get
        {
            if let key_value = store.string(forKey: camera_position_key) ,
               let position  = Camera.Position(rawValue: key_value)
            {
                return position
            }
            else
            {
                return Camera.Position.back
            }
        }
        
        set(new_value)
        {
            store.set(new_value.rawValue, forKey: camera_position_key)
        }
    }
    
    
    /**
     * Recording frame rate
     */
    var frame_rate : Int
    {
        get
        {
            return store.integer(forKey: frame_rate_key)
        }
        
        set(new_value)
        {
            store.set(new_value, forKey: frame_rate_key)
        }
    }
    
    
    var recordig_fusion_mode : Thermal_fusion_mode
    {
        get
        {
            if let key_value = store.string(forKey: recording_fusion_mode_key) ,
               let mode = Thermal_fusion_mode(rawValue: key_value)
            {
                return mode
            }
            else
            {
                return .Visual_mode
            }
        }
        
        set(new_value)
        {
            store.set(new_value.rawValue, forKey: recording_fusion_mode_key)
        }
    }
    
    
    var display_fusion_mode : Thermal_fusion_mode
    {
        get
        {
            if let key_value = store.string(forKey: display_fusion_mode_key) ,
               let mode = Thermal_fusion_mode(rawValue: key_value)
            {
                return mode
            }
            else
            {
                return .IR_mode
            }
        }
        
        set(new_value)
        {
            store.set(new_value.rawValue, forKey: display_fusion_mode_key)
        }
    }
    
    
    /**
     * Type innitialiser
     */
    init()
    {
        
        let key_prefix = "thermal_"
        
        display_enabled_key               = key_prefix + "display_enabled"
        display_image_statistics_key      = key_prefix + "display_image_statistics"
        statistics_reporting_interval_key = key_prefix + "statistics_reporting_interval"
        statistics_buffer_size_key        = key_prefix + "statistics_buffer_size"
        camera_position_key               = key_prefix + "camera_position"
        frame_rate_key                    = key_prefix + "frame_rate"
        recording_fusion_mode_key         = key_prefix + "recording_fusion_mode"
        display_fusion_mode_key           = key_prefix + "display_fusion_mode"
        
        super.init(key_prefix: key_prefix)
        
    }
    
    
    // MARK: - Private state
    
    
    private let display_enabled_key               : String
    private let display_image_statistics_key      : String
    private let statistics_reporting_interval_key : String
    private let statistics_buffer_size_key        : String
    private let camera_position_key               : String
    private let frame_rate_key                    : String
    private let recording_fusion_mode_key         : String
    private let display_fusion_mode_key           : String
    
}
