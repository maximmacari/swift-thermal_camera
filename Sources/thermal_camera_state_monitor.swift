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
        camera_service.is_connected
    }
    
    
    public init(
            //battery_percentage_value : Int      = 0,
            //battery_state_value  : UIDevice.BatteryState = .unknown,
            camera_state         : Camera_state          = .unknown,
            shutter_state        : FLIRShutterState      = .on
        )
    {
     
//        print("Thermal_camera_state : init")
        
        let device_id = Recording_manager.camera_identifier
        
        self.camera_state  = camera_state
        self.shutter_state = shutter_state
        
        device_identifier = device_id
        
        delegate = Camera_service_delegate(
                device_identifier  : device_id
            )
                
        camera_service = Video_camera(
                device_identifier : device_id,
                delegate          : delegate
            )
        
        
        // Subscribe to events from the thermal camera
        
        
        delegate.$camera_state.assign(to: &$camera_state)
        
        camera_service.$device_state_message.assign(to: &$device_state_message)
        
        
        delegate.$manager_event
            .sink
            {
                [weak self] event in
                
                self?.thermal_camera_system_event(event)
            }
            .store(in: &state_changes_subscriptions)
        
        
        delegate.$battery_percentage
            .sink
            {
                [weak self] value in
                
                self?.new_battery_percentage(value)
            }
            .store(in: &state_changes_subscriptions)
        
        
        delegate.$battery_state
            .sink
            {
                [weak self] value in
                
                self?.new_battery_state(value)
            }
            .store(in: &state_changes_subscriptions)
        
    }
    
    
    deinit
    {
        
//        print("Thermal_camera_state : deinit")
        
        for ui_subscription in state_changes_subscriptions
        {
            ui_subscription.cancel()
        }
        
        state_changes_subscriptions.removeAll()
        
        stop()
        
    }
    
    
    // MARK: - Public interface
    
    
    public func start()
    {
        
        if is_connected  ||  ( connection_task != nil )
        {
            return
        }
        
        
        keep_alive_flag      = true
        
        connection_task?.cancel()
        
        device_state_message = nil
        battery_percentage   = nil
        battery_state        = nil
        
        
        connection_task = Task
        {
            [weak self] in

            await self?.connect_to_camera()
        }
        
        if watchdog_timer == nil
        {
            start_watchdog_timer()
        }

    }
    
    
    public func stop()
    {
        
        keep_alive_flag = false
        
        stop_watchdog_timer()
        disconnect()
        
        device_state_message = "Thermal camera disconnected"
        
    }
    
    
    // MARK: - Private state
    
    
    /**
     * Unique identifier for the device.
     */
    private let device_identifier : Device.ID_type
    private let delegate          : Camera_service_delegate
    private var camera_service    : Video_camera
    private var keep_alive_flag   : Bool = false
    
    private var connection_task         : Task<Void, Never>? = nil
    
    private var state_changes_subscriptions = Set<AnyCancellable>()
    
    
    private var watchdog_timer : AnyCancellable? = nil
    
    private let watchdog_timer_interval : TimeInterval = 10.0
    
    
    // MARK: - Private interface
    
    
    private func start_watchdog_timer()
    {
        
        watchdog_timer = Timer.publish(
                every : watchdog_timer_interval,
                on    : .current,
                in    : .common
            )
            .autoconnect()
            .sink
            {
                [weak self] _ in
                
                self?.restart_camera_if_disconnected()
            }
        
    }
    
    
    private func stop_watchdog_timer()
    {
        
        watchdog_timer?.cancel()
        watchdog_timer = nil
        
    }
    
    
    private func restart_camera_if_disconnected()
    {
        
        
        if keep_alive_flag  &&  (is_connected == false)
        {
            disconnect()
            device_state_message = "Timeout, reconnecting ..."
            start()
        }
        
        
    }
    
    
    private func thermal_camera_system_event( _  event : Device_manager_event )
    {
        
        let reconnect_flag : Bool
        
        switch event
        {

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
                
                reconnect_flag = true
                

            case .device_connect_timeout(let device_id):
                
                device_state_message = "Timeout connecting to thermal camera, reconnecting ..."
                
                print(
                    """


                    Thermal_camera_state : device_manager_event : device_connect_timeout
                    device_id   = \(device_id)

                    """
                    )
                
                reconnect_flag = true
                
                
            case .device_start_timeout(let device_id):
                
                device_state_message = "Timeout starting to stream thermal data, reconnecting ..."
                
                print(
                    """


                    Thermal_camera_state : device_manager_event : device_start_timeout
                    device_id   = \(device_id)

                    """
                    )
                
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
                
                reconnect_flag = true
                
        }
        
        
        if reconnect_flag  &&  keep_alive_flag
        {
            disconnect()
            start()
        }
        
    }
    
    
    private func disconnect()
    {
                
        connection_task?.cancel()
        connection_task = nil
        
        camera_service.disconnect()
        
        device_state_message = nil
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
        
        repeat
        {

            do
            {
                //try await Task.sleep(seconds: wait_time_between_attempts)
                
                device_state_message = "Thermal camera not connected, searching ..."
                
                if camera_service.is_connected == false
                {
                    try await Task.sleep(seconds: wait_time_between_attempts)
                    try await camera_service.connect()
                }
                
                if camera_service.is_connected
                {
                    device_state_message = "Thermal camera connected, waiting " +
                                           "to receive battery status ..."
                }
                
            }
            catch
            {
            }

        }
        while (Task.isCancelled == false)    &&
              (camera_service.is_connected == false)

    }
    
}
