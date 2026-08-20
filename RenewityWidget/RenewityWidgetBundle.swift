import SwiftUI
import WidgetKit

@main
struct RenewityWidgetBundle: WidgetBundle {
    var body: some Widget {
        MonthlySpendWidget()
        UpcomingRenewalWidget()
    }
}
