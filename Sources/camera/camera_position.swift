/**
 * \file    camera_position.swift
 * \author  Mauricio Villarroel
 * \date    Created: Mar 15, 2022
 * ____________________________________________________________________________
 *
 * Copyright (C) 2022 Mauricio Villarroel. All rights reserved.
 *
 * SPDX-License-Identifer:  GPL-2.0-only
 * ____________________________________________________________________________
 */

import Foundation


extension Camera
{
    
    /**
     * The camera position/location supported by the app
     */
    enum Position : String
    {
        
        case front
        
        case back
        
        
        /**
         * A readable representation of the `Position`, typically
         * to show in the UI
         */
        var description : String
        {
            switch self
            {
                case .front:
                    return "Front"
                case .back:
                    return "Back"
            }
        }
        
    }
    
}
