/**
 * \file    thermal_fusion_mode.swift
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


public enum Thermal_fusion_mode : String
{
    case IR_mode
    
    case Visual_mode
    
    case Fusion_PIP_mode
    
    case Fusion_thermal_mode
    
    case Fusion_MSX_mode
    
    case Fusion_blending_mode
    
    
    var to_FUSION_MODE :  FUSION_MODE
    {
        switch self
        {
                
            case .IR_mode:
                return IR_MODE
                
            case .Visual_mode:
                return VISUAL_MODE
                
            case .Fusion_PIP_mode:
                return FUSION_PIP_MODE
                
            case .Fusion_thermal_mode:
                return FUSION_THERMAL_MODE
                
            case .Fusion_MSX_mode:
                return FUSION_MSX_MODE
                
            case .Fusion_blending_mode:
                return FUSION_BLENDING_MODE
        }
    }
    
}


extension FUSION_MODE
{
    
    var to_Thermal_fusion_mode  :  Thermal_fusion_mode
    {
        switch self
        {
            case IR_MODE:
                return .IR_mode
                
            case VISUAL_MODE:
                return .Visual_mode
                
            case FUSION_PIP_MODE:
                return .Fusion_PIP_mode
                
            case FUSION_THERMAL_MODE:
                return .Fusion_thermal_mode
                
            case FUSION_MSX_MODE:
                return .Fusion_MSX_mode
                
            case FUSION_BLENDING_MODE:
                return .Fusion_blending_mode
                
            default:
                return .IR_mode
                
        }
    }
    
    var description  :  String
    {
        switch self
        {
            case IR_MODE:
                return "IR_MODE"
                
            case VISUAL_MODE:
                return "VISUAL_MODE"
                
            case FUSION_PIP_MODE:
                return "FUSION_PIP_MODE"
                
            case FUSION_THERMAL_MODE:
                return "FUSION_THERMAL_MODE"
                
            case FUSION_MSX_MODE:
                return "FUSION_MSX_MODE"
                
            case FUSION_BLENDING_MODE:
                return "FUSION_BLENDING_MODE"
                
            default:
                return "UNKNOWN"
                
        }
    }
    
}
