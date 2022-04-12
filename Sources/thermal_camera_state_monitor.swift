/**
 * \file    thermal_camera_state_monitor.swift
 * \author  Mauricio Villarroel
 * \date    Created: Mar 22, 2022
 * ____________________________________________________________________________
 *
 * Copyright (C) 2022 Mauricio Villarroel. All rights reserved.
 *
 * SPDX-License-Identifer:  GPL-2.0-only
 * ____________________________________________________________________________
 */

import Foundation
import Combine
import ThermalSDK
import SensorRecordingUtils


final public class Thermal_camera_state_monitor
{
    
    @Published public private(set) var device_state_message : String? = nil
    
    @Published public private(set) var battery_percentage : Battery_percentage? = nil
    @Published public private(set) var battery_state      : Battery_state?      = nil
    
    @Published private(set) var camera_state  : Camera_state
    @Published private(set) var shutter_state : FLIRShutterState
    
    
    public var is_connected : Bool
    {
        video_camera.is_connected
    }
    
    
    public init(
            camera_state   : Camera_state     = .unknown,
            shutter_state  : FLIRShutterState = .on
        )
    {
        
        self.camera_state  = camera_state
        self.shutter_state = shutter_state
        
        self.device_identifier = Recording_manager.camera_identifier
        
        video_camera = Video_camera(device_identifier : device_identifier)
        
        
        // Subscribe to events from the thermal camera
        
        
        video_camera.$device_state_message.assign(to: &$device_state_message)
        
        video_camera.$manager_event
            .sink
            {
                [weak self] event in
                
                self?.thermal_camera_system_event(event)
            }
            .store(in: &state_changes_subscriptions)
        
        
        video_camera.$battery_percentage
            .sink
            {
                [weak self] value in
                
                self?.new_battery_percentage(value)
            }
            .store(in: &state_changes_subscriptions)
        
        
        video_camera.$battery_state
            .sink
            {
                [weak self] value in
                
                self?.new_battery_state(value)
            }
            .store(in: &state_changes_subscriptions)
        
        video_camera.$camera_state.assign(to: &$camera_state)
        
    }
    
    
    // MARK: - Public interface
    
    
    public func start()
    {
        
        keep_alive_flag = true
        restart_camera_if_disconnected()

    }
    
    
    public func stop()
    {
        
        keep_alive_flag = false
        disconnect()
        device_state_message = "Thermal camera disconnected"
        
    }
    
    
    // MARK: - Private state
    
    
    /**
     * Unique identifier for the device.
     */
    private let device_identifier : Device.ID_type
    private var video_camera      : Video_camera
    private var keep_alive_flag   : Bool = false
    
    private var connection_task   : Task<Bool, Never>? = nil
    private var is_connecting     : Bool = false
    
    private var state_changes_subscriptions = Set<AnyCancellable>()
    
    
    // MARK: - Private interface
    
    
    private func restart_camera_if_disconnected()
    {
        
        if keep_alive_flag          &&
           (is_connected == false)  &&
           (is_connecting == false)
        {
            
            connection_task = Task
            {
                [weak self] in
                
                guard let self = self else { return false }

                await self.connect_to_camera()
                
                return self.is_connected
            }
        }
        
    }
    
    
    private func thermal_camera_system_event( _  event : Device_manager_event )
    {
        
        let reconnect_flag : Bool
        
        switch event
        {
                
            case .not_set:
                
                reconnect_flag = false

            case .recording_state_update(_ , _):
                
                reconnect_flag = false
                
                
            case .device_disconnected(let device_id, let description):
                
                device_state_message = "Thermal camera disconnected, reconnecting ..."
                
                print(
                    """


                    Thermal_camera_state : device_manager_event : device_disconnected
                    device_id   = \(device_id)
                    description = \(description ?? "-")


                    """
                    )
                
                disconnect()
                reconnect_flag = true
                

            case .device_connect_timeout(let device_id):
                
                device_state_message = "Timeout connecting to thermal camera, reconnecting ..."
                
                print(
                    """


                    Thermal_camera_state : device_manager_event : device_connect_timeout
                    device_id   = \(device_id)

                    """
                    )
                
                disconnect()
                reconnect_flag = true
                
                
            case .device_start_timeout(let device_id):
                
                device_state_message = "Timeout starting to stream thermal data, reconnecting ..."
                
                print(
                    """


                    Thermal_camera_state : device_manager_event : device_start_timeout
                    device_id   = \(device_id)

                    """
                    )
                
                disconnect()
                reconnect_flag = true
                
                
            case .fatal_error(let device_id, let description):
                
                device_state_message = "A fatal error occurred with the thermal camera, reconnecting ..."
                
                print(
                    """


                    Thermal_camera_state : device_manager_event : fatal_error
                    device_id   = \(device_id)
                    description = \(description)

                    """
                    )
                
                disconnect()
                reconnect_flag = true
                
        }
        
        
        if reconnect_flag  &&  keep_alive_flag
        {
            device_state_message = "Thermal camera not connected, searching ..."
            
            Task
            {
                if let task = connection_task
                {
                    let _ = await task.value
                }
                
                restart_camera_if_disconnected()
            }
        }
        
    }
    
    
    private func disconnect()
    {
                
        device_state_message = "Disconnecting from thermal camera..."
        
        connection_task?.cancel()
        video_camera.disconnect()
        
        device_state_message = "Disconnected from thermal camera"
        battery_percentage   = nil
        battery_state        = nil
        
    }
    
    
    private func new_battery_percentage( _ value : Int )
    {
        
        if var current_percentage = battery_percentage
        {
            current_percentage.value = value
        }
        else
        {
            battery_percentage = .init(
                    device_id : device_identifier,
                    value     : value
                )
        }
        
    }
    
    
    private func new_battery_state( _ value : UIDevice.BatteryState )
    {
        
        if var current_state = battery_state
        {
            current_state.value = value
        }
        else
        {
            battery_state = .init(
                    device_id : device_identifier,
                    value     : value
                )
        }
        
    }
    
    
    private func connect_to_camera() async
    {
        
        let wait_time_between_attempts : TimeInterval = 1
        
        device_state_message = nil
        battery_percentage   = nil
        battery_state        = nil
        
        is_connecting = true
        
        while (Task.isCancelled == false)    &&
              (video_camera.is_connected == false) &&
              keep_alive_flag
        {
            
            device_state_message = "Thermal camera not connected, searching ..."
            
            do
            {
                try await video_camera.connect()
                
                device_state_message = "Thermal camera connected, waiting " +
                                       "to receive battery status ..."
            }
            catch
            {
                if Task.isCancelled == false  &&  keep_alive_flag
                {
                    video_camera.disconnect()
                    
                    do
                    {
                        try await Task.sleep(seconds: wait_time_between_attempts)
                    }
                    catch
                    {
                    }
                }
            }

        }
        
        is_connecting = false

    }
    
}
