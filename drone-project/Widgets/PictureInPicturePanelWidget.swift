//
//  PictureInPicturePanelWidget.swift
//  dscan
//
//  Created by zhang on 2021/03/18.
//

import Foundation
import UIKit
import DJIUXSDKBeta

/**
 * The PictureInPicturePanelWidget is a subclass of DUXBetaFreeformPanelWidget which implements a picture in picture panel. (Technically this is a widget
 * in widget panel.) Widgets in the PIP pane can be tapped and swapped with the widget passed in. Usage is fairly simple but has a few complexities
 * that can appear confusing.
 *
 * After setting up the PIP pane, install a tap notification handler to see when a pane has been tapped. The handler has the format:
 * (PaneID) -> void. When it is called, the top visible PaneID which was tapped is passed to the handler.
 *
 * After receiving the PaneID, if swap is desired, call the method swapWidget(PaneID, fromController, widget). This method specifies the
 * Pane to swap out, the controller which owns the widget being moved in to the Pane where the removed pane will reside, and the actual widget to exchange.
 *
 * The widget being put into fromController will be placed back in the view hierarchy at the same location as the widget being replaced. Once placed,
 * autolayout MUST be applied to handle positioning. That is beyond the scope the PIP widget since it knows nothing about proper widget positioning.
 */
@objcMembers open class PictureInPicturePanelWidget : DUXBetaFreeformPanelWidget {
    open var pipWidth: CGFloat = 200 {
        didSet {
            // Update minSize
        }
    }
    
    var pipHeight: CGFloat = 200 {
        didSet {
            // Update minSize
        }
    }
    
    var didTapCallback: ((PaneID) ->Void)?

    public override init() {
        super.init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(tapHandler))
        self.view.addGestureRecognizer(tap)
    }
    
    /**
     * Call installSwapTapNotificationHandler to install the handler to be called when a tap occurs in the PIP widget panes. Inside the
     * callback, do the actual swap call and constraint updates.
     *
     * - Parameters:
     *      - callback: a callback closure of type (PaneID) -> Void
     */
    open func installSwapTapNotificationHandler(_ callback: @escaping (PaneID) -> Void ) {
        didTapCallback = callback
    }

    /**
     * Call swapWidget to actually swap the widget (not view) in the pane, with the widget in the passed in view controller.
     * Put the swapped in widget into the PIP pane. If the pane does not contain a widget, this method returns nil and changes
     * nothing.
     *
     * - Parameters:
     *      - pane: Unnamed param. The PaneID to swap out.
     *      - fromController: The controller which owns the widget outside the PIP panel which is being exchanged.
     *      - widget: The widget being swapped into the PIP panel.
     *
     * - Returns: The widget being returned from the PIP panel which has been added to the fromController. Use this to
     *  set constraints. nil if pane did not contain a widget.
     */
    open func swapWidget(_ pane: PaneID, fromController: UIViewController, widget: DUXBetaBaseWidget?) -> DUXBetaBaseWidget? {
        guard let currentPaneWidget = widgetInPane(pane) else { return nil }
        guard let mainWidget = widget else { return nil }
        
        let viewIndex = fromController.view.subviews.firstIndex(of: mainWidget.view) ?? 0
        // All prepped and ready to do the swap. Remove the exterior widget:
        mainWidget.view.removeFromSuperview()
        mainWidget.removeFromParent()
        if let outWidget = internalSwapWidget(inPane: pane, to: mainWidget) {
            currentPaneWidget.install(in:fromController)
            fromController.view.insertSubview(currentPaneWidget.view, at:viewIndex)
            return outWidget
        }

        return nil
    }
    
    // MARK: - Internal
    /**
     * The actual gesture recognizer callback which determines the tap paneID and initiates the notification to the PIP owner.
     */
    @IBAction private func tapHandler(_ sender: UIGestureRecognizer) {
        guard let _ = sender.view else { return }
        let tapPoint = sender.location(in: sender.view)
        if let tapView = sender.view?.hitTest(tapPoint, with: nil) {
            let thePaneID = paneID(forView: tapView)
            if let callback = didTapCallback {
                callback(thePaneID)
            }
        }
    }
    
    /**
     * Internal method internalSwapWidget does the actual swap work of getting the current pane widget and positioning and then
     * doing the swap and positioning the swapped widget at the same positioning.
     */
    private func internalSwapWidget(inPane: PaneID, to: DUXBetaBaseWidget) -> DUXBetaBaseWidget? {
        let removeWidget = widgetInPane(inPane)
        let currentPositioning = panePositioning(inPane)
        removeWidgetFromPane(inPane)
        addWidget(to, toPane: inPane, position: currentPositioning)
        return removeWidget
    }
    

}
