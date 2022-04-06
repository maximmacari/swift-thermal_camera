/**
 * \file    Temperature_panel.swift
 * \author  Mauricio Villarroel
 * \date    Created: Jan 6, 2022
 * ____________________________________________________________________________
 *
 * Copyright (C) 2022 Mauricio Villarroel. All rights reserved.
 *
 * SPDX-License-Identifer:  GPL-2.0-only
 * ____________________________________________________________________________
 */

import SwiftUI
import UIKit
import SensorRecordingUtils


struct Temperature_panel: View
{
    
    let device_id          : Device.ID_type
    var max_temperature    : Double
    var min_temperature    : Double
    var battery_percentage : Int
    var battery_state      : UIDevice.BatteryState
    var frame_rate         : Double
    var total_frames_lost  : Int
    let temperature_unit   : Temperature_unit
    
    
    var body: some View
    {
        GeometryReader
        {
            geo in
            
            ZStack(alignment: .init(horizontal: .center, vertical: .center))
            {
                Background_panel()
                
                VStack(spacing: 0)
                {
                    Sensor_label_view( label : "FLIR", is_vertical : true )
                        .frame(width: geo.size.width, height: 25)
                    
                    
                    Battery_percentage_view(
                            device_id      : "FLIR",
                            percentage     : battery_percentage,
                            show_device_id : false,
                            is_vertical    : true,
                            battery_state  : battery_state
                        )
                        .frame(height: 35)
                        .padding(.top, 5)
                    
                    Frame_rate_value_view
                        .frame(height: 30)
                        .padding(.vertical, 5)
                    
                    Lost_frames_view
                        .frame(height: 30)
                        .padding(.bottom, 5)
                    
                    Temperature_value_view(max_temperature)
                        .frame(height: 20)
                    
                    Temperature_range_view
                        .frame(maxHeight : .infinity)
                    
                    Temperature_value_view(min_temperature)
                        .frame(height: 20)
                        .padding(.bottom)
                }
                .frame(width: geo.size.width - 8)
            }
        }
    }
    
    
    // MARK: - Body Views
    
    
    private var Temperature_range_view : some View
    {
        
        ZStack(alignment: .init(horizontal: .center, vertical: .center))
        {
            Rectangle()
                .fill( LinearGradient(
                    gradient   : Gradient(colors: [.red, .yellow, .blue]),
                    startPoint : .top,
                    endPoint   : .bottom
                ))
            
            ZStack(alignment: .init(horizontal: .center, vertical: .center))
            {
                Color.white.cornerRadius(5)
                
                Text(temperature_unit.short_name)
                    .font(.system(.body))
                    .fontWeight(.bold)
            }
            .frame(width: 30, height: 20)
        }

    }
    
    
    @ViewBuilder
    private func Temperature_value_view(
            _  temperature : Double
        ) -> some View
    {
        
        ZStack(alignment: .init(horizontal: .center, vertical: .center))
        {
            Color.white.cornerRadius(5)
            
            let value = round(temperature * 10) / 10.0
            Text( String(value) + "°" ).font(.system(.footnote))
                .fontWeight(.bold)
        }
        
    }
    
    
    private var Frame_rate_value_view: some View
    {
        
        ZStack(alignment: .init(horizontal: .center, vertical: .center))
        {
            
            let fps = round(frame_rate * 10) / 10.0
            
            let background_colour : Color = (fps == 0) ? .red   : .white
            let foreground_colour : Color = (fps == 0) ? .white : .black
            
            background_colour.cornerRadius(5)
            
            VStack
            {
                Text("FPS" )
                    .font(.system(.caption))
                    .fontWeight(.bold)
                    .foregroundColor(foreground_colour)
                                
                Text( String(fps) )
                    .font(.system(.footnote))
                    .foregroundColor(foreground_colour)
            }
        }

    }
    
    
    private var Lost_frames_view: some View
    {
        
        ZStack(alignment: .init(horizontal: .center, vertical: .center))
        {
            let background_colour : Color = (total_frames_lost > 0) ? .red   : .white
            let foreground_colour : Color = (total_frames_lost > 0) ? .white : .black
            
            background_colour.cornerRadius(5)
            
            VStack
            {
                Text("Lost" )
                    .font(.system(.caption))
                    .fontWeight(.bold)
                    .foregroundColor(foreground_colour)
                                
                Text( String(total_frames_lost) )
                    .font(.system(.footnote))
                    .foregroundColor(foreground_colour)
            }
        }

    }
    
}


struct Temperature_panel_Previews: PreviewProvider
{
    
    static var previews: some View
    {
        
        Temperature_panel(
                device_id          : "FLIR",
                max_temperature    : 38.7,
                min_temperature    : 20.8,
                battery_percentage : 100,
                battery_state      : .unknown,
                frame_rate         : 6.7,
                total_frames_lost  : 0,
                temperature_unit   : .celsius
            )
        .background(.black)
            .previewLayout( .fixed(width: 50, height : 350) )

    }
    
}

