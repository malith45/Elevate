import WidgetKit
import SwiftUI

import CoreData

struct WidgetJob: Identifiable {
    let id: String
    let title: String
    let location: String
    let scheduledAt: Date
    let status: String
    
    var isOverdue: Bool {
        let s = status.uppercased()
        return s != "COMPLETED" && s != "CANCELLED" && s != "IN-PROGRESS" && scheduledAt < Date()
    }
}

class WidgetCoreData {
    static let shared = WidgetCoreData()
    let container: NSPersistentContainer

    private init() {
        container = NSPersistentContainer(name: "ElevateModel")
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.elevate.app") {
            let storeURL = groupURL.appendingPathComponent("ElevateModel.sqlite")
            let description = NSPersistentStoreDescription(url: storeURL)
            container.persistentStoreDescriptions = [description]
        }
        container.loadPersistentStores { _, _ in }
    }
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
}

struct SmartNavigationEntry: TimelineEntry {
    let date: Date
    let job: WidgetJob?
}

struct SmartNavigationProvider: TimelineProvider {
    func placeholder(in context: Context) -> SmartNavigationEntry {
        SmartNavigationEntry(date: Date(), job: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (SmartNavigationEntry) -> ()) {
        let entry = SmartNavigationEntry(date: Date(), job: fetchNextJob())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SmartNavigationEntry>) -> ()) {
        let entry = SmartNavigationEntry(date: Date(), job: fetchNextJob())
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
    
    private func fetchNextJob() -> WidgetJob? {
        let defaults = UserDefaults(suiteName: "group.com.elevate.app")
        guard let userId = defaults?.string(forKey: "currentUserId"),
              let orgId = defaults?.string(forKey: "currentOrgId") else {
            return nil
        }
        
        let context = WidgetCoreData.shared.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "JobEntity")
        request.predicate = NSPredicate(format: "organizationId == %@ AND assignedUserId == %@", orgId, userId)
        
        guard let entities = try? context.fetch(request) else { return nil }
        
        var jobs: [WidgetJob] = []
        for entity in entities {
            if let id = entity.value(forKey: "id") as? String,
               let title = entity.value(forKey: "title") as? String,
               let location = entity.value(forKey: "location") as? String,
               let scheduledAt = entity.value(forKey: "scheduledAt") as? Date,
               let status = entity.value(forKey: "status") as? String {
                
                let job = WidgetJob(id: id, title: title, location: location, scheduledAt: scheduledAt, status: status)
                jobs.append(job)
            }
        }
        
        return jobs.filter {
            let s = $0.status.uppercased()
            return s != "COMPLETED" && s != "CANCELLED"
        }.sorted { $0.scheduledAt < $1.scheduledAt }.first
    }
}

struct SmartNavigationWidgetView: View {
    var entry: SmartNavigationProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        Group {
            if let job = entry.job {
                JobWidgetView(job: job)
            } else {
                EmptyWidgetView()
            }
        }
        .containerBackground(for: .widget) {
            Color.white
        }
    }
}

struct JobWidgetView: View {
    let job: WidgetJob
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color(red: 0.05, green: 0.25, blue: 0.22).opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "map.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(red: 0.05, green: 0.25, blue: 0.22))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(job.isOverdue ? "OVERDUE JOB" : "NEXT JOB")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundColor(job.isOverdue ? .red : .gray)
                
                Text(job.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                    .lineLimit(2)
                
                Text(job.location)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(red: 0.05, green: 0.25, blue: 0.22))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Navigate Button (Visual only in Widget, clicking widget deep links)
            Image(systemName: "arrow.turn.up.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Color(red: 0.05, green: 0.25, blue: 0.22))
                .cornerRadius(10)
        }
        .widgetURL(URL(string: "elevate://job/\(job.id)"))
    }
}

struct EmptyWidgetView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("ALL DONE")
                .font(.system(size: 10, weight: .heavy))
                .foregroundColor(.gray)
            
            Text("Work day complete")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black)
            
            Text("You've finished all your tasks for today.")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SmartNavigationWidget: Widget {
    let kind: String = "SmartNavigationWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SmartNavigationProvider()) { entry in
            SmartNavigationWidgetView(entry: entry)
        }
        .configurationDisplayName("Next Job")
        .description("Quickly access your next assigned job.")
        .supportedFamilies([.systemMedium])
    }
}
