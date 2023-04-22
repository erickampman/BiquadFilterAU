/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A structure that calculates the magnitude response of a set of biquadratic coefficients.
*/

import Accelerate

// The `MagnitudeResponseCalculator` is a structure that calculates the
// magnitude response of a set of biquadratic coefficients.
@objc
class MagnitudeResponseCalculator : NSObject {
    
    let sampleCount: Int
    
	@objc let ramp: [Float]	// ELK ViewController/View need this
    
    private let reals: [Float]
    private let realsSquared: [Float]
    
    private let imaginaries: [Float]
    private let imaginariesSquared: [Float]
    
    private let realsSquaredImaginariesSquaredDiff: [Float]
    private let realsImaginariesProduct: [Float]
    
    // The `MagnitudeResponseCalculator.init(sampleCount:)` initializer function
    // returns a new magnitude response calculator.
	
	@objc
    init(sampleCount: Int = 64) {
        self.sampleCount = sampleCount
        
        ramp = vDSP.ramp(in: Float() ... 1.0,
                              count: sampleCount)
        
        reals = vForce.cosPi(ramp)
        realsSquared = vDSP.multiply(reals, reals)
        
        imaginaries = vForce.sinPi(ramp)
        imaginariesSquared = vDSP.multiply(imaginaries, imaginaries)
        
        realsSquaredImaginariesSquaredDiff = vDSP.subtract(realsSquared, imaginariesSquared)
        realsImaginariesProduct = vDSP.multiply(reals, imaginaries)
    }

	@objc
	func frequencyForIndex(_ index: Int, sampleRate: Double) -> Double {
		return Double(index) * Double.pi * sampleRate / 2.0
	}

    // The following function is a vectorized version of the `magnitudeForFrequency`
    // function from https://developer.apple.com/documentation/audiotoolbox/audio_unit_v3_plug-ins/creating_custom_audio_effects.
    // The function returns the magnitude response of a biquadratic filter for
    // a set of coefficients.
	@objc
	func response(for coefficients: BiquadCoefficientsPOD) -> [Float] {
		return response(b0: coefficients.b0, b1: coefficients.b1, b2: coefficients.b2,
						a1: coefficients.a1, a2: coefficients.a2)
	}
	
	@objc
	func response(b0: Float, b1: Float, b2: Float, a1: Float, a2: Float) -> [Float]
	{
        // Calculate the zeros response.
        var numeratorReal = vDSP.add(multiplication: (realsSquaredImaginariesSquaredDiff, b0),
                                     multiplication: (reals, b1))
        numeratorReal = vDSP.add(b2, numeratorReal)
        
        let numeratorImaginary = vDSP.add(multiplication: (realsImaginariesProduct, 2 * b0),
                                          multiplication: (imaginaries, b1))
        
        let numeratorMagnitude = vDSP.hypot(numeratorReal, numeratorImaginary)
        
        // Calculate the poles response.
        var denominatorReal = vDSP.add(multiplication: (reals, a1),
                                       realsSquaredImaginariesSquaredDiff)
        denominatorReal = vDSP.add(a2, denominatorReal)
        
        let denominatorImaginary = vDSP.add(multiplication: (realsImaginariesProduct, 2),
                                            multiplication: (imaginaries, a1))
        
        let denominatorMagnitude = vDSP.hypot(denominatorReal, denominatorImaginary)
        
        // Calculate the total response.
        let response = vDSP.divide(numeratorMagnitude, denominatorMagnitude)
        
        return response
    }
}
