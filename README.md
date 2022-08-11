# ThermalCamera


Swift Package providing the functionality to record video data from thermal 
cameras such as the FLIR one Pro-series.


### Note for the FLIR One camera:

 The FLIR One camera (and its SDK) was not designed to record video. This 
 limitation is enforced by FLIR's hardware/software. The only option they 
 enabled is to take snapshots at a maximum rate of 9 frames per second (FPS).
 Therefore, this Swift package records every frame as a separate image file at
 the maximum FPS. Each image file has the image data from both the 
 red-green-blue (RGB) camera and the radiometric data from the thermal imager.

---

ThermalCamera is free software: you can redistribute it or modify it under the
terms of the GNU General Public License as published by the Free Software 
Foundation, version 2 only. Please check the file [COPYING](COPYING) for more
information on the license and copyright.

If you want to submit pull requests or contribute source code to this 
repository, please read the [CONTRIBUTING.md](CONTRIBUTING.md) for
more information about contributing guidelines.

If you use this app in your projects and publish the results, please cite the
following manuscript:

> Villarroel, M. and Davidson, S. "Open-source software mobile platform for
physiological data acquisition". arXiv (In preparation). 2022

---

ThermalRecorder is an iOS application written in Swift. It uses the 
functionality provided by the following Swift Packages:

- [swift-sensor_recording_utils](https://github.com/maurovm/swift-sensor_recording_utils):
A module containing shared utility methods and classes used by other modules
and applications to record raw data from sensors. 
- [swift-ios_thermal_sdk](https://github.com/maurovm/swift-ios_thermal_sdk): A
Swift Package wrapping the multi-plaftform XCFrameworks for FLIR Mobile SDK.
- [swift-thermal_recorder](https://github.com/maurovm/swift-thermal_recorder): 
The main application (XCode, Settings.bundle, etc) to record video from the 
thermal cameras such as the FLIR One Pro.

Examples of other applications making use of the above Swift Packages are:

- [swift-pulse_ox_recorder](https://github.com/maurovm/swift-pulse_ox_recorder):
Application to record time-series data from devices that support Bluetooth 
Low Energy (BLE) protocol, such as heart rate monitors and pulse oximeters.
- [swift-waveform_plotter_example](https://github.com/maurovm/swift-waveform_plotter_example):
Example application to plot time-series data.
