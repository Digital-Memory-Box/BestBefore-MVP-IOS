import EventKit
import Foundation

final class CalendarService {
  static let shared = CalendarService()
  private let eventStore = EKEventStore()

  private init() {}

  /// Requests access to the calendar and returns a boolean indicating if it was granted.
  func requestAccess() async -> Bool {
    if #available(iOS 17.0, *) {
      do {
        return try await eventStore.requestFullAccessToEvents()
      } catch {
        print("Failed to request calendar access (iOS 17+):", error)
        return false
      }
    } else {
      return await withCheckedContinuation { continuation in
        eventStore.requestAccess(to: .event) { granted, _ in
          continuation.resume(returning: granted)
        }
      }
    }
  }

  /// Scans for birthdays and holiday events occurring today.
  func fetchTodayCelebrations() async -> [EKEvent] {
    guard await requestAccess() else { return [] }

    let now = Date()
    let startOfDay = Calendar.current.startOfDay(for: now)
    let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

    let calendars = eventStore.calendars(for: .event)
    print("Found \(calendars.count) calendars in EKEventStore.")
    for cal in calendars {
      print(" - Calendar: \(cal.title), Type: \(cal.type.rawValue), Source: \(cal.source.title)")
    }

    // This predicate creates issues parsing. We must ensure calendars are valid.
    if calendars.isEmpty { return [] }
    let predicate = eventStore.predicateForEvents(
      withStart: startOfDay, end: endOfDay, calendars: calendars)
    let allEvents = eventStore.events(matching: predicate)
    print("Found \(allEvents.count) total events for today.")

    // Filter for birthdays and holidays
    return allEvents.filter { event in
      let title = (event.title ?? "").lowercased()
      let calendarTitle = event.calendar.title.lowercased()

      // Check if it's a birthday calendar or has celebration keywords
      let isBirthday =
        event.calendar.type == .birthday || title.contains("birthday")
        || calendarTitle.contains("birthday")

      // Check for holiday keywords in event title OR calendar title (e.g., "Holidays in US")
      let isHoliday =
        title.contains("holiday") || title.contains("celebration")
        || calendarTitle.contains("holiday")

      if isBirthday || isHoliday {
        print("Suggested event: \(event.title ?? "Untitled") from \(event.calendar.title)")
        return true
      }
      return false
    }
  }
}
