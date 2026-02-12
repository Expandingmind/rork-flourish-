import SwiftData
import SwiftUI

@Model
final class MicroAction {
    var actionKey: String
    var isCompleted: Bool
    var dateSelected: Date

    init(actionKey: String, isCompleted: Bool = false, dateSelected: Date = .now) {
        self.actionKey = actionKey
        self.isCompleted = isCompleted
        self.dateSelected = dateSelected
    }
}

struct MicroActionTemplate: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    static let all: [MicroActionTemplate] = [
        MicroActionTemplate(id: "admire_message", title: "Reach out to someone you admire", subtitle: "Build your circle", icon: "envelope.open.fill", color: Theme.softPink),
        MicroActionTemplate(id: "affirmations", title: "Write three affirmations", subtitle: "Rewire your mindset", icon: "pencil.and.outline", color: Theme.softPeach),
        MicroActionTemplate(id: "meditate", title: "Meditate for 2 minutes", subtitle: "Center yourself", icon: "brain.head.profile.fill", color: Theme.softMint),
        MicroActionTemplate(id: "gratitude", title: "List 3 things you're grateful for", subtitle: "Shift your perspective", icon: "heart.text.clipboard.fill", color: Theme.blush),
        MicroActionTemplate(id: "learn", title: "Learn one new thing today", subtitle: "Stay curious", icon: "lightbulb.fill", color: Theme.softLemon),
        MicroActionTemplate(id: "move_body", title: "Move your body for 10 minutes", subtitle: "Energy creates energy", icon: "figure.walk", color: Theme.sage),
        MicroActionTemplate(id: "vision", title: "Visualise your dream life for 1 minute", subtitle: "See it to believe it", icon: "eye.fill", color: Theme.softLavender),
        MicroActionTemplate(id: "declutter", title: "Declutter one small space", subtitle: "Clear space, clear mind", icon: "sparkles", color: Theme.dustyRose),
    ]
}
