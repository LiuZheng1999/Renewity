import SwiftData
import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedWelcome") private var hasCompletedWelcome = false
    @Query(sort: \AppCategory.sortOrder) private var categories: [AppCategory]
    @Query(sort: \AppPaymentMethod.sortOrder) private var paymentMethods: [AppPaymentMethod]
    @Environment(AppLockController.self) private var appLock
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if hasCompletedWelcome {
                TabView {
                    Tab("概览", systemImage: "square.grid.2x2.fill") {
                        HomeView()
                    }
                    Tab("订阅", systemImage: "rectangle.stack.fill") {
                        SubscriptionListView()
                    }
                    Tab("日历", systemImage: "calendar") {
                        CalendarView()
                    }
                }
                .environment(\.appCategories, categories)
                .environment(\.appPaymentMethods, paymentMethods)
            } else {
                WelcomeView()
            }
        }
        .overlay {
            if appLock.isLocked {
                AppLockView()
                    .ignoresSafeArea()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                appLock.lockIfNeeded()
            }
        }
    }
}

#Preview("主界面") {
    ContentView()
        .modelContainer(PreviewContainer.sample)
        .environment(ProStore())
        .environment(AppLockController())
        .environment(ExchangeRateStore())
}

#Preview("欢迎页") {
    WelcomeView()
}
