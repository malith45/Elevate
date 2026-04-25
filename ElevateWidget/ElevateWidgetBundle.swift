//
//  ElevateWidgetBundle.swift
//  ElevateWidget
//
//  Created by COBSCCOMP-034 on 2026-04-25.
//

import WidgetKit
import SwiftUI

@main
struct ElevateWidgetBundle: WidgetBundle {
    var body: some Widget {
        ElevateWidget()
        ElevateWidgetControl()
        ElevateWidgetLiveActivity()
        SmartNavigationWidget() // Added our new widget
    }
}
