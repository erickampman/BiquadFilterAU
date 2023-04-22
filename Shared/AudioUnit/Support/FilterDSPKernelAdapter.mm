/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The adapter object that provides a Swift-accessible interface to the filter's underlying DSP code.
*/

#import <AVFoundation/AVFoundation.h>
#import <CoreAudioKit/AUViewController.h>
#import "FilterDSPKernel.hpp"
#import "BufferedAudioBus.hpp"
#import "FilterDSPKernelAdapter.h"
#import <BiquadFilterFramework/BiquadFilterFramework-Swift.h>

#define MAGNITUDE_POINT_COUNT	256

@implementation FilterDSPKernelAdapter {
    // C++ members need to be ivars; they would be copied on access if they were properties.
    FilterDSPKernel  _kernel;
    BufferedInputBus _inputBus;
	BiquadCoefficientCalculator *_bqcCalculator;
	MagnitudeResponseCalculator *mrc;
}

- (instancetype)init {

    if (self = [super init]) {
        AVAudioFormat *format = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100 channels:2];
        // Create a DSP kernel to handle the signal processing.
        _kernel.init(format.channelCount, format.sampleRate);
        _kernel.setParameter(FilterParamCutoff, 0);
        _kernel.setParameter(FilterParamResonance, 0);
		_kernel.setParameter(FilterParamType, 0);

        // Create the input and output busses.
        _inputBus.init(format, 8);
        _outputBus = [[AUAudioUnitBus alloc] initWithFormat:format error:nil];
		
		_bqcCalculator = new BiquadCoefficientCalculator();
    }
    return self;
}

- (void)dealloc {
	delete _bqcCalculator;
}

- (AUAudioUnitBus *)inputBus {
    return _inputBus.bus;
}

- (NSArray<NSNumber *> *)magnitudesForFrequencies:(NSArray<NSNumber *> *)frequencies {
	BiquadCoefficientsPOD coefficients;
	BiquadInputs inputs;
	inputs.frequency = _kernel.cutoff;
	inputs.q = _kernel.resonance;
	inputs.filterType = PARAM_ITEM_FILTER_TYPE(_kernel.getParameter(FilterParamType));

	_kernel.calculateCoefficients(_kernel.cutoff,
								  _kernel.resonance,
								  PARAM_ITEM_FILTER_TYPE(_kernel.getParameter(FilterParamType))
	);
	
	double inverseNyquist = 2.0 / self.outputBus.format.sampleRate;
#if 0

    coefficients.calculateLopassParams(_kernel.cutoffRamper.getUIValue(), _kernel.resonanceRamper.getUIValue());
#endif
	
    NSMutableArray<NSNumber *> *magnitudes = [NSMutableArray arrayWithCapacity:frequencies.count];

	mrc = [[MagnitudeResponseCalculator alloc] initWithSampleCount:MAGNITUDE_POINT_COUNT];

    for (NSNumber *number in frequencies) {
        double frequency = [number doubleValue];
        double magnitude = _kernel.magnitudeForFrequency(frequency * inverseNyquist);

        [magnitudes addObject:@(magnitude)];
    }

    return [NSArray arrayWithArray:magnitudes];
}

#if 0
- (NSArray<NSNumber *> *)magnitudes {
	BiquadCoefficients &coeffs = _kernel.calculateCoefficients();
	
	NSArray<NSNumber *>* mags = [mrc responseWithB0:coeffs.b0 b1:coeffs.b1 b2:coeffs.b2 a1:coeffs.a1 a2:coeffs.a1];
	
	return mags;
}
#endif

/* 64 floats from 0 to 1 */
- (NSArray<NSNumber *> *)ramp {
	return mrc.ramp;
}

- (NSArray<NSNumber *> *)magnitudes {
	BiquadCoefficientsPOD cpod = [self kernelCoefficients];
	BiquadCoefficientsPOD &coeffs = _kernel.calculateCoefficients();
	// b0, b1, b2, a1, a2;
	cpod.a1 = coeffs.a1;
	cpod.a2 = coeffs.a2;
	cpod.b0 = coeffs.b0;
	cpod.b1 = coeffs.b1;
	cpod.b2 = coeffs.b2;
	
	return [mrc responseFor:cpod];
}

