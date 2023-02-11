/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The object that manages the filter's cutoff and resonance parameters.
*/

import Foundation

public let CompactFilterTypes: [String] = [
	"PassThrough",
	"LowPass",
	"HighPass",
	"BandPass",
	"Notch",
	"PeakingEQ",
]

/// Manages the BiquadFilter object's cutoff and resonance parameters.
class BiquadFilterAUParameters {

    private enum BiquadFilterParam: AUParameterAddress {
        case cutoff, resonance, filterType
    }

    /// The parameter to control the cutoff frequency (12 Hz - 20 kHz).
    var cutoffParam: AUParameter = {
        let parameter =
            AUParameterTree.createParameter(withIdentifier: "cutoff",
                                            name: "Cutoff",
                                            address: BiquadFilterParam.cutoff.rawValue,
                                            min: 12.0,
                                            max: 20_000.0,
                                            unit: .hertz,
                                            unitName: nil,
                                            flags: [.flag_IsReadable,
                                                    .flag_IsWritable,
                                                    .flag_CanRamp],
                                            valueStrings: nil,
                                            dependentParameters: nil)
        // Set default value
        parameter.value = 0.0

        return parameter
    }()

    /// The parameter to control the cutoff frequency's resonance (+/-20 dB).
    var resonanceParam: AUParameter = {
        let parameter =
            AUParameterTree.createParameter(withIdentifier: "resonance",
                                            name: "Resonance",
                                            address: BiquadFilterParam.resonance.rawValue,
											min: 0.1,
                                            max: 25,
                                            unit: .decibels,
                                            unitName: nil,
                                            flags: [.flag_IsReadable,
                                                    .flag_IsWritable,
                                                    .flag_CanRamp],
                                            valueStrings: nil,
                                            dependentParameters: nil)
        // Set the default value.
        parameter.value = 20_000.0

        return parameter
    }()
		
	var filterTypeParam: AUParameter = {
		let parameter =
	  AUParameterTree.createParameter(withIdentifier: "filterType",
									  name: "FilterType",
									  address: BiquadFilterParam.filterType.rawValue,
									  min: 0,
									  max: 5,
									  unit: AudioUnitParameterUnit.indexed,
									  unitName: nil,
									  flags: [.flag_IsReadable,
											  .flag_IsWritable],
									  valueStrings: CompactFilterTypes,
									  dependentParameters: nil)
  // Set the default value.
		parameter.value = Float(PARAM_ITEM_FILTER_TYPE.LOWPASS.rawValue)

  return parameter
}()

    let parameterTree: AUParameterTree

    init(kernelAdapter: FilterDSPKernelAdapter) {

        // Create the audio unit's tree of parameters.
        parameterTree = AUParameterTree.createTree(withChildren: [cutoffParam,
                                                                  resonanceParam,
																  filterTypeParam])

        // A closure for observing all externally generated parameter value changes.
        parameterTree.implementorValueObserver = { param, value in
            kernelAdapter.setParameter(param, value: value)
        }

        // A closure for returning state of the requested parameter.
        parameterTree.implementorValueProvider = { param in
            return kernelAdapter.value(for: param)
        }

        // A closure for returning the string representation of the requested parameter value.
        parameterTree.implementorStringFromValueCallback = { param, value in
            switch param.address {
            case BiquadFilterParam.cutoff.rawValue:
                return String(format: "%.f", value ?? param.value)
            case BiquadFilterParam.resonance.rawValue:
                return String(format: "%.2f", value ?? param.value)
            default:
                return "?"
            }
        }
    }
    
    func setParameterValues(cutoff: AUValue, resonance: AUValue) {
        cutoffParam.value = cutoff
        resonanceParam.value = resonance
    }
}
