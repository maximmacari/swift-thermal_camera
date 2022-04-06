// swift-tools-version:5.5

import PackageDescription

let package = Package(
    
    name      : "thermal_camera",
    platforms : [ .iOS("15.2") ],
    products  :
        [
            .library(
                name    : "ThermalCamera",
                targets : ["ThermalCamera"]
            )
        ],
    dependencies:
        [
            .package(url: "https://github.com/maurovm/sensor_recording_utils", .branch("master")),
            .package(path: "../FLIRThermalSDK")
        ],
    targets:
        [
            .target(
                name         : "ThermalCamera",
                dependencies :
                    [
                        .product(name: "SensorRecordingUtils", package: "sensor_recording_utils"),
                        "FLIRThermalSDK"
                    ],
                path         : "Sources"
            )
        ]

)
