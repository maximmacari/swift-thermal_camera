/**
 * \file    thermal_camera_view.swift
 * \author  Mauricio Villarroel
 * \date    Created: Dec 28, 2021
 * ____________________________________________________________________________
 *
 * Copyright (C) 2022 Mauricio Villarroel. All rights reserved.
 *
 * SPDX-License-Identifer:  GPL-2.0-only
 * ____________________________________________________________________________
 */

import SwiftUI
import SensorRecordingUtils


public struct Thermal_camera_view: View
{
    
    public var body: some View
    {
        GeometryReader
        {
            geo in
                        
            ZStack
            {
                
                Image(uiImage: manager.preview_image)
                    .resizable()
                    .aspectRatio(
                        nil,
                        contentMode: (manager.preview_mode == .scale_to_fit) ? .fit : .fill
                    )
                    .frame(
                            width     : geo.size.width,
                            height    : geo.size.height
                        )
                    .clipped()

                
                Side_panel(screen_height: geo.size.height)
                    .frame(
                            width     : geo.size.width,
                            height    : geo.size.height,
                            alignment : position
                        )
                
                
                Camera_warning_panel()
                
                
                if manager.device_state != .streaming
                {
                    Camera_recording_state_view
                }
                
            }
            
        }
        
    }
    
    public init(_ manager: Recording_manager)
    {
        _manager = ObservedObject(wrappedValue: manager)
    }
    
    
    // MARK: - Body Views
    
    
    @ViewBuilder
    private func Side_panel(
            screen_height : CGFloat
        ) -> some View
    {
                
        VStack
        {
            
            let panel_height  : CGFloat = min(
                screen_height * 0.8,
                    max_side_panel_height
                )
            
            Temperature_panel(
                    device_id          : manager.identifier,
                    max_temperature    : manager.max_temperature,
                    min_temperature    : manager.min_temperature,
                    battery_percentage : manager.battery_percentage,
                    battery_state      : manager.battery_state,
                    frame_rate         : manager.avg_frame_rate,
                    total_frames_lost  : manager.total_number_of_frames_lost,
                    temperature_unit   : .celsius
                )
            .frame(
                width    : side_panel_width,
                height   : panel_height,
                alignment: position
            )
            
        }
    }
    
    
    /**
     * Panel shown when the camera is not streaming video
     */
    private var Camera_recording_state_view : some View
    {
        VStack
        {
            Text("FLIR camera").font(.system(.title)).padding()
            
            if manager.device_state == .disconnected
            {
                Image(systemName: "video.slash.fill")
                    .font(.system(.largeTitle))
                    .padding()
            }
            else
            {
                ProgressView()
                    .scaleEffect(x: 4, y: 4, anchor: .center)
                    .padding()
                    .padding()
            }
            
            
            Text( manager.device_state.name ).font(.system(.title))
                .padding()
            
            if let message = manager.device_state_message
            {
                Text(message).font(.system(.body))
                    .padding()
            }
            
        }
    }
    
    
    @ViewBuilder
    private func Camera_warning_panel() -> some View
    {
        
        let message = warning_messages
        
        if message.isEmpty == false
        {
            Warning_view(message: message)
        }
        
    }
    
    
    // MARK: - Private state
    
    
    @ObservedObject  private var manager : Recording_manager
    
    private let side_panel_width      : CGFloat = 50
    private let max_side_panel_height : CGFloat = 500
    
    @Environment(\.horizontalSizeClass) private var horizontal_size
    
    
    private var is_landscape : Bool
    {
        horizontal_size == .regular
    }
    
    
    private var position : Alignment
    {
        if manager.interface_orientation == .landscapeRight
        {
            return .leading
        }
        else
        {
            return .trailing
        }
            
    }
    
    
    private var warning_messages : String
    {
        var message : String = ""
        
        let camera_state = manager.camera_state
        
        if (camera_state != .unknown) &&
           (camera_state != .ready)
        {
            message += "Camera state is: \(camera_state.description)"
        }
        
        
        let shutter_state = manager.shutter_state
        
        if shutter_state != .on
        {
            let separator = message.isEmpty ? "" : "\n"
            
            message += "\(separator)Shutter state is: \(shutter_state.description)"
        }
        
        
        let frames_lost = manager.number_of_frames_lost
        
        if frames_lost > 0
        {
            let separator = message.isEmpty ? "" : "\n"
            message += "\(separator)Number of frames lost: \(frames_lost)"
        }
        
        return message
    }
    
}



