/**
 * \file    flir_shutter_state.swift
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


extension FLIRShutterState
{
    
    public var description : String
    {
        switch self
        {
            case .invalid:
                return "Invalid"
                
            case .off:
                return "Off"
                
            case .on:
                return "On"
                
            case .nuc:
                return "NUC"
                
            case .bad:
                return "Corrupted/invalid"
                
            case .unknown_state:
                return "Unknown"
                
            @unknown default:
                return "Unknown"
        }
    }
    
}
