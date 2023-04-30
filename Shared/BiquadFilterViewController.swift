/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller for the BiquadFilter audio unit that manages the interactions between a FilterView and the audio unit's parameters.
*/

import CoreAudioKit

public class BiquadFilterViewController: AUViewController {

    let compact = AUAudioUnitViewConfiguration(width: 400, height: 100, hostHasController: false)
    let expanded = AUAudioUnitViewConfiguration(width: 800, height: 500, hostHasController: false)

    private var viewConfig: AUAudioUnitViewConfiguration!

	private let cutoffValueTransformer = CutoffValueTransformer()
	
    private var cutoffParameter: AUParameter!
	private var resonanceParameter: AUParameter!
	private var filterTypeParameter: AUParameter!
    private var parameterObserverToken: AUParameterObserverToken?

	@IBOutlet weak var filterView: FilterView!
	@IBOutlet weak var responseView: ResponseView!

//    @IBOutlet weak var frequencyTextField: TextField!
//    @IBOutlet weak var resonanceTextField: TextField!
 
	@IBOutlet weak var frequencySlider: Slider!
	@IBOutlet weak var resonanceSlider: Slider!

	@IBOutlet weak var filterTypePopup: NSPopUpButton!
	
    var observer: NSKeyValueObservation?

    var needsConnection = true

    @IBOutlet var expandedView: View! {
        didSet {
            expandedView.setBorder(color: .black, width: 1)
        }
    }

    @IBOutlet var compactView: View! {
        didSet {
            compactView.setBorder(color: .black, width: 1)
        }
    }

    // Always support width: 0 height:0, which is the default and largest view.
    public var viewConfigurations: [AUAudioUnitViewConfiguration] {
        return [expanded, compact]
    }

    /*
     When this view controller instantiates within the FilterDemoApp, the
     system creates its audio unit independently and passes it to the view
     controller here.
     */
    public var audioUnit: BiquadFilterAU? {
        didSet {
            audioUnit?.viewController = self
            /*
             The app may be on a dispatch worker queue processing an XPC request at
             this time, and quite possibly the main queue is busy creating the
             view. To be thread-safe, dispatch onto the main queue.

             It's also possible that the app is already on the main queue, so to
             protect against deadlock in that case, dispatch asynchronously.
             */
            performOnMain {
                if self.isViewLoaded {
                    self.connectViewToAU()
                }
            }
        }
    }

    #if os(macOS)
    public override init(nibName: NSNib.Name?, bundle: Bundle?) {
        // Pass a reference to the owning framework bundle.
        super.init(nibName: nibName, bundle: Bundle(for: type(of: self)))
    }
    #endif

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        preferredContentSize = CGSize(width: 800, height: 500)
        
        view.addSubview(expandedView)
        expandedView.pinToSuperviewEdges()

        // Set the default view configuration.
        viewConfig = expanded

//        // Respond to changes in the filterView (frequency and/or response changes).
//        filterView.delegate = self

        #if os(iOS)
        frequencyTextField.delegate = self
        resonanceTextField.delegate = self
        #endif

        guard audioUnit != nil else { return }

