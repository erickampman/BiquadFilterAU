//
//  BiquadCoefficientsPOD.h
//  BiquadFilter
//
//  Created by Eric Kampman on 3/25/23.
//  Copyright © 2023 Apple. All rights reserved.
//

#ifndef BiquadCoefficientsPOD_h
#define BiquadCoefficientsPOD_h

typedef struct BiquadCoefficientsPOD {
	float b0;
	float b1;
	float b2;
	float a1;
	float a2;
} BiquadCoefficientsPOD;

extern const BiquadCoefficientsPOD gPassthroughCoefficients;

#endif /* BiquadCoefficientsPOD_h */
