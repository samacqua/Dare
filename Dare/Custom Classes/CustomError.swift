//
//  CustomError.swift
//  Dare
//
//  Created by Sam Acquaviva on 3/3/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import Foundation

public struct CustomError: Error, LocalizedError {
    let message: String
    public var errorDescription: String? {
            return NSLocalizedString(message, comment: "")
    }
}
