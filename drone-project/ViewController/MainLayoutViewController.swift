//
//  DefaultLayoutViewController.swift
//  dscan
//
//  Created by zhang on 2021/03/18.
//

import UIKit
import DJIUXSDKBeta

class MainLayoutViewController : UIViewController, MCStreamer, RecordButtonDelegate {
    
    var appDelegate = UIApplication.shared.delegate as! AppDelegate
    let rootView = UIView()
    let streamingImageView = UIImageView()
    let streamingView = DUXBetaBaseWidget()
    let mainView = DUXBetaBaseWidget()
    let secondaryView = DUXBetaBaseWidget()
    var topBar: DUXBetaBarPanelWidget?
    var remainingFlightTimeWidget: DUXBetaRemainingFlightTimeWidget?
    var fpvWidget: DUXBetaFPVWidget?
    var compassWidget: DUXBetaCompassWidget?
    var telemetryPanel: DUXBetaTelemetryPanelWidget?
    var systemStatusListPanel: DUXBetaListPanelWidget?
    var fpvOptionsPanel: DUXBetaListPanelWidget?
    var currentMainViewWidget : DUXBetaBaseWidget?
    var mapWidget: DUXBetaMapWidget?
    var mapBig = false

    override var prefersStatusBarHidden: Bool { return true }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(rootView)
        
        view.backgroundColor = UIColor.uxsdk_black()
        
