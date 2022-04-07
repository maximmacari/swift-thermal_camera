// swift-tools-version:5.5

import PackageDescription

let package = Package(
    
    name      : "swift-thermal_camera",
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
            .package(url: "https://github.com/maurovm/swift-sensor_recording_utils", .branch("master")),
            .package(path: "../swift-ios_thermal_sdk")
        ],
    targets:
        [
            .target(
                name         : "ThermalCamera",
                dependencies :
                    [
                        .product(name: "SensorRecordingUtils", package: "swift-sensor_recording_utils"),
                        .product(name: "iOSThermalSDK", package: "swift-ios_thermal_sdk")
                    ],
                path         : "Sources"
            )
        ]

)
