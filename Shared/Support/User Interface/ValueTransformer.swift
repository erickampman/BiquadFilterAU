//
//  ValueTransformer.swift
//  BiquadFilter
//
//  Created by Eric Kampman on 4/29/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import Foundation

protocol ValueTransformer {
	associatedtype RawValueType
	func rawToUI(_ val: RawValueType) -> Float
	func uiToRaw(_ val: Float) -> RawValueType
}
