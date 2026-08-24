import SwiftData
import SwiftUI

enum MainTab: Hashable {
    case overview
    case subscriptions
    case calendar
}

private struct MainTabKey: EnvironmentKey {
    static let defaultValue: Binding<MainTab> = .constant(.overview)
}

extension EnvironmentValues {
    var mainTab: Binding<MainTab> {
        get { self[MainTabKey.self] }
        set { self[MainTabKey.self] = newValue }
    }
}

struct ContentView: View {
    @AppStorage("hasCompletedWelcome") private var hasCompletedWelcome = false
    @Query(sort: \AppCategory.sortOrder) private var categories: [AppCategory]
    @Query(sort: \AppPaymentMethod.sortOrder) private var paymentMethods: [AppPaymentMethod]
    @Environment(AppLockController.self) private var appLock
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: MainTab = .overview

    var body: some View {
        Group {
            if hasCompletedWelcome {
                TabView(selection: $selectedTab) {
                    Tab("概览", systemImage: "square.grid.2x2.fill", value: MainTab.overview) {
                        HomeView()
                    }
                    Tab("订阅", systemImage: "rectangle.stack.fill", value: MainTab.subscriptions) {
                        SubscriptionListView()
                    }
                    Tab("日历", systemImage: "calendar", value: MainTab.calendar) {
                        CalendarView()
                    }
                }
                .environment(\.appCategories, categories)
                .environment(\.appPaymentMethods, paymentMethods)
                .environment(\.mainTab, $selectedTab)
                .appSkyBackground()
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