        rootView.translatesAutoresizingMaskIntoConstraints = false
        let statusBarInsets = UIApplication.shared.keyWindow!.safeAreaInsets
        var edgeInsets: UIEdgeInsets
        if #available(iOS 11, * ) {
            edgeInsets = view.safeAreaInsets
            edgeInsets.top += statusBarInsets.top
            edgeInsets.left += statusBarInsets.left
            edgeInsets.bottom += statusBarInsets.bottom
            edgeInsets.right += statusBarInsets.right
        } else {
            edgeInsets = UIEdgeInsets(top: statusBarInsets.top, left: statusBarInsets.left, bottom: statusBarInsets.bottom, right: statusBarInsets.right)
        }
        
        rootView.topAnchor.constraint(equalTo:view.topAnchor, constant:edgeInsets.top).isActive = true
        rootView.leftAnchor.constraint(equalTo:view.leftAnchor, constant:edgeInsets.left).isActive = true
        rootView.bottomAnchor.constraint(equalTo:view.bottomAnchor, constant:-edgeInsets.bottom).isActive = true
        rootView.rightAnchor.constraint(equalTo:view.rightAnchor, constant:-edgeInsets.right).isActive = true

        setupTopBar()
        setupMainView()
        setupTelemetryPanel()
        setupRemainingFlightTimeWidget()
        setupRTKWidget()
        setupLeftPanel()
        setupMapWidget()
        setupSecondaryView()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        DUXBetaStateChangeBroadcaster.instance().unregisterListener(self)
        
        super.viewDidDisappear(animated)
    }
    
    @IBAction func close () {
        dismiss(animated: true) {
            DJISDKManager.keyManager()?.stopAllListening(ofListeners: self)
        }
    }
    
    func toggleRecording(isRecording: Bool) {
        if isRecording {
            MCCommunicationService.shared.startRec()
        } else {
            MCCommunicationService.shared.stopRec()
        }
    }
    
    func MCStreaming(_ imageData: Data) {
        DispatchQueue.main.async {
            let image = UIImage(data: imageData)
            self.streamingImageView.image = image
        }
    }
        
    // Method for setting up the top bar. We may want to refactor this into another file at some point
    // but for now, let's use this as out basic playground file. We are designing for lower complexity
    // if possible than having multiple view containers defined in other classes and getting attached.
    func setupTopBar() {
        let topBarWidget = DUXBetaTopBarWidget()
        
        let logoBtn = UIButton()
        logoBtn.translatesAutoresizingMaskIntoConstraints = false
        logoBtn.setImage(UIImage.init(named: "Close"), for: .normal)
        logoBtn.imageView?.contentMode = .scaleAspectFit
        logoBtn.addTarget(self, action: #selector(close), for: .touchUpInside)
        view.addSubview(logoBtn)
                
        let customizationsBtn = UIButton()
        customizationsBtn.translatesAutoresizingMaskIntoConstraints = false
        customizationsBtn.setImage(UIImage.init(named: "Wrench"), for: .normal)
        customizationsBtn.imageView?.contentMode = .scaleAspectFit
        customizationsBtn.addTarget(self, action: #selector(setupFPVOptionsPanel), for: .touchUpInside)
        view.addSubview(customizationsBtn)
        
        topBarWidget.install(in: self)
        
        let margin: CGFloat = 5.0
        let height: CGFloat = 28.0
        NSLayoutConstraint.activate([
            logoBtn.leftAnchor.constraint(equalTo: rootView.leftAnchor),
            logoBtn.topAnchor.constraint(equalTo: rootView.topAnchor, constant: margin),
            logoBtn.heightAnchor.constraint(equalToConstant: height - 2 * margin),
          
            topBarWidget.view.trailingAnchor.constraint(equalTo: customizationsBtn.leadingAnchor),
            topBarWidget.view.leadingAnchor.constraint(equalTo: logoBtn.trailingAnchor),
            topBarWidget.view.topAnchor.constraint(equalTo: rootView.topAnchor),
            topBarWidget.view.heightAnchor.constraint(equalToConstant: height),
            
            customizationsBtn.topAnchor.constraint(equalTo: rootView.topAnchor, constant: margin),
            customizationsBtn.heightAnchor.constraint(equalToConstant: height - 2 * margin),
            customizationsBtn.rightAnchor.constraint(equalTo: rootView.rightAnchor)
        ])
        
        topBar = topBarWidget
        topBar!.topMargin = margin
        topBar!.rightMargin = margin
        topBar!.bottomMargin = margin
        topBar!.leftMargin = margin

        DUXBetaStateChangeBroadcaster.instance().registerListener(self, analyticsClassName: "SystemStatusUIState") { [weak self] (analyticsData) in
            DispatchQueue.main.async {
                if let weakSelf = self {
                    if let list = weakSelf.systemStatusListPanel {
                        list.closeTapped()
                        weakSelf.systemStatusListPanel = nil
                    } else {
                        weakSelf.setupSystemStatusList()
                    }
                }
            }
        }
    }
    
    func setupRemainingFlightTimeWidget() {
        let remainingFlightTimeWidget = DUXBetaRemainingFlightTimeWidget()
        
        remainingFlightTimeWidget.install(in: self)
        
        NSLayoutConstraint.activate([
            remainingFlightTimeWidget.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            remainingFlightTimeWidget.view.rightAnchor.constraint(equalTo: view.rightAnchor),
            remainingFlightTimeWidget.view.centerYAnchor.constraint(equalTo: topBar?.view.bottomAnchor ?? rootView.topAnchor, constant: 3.0)
        ])

        self.remainingFlightTimeWidget = remainingFlightTimeWidget
    }
    
    func setupLeftPanel() {
        let leftBarWidget = DUXBetaFreeformPanelWidget()
        var configuration = DUXBetaPanelWidgetConfiguration(type: .freeform, variant: .freeform)
        configuration = configuration.configureColors(background: .uxsdk_clear())
        _ = leftBarWidget.configure(configuration)
        
        leftBarWidget.install(in: self)

        NSLayoutConstraint.activate([
            leftBarWidget.view.topAnchor.constraint(equalTo: topBar?.view.bottomAnchor ?? rootView.topAnchor),
            leftBarWidget.view.bottomAnchor.constraint(equalTo: telemetryPanel?.view.topAnchor ?? rootView.bottomAnchor),
            leftBarWidget.view.leftAnchor.constraint(equalTo: (compassWidget?.view ?? rootView).leftAnchor),
            leftBarWidget.view.rightAnchor.constraint(equalTo: rootView.leftAnchor, constant: 64.0)
        ])
        
        let newPanes = leftBarWidget.splitPane(leftBarWidget.rootPane(), along: .vertical, proportions: [0.25, 0.25, 0.25, 0.25])

        DUXBetaTakeOffWidget().install(in: leftBarWidget, pane: newPanes[1], position: .centered)
        DUXBetaReturnHomeWidget().install(in: leftBarWidget, pane: newPanes[2], position: .centered)
    }
    
    func setupSecondaryView() {
        self.secondaryView.install(in: self)
        self.secondaryView.view.translatesAutoresizingMaskIntoConstraints = false
        self.setupSecondaryViewConstrants(self.secondaryView.view)
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.onSecondaryViewTapped))
        self.secondaryView.view.addGestureRecognizer(gesture)
        
        self.streamingView.view = self.streamingImageView
        self.streamingView.view.translatesAutoresizingMaskIntoConstraints = false
        MCCommunicationService.shared.streamerDelegate = self
        self.streamingView.install(in: self.secondaryView)
        self.setupFillConstraints(self.streamingView.view, parent: self.secondaryView.view)
        self.streamingImageView.image = UIGraphicsImageRenderer(size: CGSize(width: 640, height: 480)).image { renderContext in
            UIColor.white.setFill()
            renderContext.fill(CGRect(origin: .zero, size: CGSize(width: 640, height: 480)))
        }
    }
    
    @objc func onSecondaryViewTapped() {
        self.streamingView.view.removeFromSuperview()
        self.streamingView.view.removeConstraints(self.streamingView.view.constraints)
        self.streamingView.removeFromParent()
        self.fpvWidget!.view.removeFromSuperview()
        self.fpvWidget!.view.removeConstraints(self.fpvWidget!.view.constraints)
        self.fpvWidget!.removeFromParent()
        if self.currentMainViewWidget == self.fpvWidget {
            self.fpvWidget!.install(in: self.secondaryView)
            self.streamingView.install(in: self.mainView)
            self.setupMainViewConstraints(self.streamingView.view)
            self.setupSecondaryViewConstrants(self.fpvWidget!.view)
            self.currentMainViewWidget = self.streamingView
        } else if self.currentMainViewWidget == self.streamingView {
            self.fpvWidget!.install(in: self.mainView)
            self.streamingView.install(in: self.secondaryView)
            self.setupMainViewConstraints(self.fpvWidget!.view)
            self.setupSecondaryViewConstrants(self.streamingView.view)
            self.currentMainViewWidget = self.fpvWidget
        }
    }

    func setupMapWidget() {
        let map = DUXBetaMapWidget()
        map.showFlyZoneLegend = false

        map.install(in: self)

        map.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            map.view.bottomAnchor.constraint(equalTo: telemetryPanel?.view.bottomAnchor ?? rootView.bottomAnchor),
            map.view.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -20.0),
            map.view.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.4),
            map.view.heightAnchor.constraint(equalTo: telemetryPanel?.view.heightAnchor ?? map.view.widthAnchor)
        ])
        
