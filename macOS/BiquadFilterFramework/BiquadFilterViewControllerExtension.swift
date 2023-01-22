/*
See LICENSE folder for this sample’s licensing information.

Abstract:
BiquadFilterViewController is the app extension's principal class, responsible for creating both the audio unit and its view.
*/

import CoreAudioKit

extension BiquadFilterViewController: AUAudioUnitFactory {
    public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        audioUnit = try BiquadFilterAU(componentDescription: componentDescription, options: [])
        return audioUnit!
    }
}