struct FLIR_view_Previews: PreviewProvider
{
    
    // dummy thermal image
    static let image = UIColor.black.image(
            Recording_manager.max_camera_resolution
        )
    
    static var previews: some View
    {
        
        NavigationView
        {
            Thermal_camera_view(
                    Recording_manager(
                            orientation  : .landscapeLeft,
                            device_state : .disconnected
                        )
                )
                .hide_navigation_interface()
                .ignoresSafeArea()
        }
        .navigationViewStyle(.stack)
        .previewInterfaceOrientation(.landscapeRight)
        
        
        NavigationView
        {
            Thermal_camera_view(
                    Recording_manager(
                            orientation  : .landscapeLeft,
                            device_state : .connecting
                        )
                )
                .hide_navigation_interface()
                .ignoresSafeArea()
        }
        .navigationViewStyle(.stack)
        .previewInterfaceOrientation(.landscapeRight)
        
        NavigationView
        {
            Thermal_camera_view(
                    Recording_manager(
                            orientation  : .landscapeRight,
                            device_state : .connecting
                        )
                )
                .hide_navigation_interface()
                .ignoresSafeArea()
        }
        .navigationViewStyle(.stack)
        .previewInterfaceOrientation(.landscapeLeft)


        NavigationView
        {
            Thermal_camera_view(
                    Recording_manager(
                            orientation          : .portrait,
                            device_state         : .connecting,
                            device_state_message : "Waiting for camera to be ready ..."
                        )
                )
                .hide_navigation_interface()
                .ignoresSafeArea()
        }
        .navigationViewStyle(.stack)
        .previewInterfaceOrientation(.portrait)


        NavigationView
        {
            Thermal_camera_view(
                    Recording_manager(
                            orientation        : .landscapeLeft,
                            device_state       : .streaming,
                            max_temperature    : 39.7,
                            min_temperature    : 28.4,
                            default_image      : image,
                            battery_percentage : 100,
                            camera_state       : .cooling
                        )
                )
                .hide_navigation_interface()
                .ignoresSafeArea()
        }
        .navigationViewStyle(.stack)
        .previewInterfaceOrientation(.landscapeRight)


        NavigationView
        {
            Thermal_camera_view(
                    Recording_manager(
                            orientation        : .landscapeRight,
                            device_state       : .streaming,
                            max_temperature    : 39.7,
                            min_temperature    : 28.4,
                            default_image      : image,
                            battery_percentage : 75
                        )
                )
                .hide_navigation_interface()
                .ignoresSafeArea()
        }
        .navigationViewStyle(.stack)
        .previewInterfaceOrientation(.landscapeLeft)


        NavigationView
        {
            Thermal_camera_view(
                    Recording_manager(
                            orientation        : .portrait,
                            device_state       : .streaming,
                            max_temperature    : 39.7,
                            min_temperature    : 28.4,
                            default_image      : image,
                            battery_percentage : 75
                        )
                )
                .hide_navigation_interface()
                .ignoresSafeArea()
        }
        .navigationViewStyle(.stack)
        .previewInterfaceOrientation(.portrait)


        NavigationView
        {
            Thermal_camera_view(
                    Recording_manager(
                            orientation  : .landscapeLeft,
                            device_state : .stopping
                        )
                )
                .hide_navigation_interface()
                .ignoresSafeArea()
        }
        .navigationViewStyle(.stack)
        .previewInterfaceOrientation(.landscapeRight)


        NavigationView
        {
            Thermal_camera_view(
                    Recording_manager(
                            orientation  : .landscapeLeft,
                            device_state : .disconnecting
                        )
                )
                .hide_navigation_interface()
                .ignoresSafeArea()
        }
        .navigationViewStyle(.stack)
        .previewInterfaceOrientation(.landscapeRight)

    }
    
}
