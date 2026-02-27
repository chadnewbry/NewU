import Foundation
import SwiftData

@Model
final class DailyNote {
    @Attribute(.unique) var id: UUID
    var date: Date
    var content: String

    init(
        id: UUID = UUID(),
        date: Date = .now,
        content: String = ""
    ) {
        self.id = id
        self.date = date
        self.content = content
    }
}
