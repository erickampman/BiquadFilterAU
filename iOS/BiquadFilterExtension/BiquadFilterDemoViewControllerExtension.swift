/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The BiquadFilterViewController is the app extension's principal class, responsible for creating both the audio unit and its view.
*/

import CoreAudioKit
import BiquadFilterFramework

extension BiquadFilterViewController: AUAudioUnitFactory {

    public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        audioUnit = try BiquadFilter(componentDescription: componentDescription, options: [])
        return audioUnit!
    }
}
