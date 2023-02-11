# Biquad Filter AU

This project combines Apple's Filter AudioUnit example with Apple's Biquad Calculater example.

The files that are Apple's are clearly marked. Likewise for my additions.

## TODO
- Only the MacOS side has been tested. iOS is probably broken.
- The frequency graph is broken.
- I've kind of lost sight of db vs raw Q values.
- Add an AUParam toggle to switch between using vDSP_ and manual IIR calculation (currently it's manual only)
- Experimenation is needed to determine what to do with parameter ramping (and batch vDSP calls).
- Test in GB / Logic / etc

# WARNING
Making mistakes can be very hard on your ears and speakers. Keep the volume low and be ready to mute if problems occur.