//        let holdRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.onMapHeld))
//        map.view.addGestureRecognizer(holdRecognizer)

        self.mapWidget = map
    }
    
    @objc func onMapHeld() {
        // TODO: bug
        self.mapWidget!.view.removeConstraints(self.mapWidget!.view.constraints)
        if self.mapBig {
            NSLayoutConstraint.activate([
                self.mapWidget!.view.bottomAnchor.constraint(equalTo: self.telemetryPanel!.view.bottomAnchor),
                self.mapWidget!.view.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -20.0),
                self.mapWidget!.view.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.4),
                self.mapWidget!.view.heightAnchor.constraint(equalTo: self.telemetryPanel!.view.heightAnchor)
            ])
            self.mapBig = false
        } else {
            NSLayoutConstraint.activate([
                self.mapWidget!.view.bottomAnchor.constraint(equalTo: self.telemetryPanel!.view.bottomAnchor),
                self.mapWidget!.view.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -20.0),
                self.mapWidget!.view.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.8),
                self.mapWidget!.view.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 0.5)
            ])
            self.mapBig = true
        }
    }
    
    func setupSystemStatusList() {
        let listPanel = DUXBetaSystemStatusListWidget()
        listPanel.onCloseTapped( { [weak self] listPanel in
            guard let self = self else { return }
            if listPanel == self.systemStatusListPanel {
                self.systemStatusListPanel = nil
            }
        })
        listPanel.install(in: self) // Very important to use this method
        
        listPanel.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        listPanel.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        listPanel.view.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier:0.6).isActive = true
        listPanel.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        systemStatusListPanel = listPanel
    }
    
    func setupMainViewConstraints(_ v: UIView) {
        v.layer.zPosition = -1
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: self.topBar!.view.bottomAnchor),
            v.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            v.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            v.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
    }
    
    func setupSecondaryViewConstrants(_ v: UIView) {
        NSLayoutConstraint.activate([
            v.leftAnchor.constraint(equalTo: compassWidget?.view.leftAnchor ?? view.leftAnchor),
            v.topAnchor.constraint(equalTo: topBar?.view.bottomAnchor ?? view.topAnchor, constant: 10.0),
            v.widthAnchor.constraint(equalToConstant: 320),
            v.heightAnchor.constraint(equalToConstant: 240)
        ])
    }
    
    func setupFillConstraints(_ v: UIView, parent: UIView) {
        NSLayoutConstraint.activate([
            v.leftAnchor.constraint(equalTo: parent.leftAnchor),
            v.rightAnchor.constraint(equalTo: parent.rightAnchor),
            v.topAnchor.constraint(equalTo: parent.topAnchor),
            v.bottomAnchor.constraint(equalTo: parent.bottomAnchor)
        ])
    }
    
    func setupMainView() {
        self.mainView.install(in: self)
        self.mainView.view.translatesAutoresizingMaskIntoConstraints = false
        setupMainViewConstraints(self.mainView.view)
        
        let fpvWidget = DUXBetaFPVWidget()
        fpvWidget.install(in: self.mainView)

        self.fpvWidget = fpvWidget
        self.currentMainViewWidget = self.fpvWidget
        self.setupFillConstraints(self.fpvWidget!.view, parent: self.mainView.view)

    }
    
    func setupRTKWidget() {
        let rtkWidget = DUXBetaRTKWidget()
        rtkWidget.view.translatesAutoresizingMaskIntoConstraints = false
        rtkWidget.install(in: self)
        
        if let topBar = topBar {
            rtkWidget.view.topAnchor.constraint(equalTo: topBar.view.bottomAnchor).isActive = true
        } else {
            rtkWidget.view.topAnchor.constraint(equalTo: view.topAnchor, constant: 44.0).isActive = true
        }
        if let telemetryPanel = telemetryPanel {
            if UIDevice.current.userInterfaceIdiom == .phone {
                rtkWidget.view.bottomAnchor.constraint(equalTo: telemetryPanel.view.bottomAnchor).isActive = true
            } else {
                rtkWidget.view.bottomAnchor.constraint(equalTo: telemetryPanel.view.topAnchor).isActive = true
            }
        } else {
            rtkWidget.view.bottomAnchor.constraint(equalTo: view.topAnchor).isActive = true
        }
        rtkWidget.view.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }
    
    func setupTelemetryPanel() {
        let compassWidget = DUXBetaCompassWidget()
        let telemetryPanel = DUXBetaTelemetryPanelWidget()
        var configuration = DUXBetaPanelWidgetConfiguration(type: .freeform, variant: .freeform)
        configuration = configuration.configureColors(background: .uxsdk_clear())
        _ = telemetryPanel.configure(configuration)
        
        let leftMarginLayoutGuide = UILayoutGuide.init()
        view.addLayoutGuide(leftMarginLayoutGuide)
        
        let bottomMarginLayoutGuide = UILayoutGuide.init()
        view.addLayoutGuide(bottomMarginLayoutGuide)
        
        compassWidget.install(in: self)
        telemetryPanel.install(in: self)
        
        let backgroundView = telemetryPanel.backgroundViewForPane(0)
        backgroundView?.backgroundColor = .uxsdk_blackAlpha50()
        backgroundView?.layer.cornerRadius = 5.0
        
        NSLayoutConstraint.activate([
            leftMarginLayoutGuide.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.015),
            leftMarginLayoutGuide.leftAnchor.constraint(equalTo: view.leftAnchor),
            leftMarginLayoutGuide.rightAnchor.constraint(equalTo: compassWidget.view.leftAnchor),
            
            bottomMarginLayoutGuide.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.04),
            bottomMarginLayoutGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomMarginLayoutGuide.topAnchor.constraint(equalTo: compassWidget.view.bottomAnchor),
            
            compassWidget.view.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.116),
            compassWidget.view.widthAnchor.constraint(equalTo: compassWidget.view.heightAnchor, multiplier: compassWidget.widgetSizeHint.preferredAspectRatio),
            
            telemetryPanel.view.leftAnchor.constraint(equalTo: compassWidget.view.rightAnchor),
            telemetryPanel.view.centerYAnchor.constraint(equalTo: compassWidget.view.centerYAnchor),
            telemetryPanel.view.heightAnchor.constraint(equalTo: compassWidget.view.heightAnchor, multiplier: 1.2),
            telemetryPanel.view.widthAnchor.constraint(equalTo: telemetryPanel.view.heightAnchor,
                                                     multiplier: telemetryPanel.widgetSizeHint.preferredAspectRatio)
        ])
        
        self.compassWidget = compassWidget
        self.telemetryPanel = telemetryPanel
    }
    
    @objc func setupFPVOptionsPanel() {
        if let _ = fpvOptionsPanel {
            fpvOptionsPanel?.closeTapped()
        }
        
        let listPanel = DUXBetaListPanelWidget()
        _ = listPanel.configure(DUXBetaPanelWidgetConfiguration(type: .list, listKind: .widgets)
            .configureTitlebar(visible: true, withCloseBox: true, title: "FPV Options"))

        listPanel.onCloseTapped({ [weak self] inPanel in
            guard let self = self else { return }
            self.fpvOptionsPanel = nil;
        })
        listPanel.install(in: self)
        
        NSLayoutConstraint.activate([
            listPanel.view.heightAnchor.constraint(greaterThanOrEqualToConstant: listPanel.widgetSizeHint.minimumHeight),
            listPanel.view.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.7),
            listPanel.view.widthAnchor.constraint(greaterThanOrEqualToConstant: listPanel.widgetSizeHint.minimumWidth),
            listPanel.view.topAnchor.constraint(equalTo: topBar?.view.bottomAnchor ?? view.topAnchor),
            listPanel.view.rightAnchor.constraint(equalTo: rootView.rightAnchor)
        ])

        let cameraNameVisibility = FPVCameraNameVisibilityWidget()
        cameraNameVisibility.setTitle("Camera Name Visibility", andIconName: nil)
        cameraNameVisibility.fpvWidget = fpvWidget
        
        let cameraSideVisibility = FPVCameraSideVisibilityWidget()
        cameraSideVisibility.setTitle("Camera Side Visibility", andIconName: nil)
        cameraSideVisibility.fpvWidget = fpvWidget
        
        let gridlinesVisibility = FPVGridlineVisibilityWidget()
        gridlinesVisibility.setTitle("Gridlines Visibility", andIconName: nil)
        gridlinesVisibility.fpvWidget = fpvWidget
        
        let gridlinesType = FPVGridlineTypeWidget()
        gridlinesType.setTitle("Gridlines Type", andIconName: nil)
        gridlinesType.fpvWidget = fpvWidget
        
        let centerImageVisibility = FPVCenterViewVisibilityWidget()
        centerImageVisibility.setTitle("CenterPoint Visibility", andIconName: nil)
        centerImageVisibility.fpvWidget = fpvWidget
        
        let centerImageType = FPVCenterViewTypeWidget()
        centerImageType.setTitle("CenterPoint Type", andIconName: nil)
        centerImageType.fpvWidget = fpvWidget
        
        let centerImageColor = FPVCenterViewColorWidget()
        centerImageColor.setTitle("CenterPoint Color", andIconName: nil)
        centerImageColor.fpvWidget = fpvWidget
        
        let hardwareDecodeWidget = DUXBetaListItemSwitchWidget()
        hardwareDecodeWidget.setTitle("Enable Hardware Decode", andIconName: nil)
        hardwareDecodeWidget.onOffSwitch.isOn = fpvWidget?.enableHardwareDecode ?? false
        hardwareDecodeWidget.setSwitchAction { [weak self] (enabled) in
            self?.fpvWidget?.enableHardwareDecode = enabled
        }
        
        let streamingWidget = DUXBetaListItemSwitchWidget()
        streamingWidget.setTitle("MC Streaming", andIconName: nil)
        streamingWidget.onOffSwitch.isOn = MCCommunicationService.shared.streaming
        streamingWidget.setSwitchAction { (enabled) in
            MCCommunicationService.shared.toggleStreaming(assign: enabled)
        }
        
        let recordingWidget = DUXBetaListItemSwitchWidget()
        recordingWidget.setTitle("MC Recording", andIconName: nil)
        recordingWidget.onOffSwitch.isOn = MCCommunicationService.shared.recording
        recordingWidget.setSwitchAction { (enabled) in
            if enabled {
                MCCommunicationService.shared.startRec()
            } else {
                MCCommunicationService.shared.stopRec()
            }
        }
        
        let fpvFeedCustomization = FPVVideoFeedWidget().setTitle("Video Feed", andIconName: nil)
        fpvFeedCustomization.fpvWidget = fpvWidget
        
        let MCFeed = MCCameraFeedWidget().setTitle("MC Camera Feed", andIconName: nil)
        fpvFeedCustomization.fpvWidget = fpvWidget
        
        listPanel.addWidgetArray([
            streamingWidget,
            recordingWidget,
            MCFeed,
            hardwareDecodeWidget,
            fpvFeedCustomization,
            cameraNameVisibility,
            cameraSideVisibility,
            gridlinesVisibility,
            gridlinesType,
            centerImageVisibility,
            centerImageType,
            centerImageColor,
        ])
        fpvOptionsPanel = listPanel
    }
}
