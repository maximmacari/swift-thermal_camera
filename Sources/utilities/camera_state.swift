/**
 * \file    camera_state.swift
 * \author  Mauricio Villarroel
 * \date    Created: Mar 20, 2022
 * ____________________________________________________________________________
 *
 * Copyright (C) 2022 Mauricio Villarroel. All rights reserved.
 *
 * SPDX-License-Identifer:  GPL-2.0-only
 * ____________________________________________________________________________
 */

import Foundation
import ThermalSDK


public enum Camera_state
{
    
    case not_ready
    
    case cooling
    
    case ready
    
    case unknown
    
    
    init( from  flir_state : FLIRCameraState )
    {
        switch flir_state
        {
            case .NOT_READY:
                self = .not_ready
                
            case .COOLING:
                self = .cooling
                
            case .READY:
                self = .ready
                
            default:
                self = .unknown
                
        }
        
    }
    
    
    public var description : String
    {
        switch self
        {
            case .not_ready:
                return "NOT ready"
                
            case .cooling:
                return "Cooling"
                
            case .ready:
                return "Ready"
                
            case .unknown:
                return "Unknown"
        }
    }
    
}
