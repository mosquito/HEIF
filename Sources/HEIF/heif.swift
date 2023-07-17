// Copyright (c) by Alexander Borsuk, 2021
// See MIT license in LICENSE file.

import Foundation
import CoreImage
import ArgumentParser
import Glob
import Progress
import os

import Darwin

import IOKit
import IOKit.pwr_mgt

let kToolVersion = "0.9"
let defaultCompressionQuality = 0.76

let dispatcher = DispatchQueue(label: "heif.converter")
let dispatchSemaphore = DispatchSemaphore(value: 4)
let fileManager = FileManager.default


@main
struct HEIFParser: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Converts image to HEIC format, version \(kToolVersion)"
    )

    @Option(
        name: [.customShort("q"), .long],
        help: ArgumentHelp("Output image quality it ranges from 0.1 (max compression) to 1.0 (lossless)")
    )
    var quality = defaultCompressionQuality
    
    @Flag(
        help: ArgumentHelp("Use 10 bit color depth in destination")
    )
    var heif10: Bool = false
    
    @Flag(help: ArgumentHelp("Trash source file"))
    var trashSource: Bool = false

    @Argument(help: ArgumentHelp("Source files"))
    var sourceFiles: Array<String>
    
    func validate() throws {
        guard quality >= 0.1 && quality <= 1.0 else {
            throw ValidationError("Quality must be between 0.1..1.0 not \(quality)")
        }
        guard !sourceFiles.isEmpty else {
            throw ValidationError("No input files")
        }
    }
    
    func copyCreationDate(from sourcePath: String, to destinationPath: String) {
        guard let sourceAttributes = try? fileManager.attributesOfItem(atPath: sourcePath),
              let sourceCreationDate = sourceAttributes[.creationDate] as? Date
        else {
            return
        }
        
        try! fileManager.setAttributes(
            [.creationDate: sourceCreationDate],
            ofItemAtPath: destinationPath
        )
    }
        
    func convert(path: String) {
        autoreleasepool(invoking: {
            let imageUrl = URL(fileURLWithPath:path)
            let image = CIImage(contentsOf: imageUrl)
            
            if image == nil {
                print("Failed to open file: \'\(path)\'")
                return
            }
                
            let context = CIContext(options: nil)
            let heicUrl = imageUrl.deletingPathExtension().appendingPathExtension("heic")
            let options: [CIImageRepresentationOption: Any] = [
                .init(rawValue: kCGImageDestinationLossyCompressionQuality as String):quality
            ]
            
            let colorSpace = image!.colorSpace!
            
            do {
                if heif10 {
                    try context.writeHEIF10Representation(
                        of:image!,
                        to:heicUrl,
                        colorSpace: colorSpace,
                        options:options
                    )
                } else {
                    try context.writeHEIFRepresentation(
                        of:image!,
                        to:heicUrl,
                        format: .ARGB8,
                        colorSpace: colorSpace,
                        options:options
                    )
                }
                
                copyCreationDate(from: path, to: heicUrl.path)
            }
            catch {
                print("*************************************************")
                print("Failed fo write HEIF for file: '\(path)'")
                print(error);
                print("*************************************************")
                print("")
                dispatchSemaphore.signal()
                return
            }
            
            if trashSource {
                try! fileManager.trashItem(at: imageUrl, resultingItemURL: nil)
            }
            dispatchSemaphore.signal()
        })
    }
    
    func run() {
        let dispatchGroup = DispatchGroup()

        let reasonForActivity = "HEIF compression" as CFString
        var assertionID: IOPMAssertionID = 0
        var success = IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoIdleSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reasonForActivity,
            &assertionID
        )
        if success != kIOReturnSuccess {print("Failed to prevent sleep")}

        for source in sourceFiles {
            for path in Progress(Glob(pattern: source)) {
                dispatchSemaphore.wait()
                dispatcher.async(group: dispatchGroup) {convert(path: path)}
            }
        }
        dispatchGroup.wait()
        
        if success == kIOReturnSuccess {success = IOPMAssertionRelease(assertionID)}
    }
}
