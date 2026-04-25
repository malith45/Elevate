//
//  ElevateWidgetLiveActivity.swift
//  ElevateWidget
//
//  Created by COBSCCOMP-034 on 2026-04-25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct ElevateWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct ElevateWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ElevateWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension ElevateWidgetAttributes {
    fileprivate static var preview: ElevateWidgetAttributes {
        ElevateWidgetAttributes(name: "World")
    }
}

extension ElevateWidgetAttributes.ContentState {
    fileprivate static var smiley: ElevateWidgetAttributes.ContentState {
        ElevateWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: ElevateWidgetAttributes.ContentState {
         ElevateWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: ElevateWidgetAttributes.preview) {
   ElevateWidgetLiveActivity()
} contentStates: {
    ElevateWidgetAttributes.ContentState.smiley
    ElevateWidgetAttributes.ContentState.starEyes
}
