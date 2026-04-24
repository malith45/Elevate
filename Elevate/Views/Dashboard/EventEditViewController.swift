import SwiftUI
import EventKit
import EventKitUI

struct EventEditViewController: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    var eventStore: EKEventStore
    var onComplete: () -> Void
    
    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let controller = EKEventEditViewController()
        controller.eventStore = eventStore
        controller.editViewDelegate = context.coordinator
        
        // Let the controller handle its own default event creation if possible
        // or set a minimal event if required
        let newEvent = EKEvent(eventStore: eventStore)
        newEvent.startDate = Date()
        newEvent.endDate = Date().addingTimeInterval(3600)
        controller.event = newEvent
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: EKEventEditViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, EKEventEditViewDelegate {
        let parent: EventEditViewController
        
        init(_ parent: EventEditViewController) {
            self.parent = parent
        }
        
        func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
            parent.presentationMode.wrappedValue.dismiss()
            parent.onComplete()
        }
    }
}
