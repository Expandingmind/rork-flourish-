import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DailyView()
                .tabItem {
                    Label("Today", systemImage: "flame.fill")
                }
                .tag(0)
            
            EvidenceView()
                .tabItem {
                    Label("Evidence", systemImage: "bolt.fill")
                }
                .tag(1)
            
            BucketListView()
                .tabItem {
                    Label("Dreams", systemImage: "sparkles")
                }
                .tag(2)
            
            TravelView()
                .tabItem {
                    Label("Travel", systemImage: "pin.fill")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Label("You", systemImage: "person.crop.circle.fill")
                }
                .tag(4)
        }
        .tint(Theme.accent)
        .onAppear {
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithOpaqueBackground()
            tabBarAppearance.backgroundColor = UIColor(Color(red: 0.98, green: 0.96, blue: 0.93))
            UITabBar.appearance().standardAppearance = tabBarAppearance
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

            let navAppearance = UINavigationBarAppearance()
            navAppearance.configureWithOpaqueBackground()
            navAppearance.backgroundColor = UIColor(Color(red: 0.98, green: 0.96, blue: 0.93))
            let palatinoBold34 = UIFont(name: Theme.fontNameBold, size: 34) ?? .boldSystemFont(ofSize: 34)
            let palatinoBold17 = UIFont(name: Theme.fontNameBold, size: 17) ?? .boldSystemFont(ofSize: 17)
            navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(Theme.deep), .font: palatinoBold34]
            navAppearance.titleTextAttributes = [.foregroundColor: UIColor(Theme.deep), .font: palatinoBold17]
            UINavigationBar.appearance().standardAppearance = navAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        }
    }
}
