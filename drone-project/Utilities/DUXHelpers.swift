//
//  DUXHelpers.swift
//  dscan
//
//  Created by zhang on 2021/03/18.
//


import UIKit

extension UIControl {
    func duxbeta_connect(controlAction:ControlAction, for event:UIControl.Event) {
        self.addTarget(controlAction,
                       action: #selector(ControlAction.performAction(_:)),
                       for: event)
    }
    
    func duxbeta_connect(controlAction:ControlAction, for events:[UIControl.Event]) {
        for event in events {
            self.addTarget(controlAction,
                           action: #selector(ControlAction.performAction(_:)),
                           for: event)
        }
    }
    
    func duxbeta_connect(action: @escaping DUXBetaControlActionClosure, for event:UIControl.Event) -> ControlAction {
        let controlAction = ControlAction(action)
        
        self.duxbeta_connect(controlAction: controlAction,
                     for: event)
        
        return controlAction
    }
    
    func duxbeta_connect(action: @escaping DUXBetaControlActionClosure, for events:[UIControl.Event]) -> ControlAction {
        let controlAction = ControlAction(action)
        
        self.duxbeta_connect(controlAction: controlAction,
                     for: events)
        
        return controlAction
    }
}

typealias DUXBetaControlActionClosure = () -> Void

public final class ControlAction {
    let action: DUXBetaControlActionClosure
    init(_ action: @escaping DUXBetaControlActionClosure) {
        self.action = action
    }
    
    @objc func performAction(_ sender:Any) {
        action()
    }
}
