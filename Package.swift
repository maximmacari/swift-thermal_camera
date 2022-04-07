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
            .package(path: "../ios_thermal_sdk")
        ],
    targets:
        [
            .target(
                name         : "ThermalCamera",
                dependencies :
                    [
                        .product(name: "SensorRecordingUtils", package: "sensor_recording_utils"),
                        .product(name: "iOSThermalSDK", package: "ios_thermal_sdk")
                    ],
                path         : "Sources"
            )
        ]

)
