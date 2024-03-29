/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The non-UI controller object used to manage the interaction with the BiquadFilter audio unit.
*/

import Foundation
import AudioToolbox
import CoreAudioKit
import AVFoundation

// A simple wrapper type to prevent exposing the Core Audio AUAudioUnitPreset in the UI layer.
public struct Preset {
    fileprivate init(preset: AUAudioUnitPreset) {
        audioUnitPreset = preset
    }
    fileprivate let audioUnitPreset: AUAudioUnitPreset
    public var number: Int { return audioUnitPreset.number }
    public var name: String { return audioUnitPreset.name }
}

// The protocol you adopt to observe parameter value changes.
public protocol AUManagerDelegate: AnyObject {
    func cutoffValueDidChange(_ value: Float)
    func resonanceValueDidChange(_ value: Float)
	func filterTypeValueDidChange(_ value: Float)
}

// The controller object for managing the interaction with the audio unit and its user interface.
public class AudioUnitManager {

    /// The user-selected audio unit.
    private var audioUnit: BiquadFilterAU?

	/*
		ELK this delegate is for updating UI OUTSIDE the AU UI.
	 */
    public weak var delegate: AUManagerDelegate? {
        didSet {
            updateCutoff()
            updateResonance()
        }
    }

    public private(set) var viewController: BiquadFilterViewController!

    public var cutoffValue: Float = 0.0 {
        didSet {
            cutoffParameter.value = cutoffValue
        }
    }

    public var resonanceValue: Float = 0.0 {
        didSet {
            resonanceParameter.value = resonanceValue
        }
    }

	// set by popup, but AUParameters are always floats!
	public var filterTypeValue: Float = 0.0 {
		didSet {
			filterTypeParameter.value = filterTypeValue
		}
	}

    // Gets the audio unit's defined presets.
    public var presets: [Preset] {
        guard let audioUnitPresets = audioUnit?.factoryPresets else {
            return []
        }
        return audioUnitPresets.map { preset -> Preset in
            return Preset(preset: preset)
        }
    }

    // Retrieves or sets the audio unit's current preset.
    public var currentPreset: Preset? {
        get {
            guard let preset = audioUnit?.currentPreset else { return nil }
            return Preset(preset: preset)
        }
        set {
            audioUnit?.currentPreset = newValue?.audioUnitPreset
        }
    }

    /// The playback engine for playing audio.
    private let playEngine = SimplePlayEngine()

    // The audio unit's filter cutoff frequency parameter object.
    private var cutoffParameter: AUParameter!

    // The audio unit's filter resonance parameter object.
    private var resonanceParameter: AUParameter!

	// The audio unit's filter type parameter object.
	private var filterTypeParameter: AUParameter!

    // A token for registering to observe parameter value changes.
    private var parameterObserverToken: AUParameterObserverToken!

    // The AudioComponentDescription that matches the BiquadFilterExtension Info.plist.
    private var componentDescription: AudioComponentDescription = {

        // Ensure that AudioUnit type, subtype, and manufacturer match the extension's Info.plist values.
        var componentDescription = AudioComponentDescription()
        componentDescription.componentType = kAudioUnitType_Effect
        componentDescription.componentSubType = "bqFl".osType()! // 0x666c7472 /*'fltr'*/
        componentDescription.componentManufacturer = 0x44656d6f /*'Demo'*/
        componentDescription.componentFlags = 0
        componentDescription.componentFlagsMask = 0

        return componentDescription
    }()

    private let componentName = "Demo: BiquadFilter"

    public init() {

        viewController = loadViewController()

        /*
         Register the `AUAudioUnit` subclass, and `BiquadFilter`, so it can instantiate using its component description.

         This registration is local to this process.
         */
        AUAudioUnit.registerSubclass(BiquadFilterAU.self,
                                     as: componentDescription,
                                     name: componentName,
                                     version: UInt32.max)

        AVAudioUnit.instantiate(with: componentDescription) { audioUnit, error in
            guard error == nil, let audioUnit = audioUnit else {
                fatalError("Could not instantiate audio unit: \(String(describing: error))")
            }
            self.audioUnit = audioUnit.auAudioUnit as? BiquadFilterAU
            self.connectParametersToControls()
            self.playEngine.connect(avAudioUnit: audioUnit)
        }
    }

    // Loads the audio unit's view controller from the extension bundle.
    private func loadViewController() -> BiquadFilterViewController {
        // Locate the app extension's bundle in the main app's PlugIns directory.
        guard let url = Bundle.main.builtInPlugInsURL?.appendingPathComponent("BiquadFilterExtension.appex"),
            let appexBundle = Bundle(url: url) else {
                fatalError("Could not find app extension bundle URL.")
        }

        #if os(iOS)
        let storyboard = Storyboard(name: "MainInterface", bundle: appexBundle)
        guard let controller = storyboard.instantiateInitialViewController() as? BiquadFilterViewController else {
            fatalError("Unable to instantiate BiquadFilterViewController")
        }
        return controller
        #elseif os(macOS)
        return BiquadFilterViewController(nibName: "BiquadFilterViewController", bundle: appexBundle)
        #endif
    }

    /**
     Call this after instantiating the audio unit, to find the AU's parameters and
     connect them to the controls.
     */
    private func connectParametersToControls() {

        guard let audioUnit = audioUnit else {
            fatalError("Couldn't locate BiquadFilter")
        }

        viewController.audioUnit = audioUnit

        // Find the parameters by their identifiers.
        guard let parameterTree = audioUnit.parameterTree else {
            fatalError("BiquadFilter does not define any parameters.")
        }

        cutoffParameter = parameterTree.value(forKey: "cutoff") as? AUParameter
		resonanceParameter = parameterTree.value(forKey: "resonance") as? AUParameter
		filterTypeParameter = parameterTree.value(forKey: "filterType") as? AUParameter

        parameterObserverToken = parameterTree.token(byAddingParameterObserver: { [weak self] address, _ in
            guard let self = self else { return }
            /*
             The system calls this when one of the parameter values changes.
             You can only update the UI from the main queue.
             */

            DispatchQueue.main.async {
				// update the instantiating App's UI
				switch address {
				case self.cutoffParameter.address:
					self.updateCutoff()
				case self.resonanceParameter.address:
					self.updateResonance()
				case self.filterTypeParameter.address:
					self.updateFilterType()
				default:
					break
				}
				// Update the AU's ViewController
				self.viewController.updateControls(self)
            }
        })
    }

    // Callbacks to update controls from parameters.
    func updateCutoff() {
        guard let param = cutoffParameter else { return }
        delegate?.cutoffValueDidChange(param.value)
    }

    func updateResonance() {
        guard let param = resonanceParameter else { return }
        delegate?.resonanceValueDidChange(param.value)
    }
	func updateFilterType() {
		guard let param = filterTypeParameter else { return }
		delegate?.filterTypeValueDidChange(param.value)
	}

    @discardableResult
    public func togglePlayback() -> Bool {
        return playEngine.togglePlay()
    }

    public func toggleView() {
        viewController.toggleViewConfiguration()
    }

    public func cleanup() {
        playEngine.stopPlaying()

        guard let parameterTree = audioUnit?.parameterTree else { return }
        parameterTree.removeParameterObserver(parameterObserverToken)
    }
}