        // Connect the user interface to the audio unit parameters, if necessary.
        connectViewToAU()
    }

	private func connectViewToAU() {
		guard needsConnection, let paramTree = audioUnit?.parameterTree else { return }
		
		// Find the cutoff and resonance parameters in the parameter tree.
		guard let cutoff = paramTree.value(forKey: "cutoff") as? AUParameter,
			  let resonance = paramTree.value(forKey: "resonance") as? AUParameter,
				let filterType = paramTree.value(forKey: "filterType") as? AUParameter
		else {
			fatalError("Required AU parameters not found.")
        }

        // Set the instance variables.
        cutoffParameter = cutoff
        resonanceParameter = resonance
		filterTypeParameter = filterType

        // Observe major state changes like a user selecting a user preset.
        observer = audioUnit?.observe(\.allParameterValues) { object, change in
            DispatchQueue.main.async {
                self.updateUI()
            }
        }

        // Observe value changes to the cutoff and resonance parameters.
        parameterObserverToken =
            paramTree.token(byAddingParameterObserver: { [weak self] address, value in
                guard let self = self else { return }

                // An arbitrary queue is calling this closure. Ensure
                // all UI updates dispatch back to the main thread.
				if [cutoff.address, resonance.address, filterType.address].contains(address) {
                    DispatchQueue.main.async {
                        self.updateUI()
                    }
                }
            })

        // Indicate the view and the audio unit have a connection.
        needsConnection = false

        // Sync the UI with the parameter state.
        updateUI()
    }

    private func updateUI() {
        // Set the latest values on the graph view.
//        filterView.frequency = cutoffParameter.value
//        filterView.resonance = resonanceParameter.value
		
		
		// filterType here FIXME

        // Set the latest text field values.
//        frequencyTextField.text = cutoffParameter.string(fromValue: nil)
//        resonanceTextField.text = resonanceParameter.string(fromValue: nil)

//        updateFilterViewFrequencyAndMagnitudes()
		
		let intVal = Int(filterTypeParameter.value)
		filterTypePopup.selectItem(withTag: intVal)

		frequencySlider.floatValue = cutoffValueTransformer.rawToUI(cutoffParameter.value)
		resonanceSlider.floatValue = resonanceParameter.value

//		Update Coefficients here
		if let au = audioUnit {
			responseView.coefficients = au.coefficients()
		}
		
//		guard let item = sender.selectedItem else { return }
//		
//		audioUnitManager.filterTypeValue = Float(item.tag)

    }

    @IBAction func frequencyTextUpdated(_ sender: TextField) {
        updateFromTextField(parameter: cutoffParameter, with: sender)
    }

    @IBAction func resonanceTextUpdated(_ sender: TextField) {
        updateFromTextField(parameter: resonanceParameter, with: sender)
    }

    func updateFromTextField(parameter: AUParameter, with textField: TextField) {
        guard let value = (textField.text as NSString?)?.floatValue else { return }
        parameter.value = value
        textField.text = parameter.string(fromValue: nil)
    }
	
	/*
		frequencyValueForSliderLocation was taken from MainViewController.swift,
		written by Apple.
		see LICENSE.txt, included in this project.
	 */
	private func frequencyValueForSliderLocation(_ location: Float) -> Float {
		var value = pow(2, location)
		value = (value - 1) / 511

		value *= (defaultMaxHertz - defaultMinHertz)

		return value + defaultMinHertz
	}
	
	@IBAction func frequencySliderUpdated(_ sender: Slider) {
		cutoffParameter.value = cutoffValueTransformer.uiToRaw(sender.floatValue)
	}

	@IBAction func resonanceSliderUpdated(_ sender: Slider) {
		resonanceParameter.value = sender.floatValue
	}

	@IBAction func filterTypeUpdated(_ sender: NSPopUpButton) {
		
		guard let value = sender.selectedItem?.tag else {
			return
		}
		filterTypeParameter.value = AUValue(value)
	}
	
	func updateControls(_ auMgr: AudioUnitManager) {
		
	}

    // MARK: View Configuration Selection

    public func toggleViewConfiguration() {
        // Let the audio unit call selectViewConfiguration instead of calling
        // it directly to ensure validation of the audio unit's behavior.
        audioUnit?.select(viewConfig == expanded ? compact : expanded)
    }

    func selectViewConfiguration(_ viewConfig: AUAudioUnitViewConfiguration) {
        // If the requested configuration is already active, do nothing.
        guard self.viewConfig != viewConfig else { return }

        self.viewConfig = viewConfig

        let isDefault = viewConfig.width >= expanded.width &&
                        viewConfig.height >= expanded.height
        let fromView = isDefault ? compactView : expandedView
        let toView = isDefault ? expandedView : compactView

        performOnMain {
            #if os(iOS)
            UIView.transition(from: fromView!,
                              to: toView!,
                              duration: 0.2,
                              options: [.transitionCrossDissolve, .layoutSubviews])

            if toView == self.expandedView {
                toView?.pinToSuperviewEdges()
            }

            #elseif os(macOS)
            self.view.addSubview(toView!)
            fromView!.removeFromSuperview()
            toView!.pinToSuperviewEdges()
            #endif
        }
    }

    func performOnMain(_ operation: @escaping () -> Void) {
        if Thread.isMainThread {
            operation()
        } else {
            DispatchQueue.main.async {
                operation()
            }
        }
    }
}

#if false
extension BiquadFilterViewController: FilterViewDelegate {
    // MARK: FilterViewDelegate

    func updateFilterViewFrequencyAndMagnitudesX() {
        guard let audioUnit = audioUnit else { return }

        // Get an array of frequencies from the view.
        let frequencies = filterView.frequencyDataForDrawing()

        // Get the corresponding magnitudes from the audio unit.
        let magnitudes = audioUnit.magnitudes(forFrequencies: frequencies)
		let magnitudes2 = audioUnit.magnitudes();
		print("\(magnitudes2.count)")
        filterView.setMagnitudes(magnitudes)
    }
	func updateFilterViewFrequencyAndMagnitudes() {
		guard let audioUnit = audioUnit else { return }
		
		let ramp = audioUnit.ramp()
		
		
	}

    func filterViewTouchBegan(_ filterView: FilterView) {
        resonanceParameter.setValue(filterView.resonance,
                                    originator: parameterObserverToken,
                                    atHostTime: 0,
                                    eventType: .touch)
        
        cutoffParameter.setValue(filterView.frequency,
                                    originator: parameterObserverToken,
                                    atHostTime: 0,
                                    eventType: .touch)
    }
    
    func filterView(_ filterView: FilterView, didChangeResonance resonance: Float) {
        resonanceParameter.setValue(resonance,
                                    originator: parameterObserverToken,
                                    atHostTime: 0,
                                    eventType: .value)
        updateFilterViewFrequencyAndMagnitudes()
    }

    func filterView(_ filterView: FilterView, didChangeFrequency frequency: Float) {
        cutoffParameter.setValue(frequency,
                                 originator: parameterObserverToken,
                                 atHostTime: 0,
                                 eventType: .value)
        updateFilterViewFrequencyAndMagnitudes()
    }

    func filterView(_ filterView: FilterView, didChangeFrequency frequency: Float, andResonance resonance: Float) {
        
         resonanceParameter.setValue(resonance,
                                    originator: parameterObserverToken,
                                    atHostTime: 0,
                                    eventType: .value)
        
        cutoffParameter.setValue(frequency,
                                 originator: parameterObserverToken,
                                 atHostTime: 0,
                                 eventType: .value)
        
        updateFilterViewFrequencyAndMagnitudes()
    }

    func filterViewTouchEnded(_ filterView: FilterView) {
        resonanceParameter.setValue(filterView.resonance,
                                    originator: nil,
                                    atHostTime: 0,
                                    eventType: .release)
        
        cutoffParameter.setValue(filterView.frequency,
                                    originator: nil,
                                    atHostTime: 0,
                                    eventType: .release)
    }
    
    func filterViewDataDidChange(_ filterView: FilterView) {
        updateFilterViewFrequencyAndMagnitudes()
    }
}

#if os(iOS)
extension BiquadFilterViewController: UITextFieldDelegate {
    // MARK: UITextFieldDelegate
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }
}
#endif

#endif
