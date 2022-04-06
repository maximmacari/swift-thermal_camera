/**
 * \file    thermal_error.swift
 * \author  Mauricio Villarroel
 * \date    Created: Mar 8, 2022
 * ____________________________________________________________________________
 *
 * Copyright (C) 2022 Mauricio Villarroel. All rights reserved.
 *
 * SPDX-License-Identifer:  GPL-2.0-only
 * ____________________________________________________________________________
 */

import Foundation


enum Thermal_error: Error, Equatable
{
    
    case incorrect_camera_discovered(description: String)
    
    case camera_discovery_error(code: Int , description: String)
    
    case failed_to_subscribe_to_thermal_stream
    
}
