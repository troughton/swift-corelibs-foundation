// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


#if os(OSX) || os(iOS)
import Darwin
#elseif os(Linux) || CYGWIN
import Glibc
#endif

import CoreFoundation

public struct NSOperatingSystemVersion {
    public var majorVersion: Int
    public var minorVersion: Int
    public var patchVersion: Int
    public init() {
        self.init(majorVersion: 0, minorVersion: 0, patchVersion: 0)
    }
    
    public init(majorVersion: Int, minorVersion: Int, patchVersion: Int) {
        self.majorVersion = majorVersion
        self.minorVersion = minorVersion
        self.patchVersion = patchVersion
    }
}



open class ProcessInfo: NSObject {
    
    internal static let _processInfo = ProcessInfo()
    open class func processInfo() -> ProcessInfo {
        return _processInfo
    }
    
    internal override init() {
        
    }
    
    
    internal static var _environment: [String : String] = {
        let dict = __CFGetEnvironment()._nsObject
        var env = [String : String]()
        dict.enumerateKeysAndObjects([]) { key, value, stop in
            env[(key as! NSString)._swiftObject] = (value as! NSString)._swiftObject
        }
        return env
    }()
    
    open var environment: [String : String] {
        return ProcessInfo._environment
    }
    
    open var arguments: [String] {
        return CommandLine.arguments // seems reasonable to flip the script here...
    }
    
    open var hostName: String {
        if let name = Host.currentHost().name {
            return name
        } else {
            return "localhost"
        }
    }
    
    open var processName: String = _CFProcessNameString()._swiftObject
    
    open var processIdentifier: Int32 {
        return __CFGetPid()
    }
    
    open var globallyUniqueString: String {
        let uuid = CFUUIDCreate(kCFAllocatorSystemDefault)
        return CFUUIDCreateString(kCFAllocatorSystemDefault, uuid)._swiftObject
    }

    open var operatingSystemVersionString: String {
        return CFCopySystemVersionString()?._swiftObject ?? "Unknown"
    }
    
    open var operatingSystemVersion: NSOperatingSystemVersion {
        // The following fallback values match Darwin Foundation
        let fallbackMajor = -1
        let fallbackMinor = 0
        let fallbackPatch = 0
        
        guard let systemVersionDictionary = _CFCopySystemVersionDictionary() else {
            return NSOperatingSystemVersion(majorVersion: fallbackMajor, minorVersion: fallbackMinor, patchVersion: fallbackPatch)
        }
        
        let productVersionKey = unsafeBitCast(_kCFSystemVersionProductVersionKey, to: UnsafeRawPointer.self)
        guard let productVersion = unsafeBitCast(CFDictionaryGetValue(systemVersionDictionary, productVersionKey), to: NSString!.self) else {
            return NSOperatingSystemVersion(majorVersion: fallbackMajor, minorVersion: fallbackMinor, patchVersion: fallbackPatch)
        }
        
        let versionComponents = productVersion._swiftObject.characters.split(separator: ".").flatMap(String.init).flatMap({ Int($0) })
        let majorVersion = versionComponents.dropFirst(0).first ?? fallbackMajor
        let minorVersion = versionComponents.dropFirst(1).first ?? fallbackMinor
        let patchVersion = versionComponents.dropFirst(2).first ?? fallbackPatch
        return NSOperatingSystemVersion(majorVersion: majorVersion, minorVersion: minorVersion, patchVersion: patchVersion)
    }
    
    internal let _processorCount = __CFProcessorCount()
    open var processorCount: Int {
        return Int(_processorCount)
    }
    
    internal let _activeProcessorCount = __CFActiveProcessorCount()
    open var activeProcessorCount: Int {
        return Int(_activeProcessorCount)
    }
    
    internal let _physicalMemory = __CFMemorySize()
    open var physicalMemory: UInt64 {
        return _physicalMemory
    }
    
    open func isOperatingSystemAtLeastVersion(_ version: NSOperatingSystemVersion) -> Bool {
        let ourVersion = operatingSystemVersion
        if ourVersion.majorVersion < version.majorVersion {
            return false
        }
        if ourVersion.majorVersion > version.majorVersion {
            return true
        }
        if ourVersion.minorVersion < version.minorVersion {
            return false
        }
        if ourVersion.minorVersion > version.minorVersion {
            return true
        }
        if ourVersion.patchVersion < version.patchVersion {
            return false
        }
        if ourVersion.patchVersion > version.patchVersion {
            return true
        }
        return true
    }
    
    open var systemUptime: TimeInterval {
        return CFGetSystemUptime()
    }
}
