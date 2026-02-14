//
//  DailyQuoteWidgetBundle.swift
//  DailyQuoteWidget
//
//  Created by Muhammad Awais on 16/10/2025.
//

import WidgetKit
import SwiftUI

@main
struct DailyQuoteWidgetBundle: WidgetBundle {
    var body: some Widget {
        DailyQuoteWidget()
        DailyQuoteWidgetControl()
        DailyQuoteWidgetLiveActivity()
    }
}
