/**
 * \file    ui_color_image.swift
 * \author  Mauricio Villarroel
 * \date    Created: Mar 13, 2022
 * ____________________________________________________________________________
 *
 * Copyright (C) 2022 Mauricio Villarroel. All rights reserved.
 *
 * SPDX-License-Identifer:  GPL-2.0-only
 * ____________________________________________________________________________
 */

import SwiftUI


/**
 * Create a UIImage filled with a given colour
 */
extension UIColor
{
    
    func image(_ size: CGSize = CGSize(width: 1, height: 1)) -> UIImage
    {
        return UIGraphicsImageRenderer(size: size).image
        {
            rendererContext in
            self.setFill()
            rendererContext.fill(CGRect(origin: .zero, size: size))
        }
    }
    
}
