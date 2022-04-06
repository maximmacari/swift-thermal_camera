/**
 * \file    warning_view.swift
 * \author  Mauricio Villarroel
 * \date    Created: Mar 20, 2022
 * ____________________________________________________________________________
 *
 * Copyright (C) 2022 Mauricio Villarroel. All rights reserved.
 *
 * SPDX-License-Identifer:  GPL-2.0-only
 * ____________________________________________________________________________
 */

import SwiftUI
import SensorRecordingUtils


struct Warning_view: View
{
    
    let message : String
    
    
    var body: some View
    {
        
        GeometryReader
        {
            geo in
            
            HStack
            {
            
                Spacer()
            
                VStack
                {
                    ZStack
                    {
                        Color.white
                            .cornerRadius(15.0)
                            .shadow(
                                color : .gray,
                                radius: 5.0,
                                x:      0,
                                y:      10
                            )
                        
                        Text(message)
                    }
                    .frame(
                        width    : geo.size.width * max_width_factor,
                        height   : panel_height,
                        alignment: .center
                    )
                    .padding(.top, 60)

                    Spacer()

                }
                
                Spacer()
                
            }
        }

    }
    
    
    // MARK: - Private state
    
    private let panel_height     : CGFloat = 50;
    private let max_width_factor : CGFloat = 0.7;
    
}

struct Warning_view_Previews: PreviewProvider
{
    static var previews: some View
    {
        Warning_view(message: "Camera is cooling ...")
            .background(.black)
    }
}
