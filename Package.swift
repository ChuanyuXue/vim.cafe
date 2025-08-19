// swift-tools-version: 5.9
/*
Author: <Chuanyu> (skewcy@gmail.com)
Package.swift (c) 2025
Desc: description
Created:  2025-08-17T20:10:43.797Z
*/

import PackageDescription

let package = Package(
    name: "vim.cafe",
    platforms: [
        .macOS(.v10_15)
    ],
    targets: [
        .target(
            name: "VimCafe",
            path: "Sources",
            resources: [
                .copy("Interface/Golf/vimgolf.vimrc")
            ]
        ),
        .testTarget(
            name: "VimCafeTests",
            dependencies: ["VimCafe"],
            path: "Tests"
        )
    ]
)
