//
//  BiquadCoefficientCalculator.hpp
//  BiquadCPP
//
//  Created by Eric Kampman on 1/22/23.
//

#ifndef BiquadCoefficientCalculator_h
#define BiquadCoefficientCalculator_h

#include <cmath>

#import "BiquadFilterData.h"

struct BiquadInputs {
	float 					frequency;
	float					q;
	PARAM_ITEM_FILTER_TYPE 	filterType;
//	float					dbGain;
	// -50 <= dbGain <= 50
	// .10 <= q      <= 25
	// meh fit with y = 18.1 * ln(x) - 8.33
};

struct BiquadCoefficients {
	float	b0, b1, b2, a1, a2;
};

class BiquadCoefficientCalculator {
public:
	const BiquadCoefficients passthroughCoefficients {
		1, 0, 0, 0, 0,
	};
	
	BiquadCoefficientCalculator() {
	}

	BiquadCoefficients &calculate(BiquadCoefficients &coefficients,
								  BiquadInputs &inputs,
								  double sampleRate)
	{
		return calculate(coefficients,
						  inputs.frequency, inputs.q,
						  inputs.filterType,
						  sampleRate);
	}
		

	BiquadCoefficients &calculate(BiquadCoefficients &coefficients,
								  float frequency, float resonance,
								  PARAM_ITEM_FILTER_TYPE filterType,
								  double sampleRate)
	{

		float omega = 2.0 * M_PI * frequency / float(sampleRate);
		float sinOmega = sin(omega);
		float alpha = sinOmega / (2 * resonance);
		float cosOmega = cos(omega);
		
		float b0;
		float b1;
		float b2;
		float a0;
		float a1;
		float a2;

		switch (filterType) {
		case PARAM_ITEM_FILTER_TYPE_PASSTHROUGH:
			b0 = passthroughCoefficients.b0;
			b1 = passthroughCoefficients.b1;
			b2 = passthroughCoefficients.b2;
			a0 = 1;
			a1 = passthroughCoefficients.a1;
			a2 = passthroughCoefficients.a2;
			break;
		case PARAM_ITEM_FILTER_TYPE_LOWPASS:
			b0 = (1.0 - cosOmega) / 2.0;
			b1 = 1.0 - cosOmega;
			b2 = (1.0 - cosOmega) / 2.0;
			a0 = 1 + alpha;
			a1 = -2.0 * cosOmega;
			a2 = 1.0 - alpha;
			break;
		case PARAM_ITEM_FILTER_TYPE_HIGHPASS:
			b0 = (1.0 + cosOmega) / 2.0;
			b1 = -(1.0 + cosOmega);
			b2 = (1.0 + cosOmega) / 2.0;
			a0 = 1.0 + alpha;
			a1 = -2.0 * cosOmega;
			a2 = 1 - alpha;
			break;
		case PARAM_ITEM_FILTER_TYPE_BANDPASS:
			b0 = alpha;
			b1 = 0.0;
			b2 = -alpha;
			a0 = 1.0 + alpha;
			a1 = -2.0 * cosOmega;
			a2 = 1.0 - alpha;
			break;
		case PARAM_ITEM_FILTER_TYPE_NOTCH:
			b0 = 1.0;
			b1 = -2.0 * cosOmega;
			b2 = 1.0;
			a0 = 1.0 + alpha;
			a1 = -2.0 * cosOmega;
			a2 = 1.0 - alpha;
			break;
		case PARAM_ITEM_FILTER_TYPE_PEAKINGEQ:
			{
				float dbGain = 18.1 * log(resonance) - 8.33;
				float A = pow(10.0, dbGain / 40.0);
				b0 = 1.0 + alpha * A;
				b1 = -2.0 * cosOmega;
				b2 = 1.0 - alpha * A;
				a0 = 1.0 + alpha / A;
				a1 = -2.0 * cosOmega;
				a2 = 1.0 - alpha / A;
			}
			break;
		}
		
		coefficients.b0 = b0 / a0;
		coefficients.b1 = b1 / a0;
		coefficients.b2 = b2 / a0;
		coefficients.a1 = a1 / a0;
		coefficients.a2 = a2 / a0;
		
		return coefficients;
	}
protected:
	
};
#endif /* BiquadCoefficientCalculator_h */