- (struct BiquadCoefficientsPOD)kernelCoefficients {
	BiquadCoefficientsPOD cpod;
	BiquadCoefficientsPOD &coeffs = _kernel.calculateCoefficients();
	// b0, b1, b2, a1, a2;
	cpod.a1 = coeffs.a1;
	cpod.a2 = coeffs.a2;
	cpod.b0 = coeffs.b0;
	cpod.b1 = coeffs.b1;
	cpod.b2 = coeffs.b2;

	return cpod;
}

- (void)setParameter:(AUParameter *)parameter value:(AUValue)value {
    _kernel.setParameter(parameter.address, value);
}

- (AUValue)valueForParameter:(AUParameter *)parameter {
    return _kernel.getParameter(parameter.address);
}

- (AUAudioFrameCount)maximumFramesToRender {
    return _kernel.maximumFramesToRender();
}

- (void)setMaximumFramesToRender:(AUAudioFrameCount)maximumFramesToRender {
    _kernel.setMaximumFramesToRender(maximumFramesToRender);
}

- (BOOL)shouldBypassEffect {
    return _kernel.isBypassed();
}

- (void)setShouldBypassEffect:(BOOL)bypass {
    _kernel.setBypass(bypass);
}

- (void)allocateRenderResources {
    _inputBus.allocateRenderResources(self.maximumFramesToRender);
    _kernel.init(self.outputBus.format.channelCount, self.outputBus.format.sampleRate);
    _kernel.reset();
}

- (void)deallocateRenderResources {
    _inputBus.deallocateRenderResources();
}

#pragma mark - AUAudioUnit (AUAudioUnitImplementation)

// Subclasses must provide an AUInternalRenderBlock (via a getter) to implement rendering.
- (AUInternalRenderBlock)internalRenderBlock {
    /*
     Capture in locals to avoid ObjC member lookups. Don't capture "self" in render.
     */
    // Specify that captured objects are mutable.
    __block FilterDSPKernel *state = &_kernel;
    __block BufferedInputBus *input = &_inputBus;

    return ^AUAudioUnitStatus(AudioUnitRenderActionFlags *actionFlags,
                              const AudioTimeStamp       *timestamp,
                              AVAudioFrameCount           frameCount,
                              NSInteger                   outputBusNumber,
                              AudioBufferList            *outputData,
                              const AURenderEvent        *realtimeEventListHead,
                              AURenderPullInputBlock      pullInputBlock) {

        AudioUnitRenderActionFlags pullFlags = 0;

        if (frameCount > state->maximumFramesToRender()) {
            return kAudioUnitErr_TooManyFramesToProcess;
        }

        AUAudioUnitStatus err = input->pullInput(&pullFlags, timestamp, frameCount, 0, pullInputBlock);

        if (err != 0) { return err; }

        AudioBufferList *inAudioBufferList = input->mutableAudioBufferList;

        /*
         Important:
         If the caller passes non-null output pointers (outputData->mBuffers[x].mData),
         use those.

         If the caller passed null output buffer pointers, process them in memory the
         audio unit owns and modify the (outputData->mBuffers[x].mData) pointers to
         point to this owned memory. The audio unit is responsible for preserving the
         validity of this memory until the next call to render, or you call
         deallocateRenderResources.

         If your algorithm can't process in-place, you need to preallocate an
         output buffer and use it here.

         See the description of the canProcessInPlace property.
         */

        // If you receive null output buffer pointers, process them in-place in the
        // input buffer.
        AudioBufferList *outAudioBufferList = outputData;
        if (outAudioBufferList->mBuffers[0].mData == nullptr) {
            for (UInt32 i = 0; i < outAudioBufferList->mNumberBuffers; ++i) {
                outAudioBufferList->mBuffers[i].mData = inAudioBufferList->mBuffers[i].mData;
            }
        }

        state->setBuffers(inAudioBufferList, outAudioBufferList);
        state->processWithEvents(timestamp, frameCount, realtimeEventListHead, nil /* MIDIOutEventBlock */);

        return noErr;
    };
}

@end
