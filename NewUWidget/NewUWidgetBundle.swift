import WidgetKit
import SwiftUI

@main
struct NewUWidgetBundle: WidgetBundle {
    var body: some Widget {
        SmallInjectionWidget()
        MediumDashboardWidget()
    }
}
