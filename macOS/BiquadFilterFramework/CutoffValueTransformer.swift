//
//  CutoffValueTransformer.swift
//  BiquadFilter
//
//  Created by Eric Kampman on 4/29/23.
//  Copyright © 2023 Apple. All rights reserved.
//

/*
	The math is taken from MainViewController, written by Apple.
	Refer to LICENSE.txt for details.
 */

import Foundation

class CutoffValueTransformer : ValueTransformer {
	typealias RawValueType = Float
	
	let defaultMinHertz: Float = 12.0
	let defaultMaxHertz: Float = 20_000.0

	func rawToUI(_ val: Float) -> Float {
		// Normalize the vaue from 0-1.
		var normalizedValue = (val - defaultMinHertz) / (defaultMaxHertz - defaultMinHertz)

		// Map to 2^0 - 2^9 (slider range).
		normalizedValue = (normalizedValue * 511.0) + 1
		return Float(log2(normalizedValue))
	}
	
	func uiToRaw(_ val: Float) -> Float {
		var value = pow(2, val)
		value = (value - 1.0) / 511.0
		value *= (defaultMaxHertz - defaultMinHertz)
		return value + defaultMinHertz
	}
	
}
