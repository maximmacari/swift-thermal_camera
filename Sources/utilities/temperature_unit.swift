/**
 * \file    temperature_unit.swift
 * \author  Mauricio Villarroel
 * \date    Created: Mar 10, 2022
 * ____________________________________________________________________________
 *
 * Copyright (C) 2022 Mauricio Villarroel. All rights reserved.
 *
 * SPDX-License-Identifer:  GPL-2.0-only
 * ____________________________________________________________________________
 */

import Foundation
import ThermalSDK


enum Temperature_unit
{
    case celsius
    
    case fahrenheit
    
    case kelvin
    
    
    var short_name : String
    {
        switch self
        {
            case .celsius:
                return "°C"
                
            case .fahrenheit:
                return "°F"
                
            case .kelvin:
                return "°K"
        }
    }
    
    var long_name : String
    {
        switch self
        {
            case .celsius:
                return "Celsius"
                
            case .fahrenheit:
                return "Fahrenheit"
                
            case .kelvin:
                return "Kelvin"
        }
    }
    
    
    static func from_number( flir_value : TemperatureUnit ) -> Temperature_unit?
    {
        let unit : Temperature_unit?
        
        switch flir_value
        {
            case .CELSIUS:
                unit = .celsius
                
            case .FAHRENHEIT:
                unit = .fahrenheit
                
            case .KELVIN:
                unit = .kelvin
                
            @unknown default:
                unit = nil
        }
        
        return unit
    }
    
}
