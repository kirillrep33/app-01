import SwiftUI

struct AppRootView: View {
    @StateObject private var store: FishStockStore
    @State private var selectedTab: Tab = .fish

    enum Tab {
        case fish
        case sales
        case statistics
    }

    init(store: FishStockStore) {
        _store = StateObject(wrappedValue: store)
    }

    var body: some View {
        Group {
            switch selectedTab {
            case .fish:
            NavigationStack {
                FishListView(viewModel: FishListViewModel(store: store))
            }
            case .sales:
            NavigationStack {
                SalesListView(viewModel: SalesListViewModel(store: store))
            }
            case .statistics:
            NavigationStack {
                StatisticsView(viewModel: StatisticsViewModel(store: store))
            }
            }
        }
        .safeAreaInset(edge: .bottom) {
            CustomTabBar(selectedTab: $selectedTab)
                .background(Color.clear)
        }
        .environmentObject(store)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: AppRootView.Tab

    var body: some View {
        GeometryReader { geometry in
            let availableWidth = max(0, geometry.size.width - 56)
            let buttonWidth = min(max((availableWidth - 32) / 3, 58), 92)
            let spacing = min(max((availableWidth - buttonWidth * 3) / 2, 12), 40)

            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(red: 7/255, green: 21/255, blue: 58/255))
                    .shadow(color: .black.opacity(0.87), radius: 4, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.black.opacity(0.95),
                                        Color.black.opacity(0.0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .padding(.top, 2)
                            .blendMode(.overlay)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    )
                    .overlay {
                        if UIImage(named: "Group 9") != nil {
                            Image("Group 9")
                                .resizable()
                                .scaledToFill()
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                    }

                HStack(spacing: spacing) {
                    tabButton(
                        title: "Fish",
                        isSelected: selectedTab == .fish,
                        imageName: selectedTab == .fish ? "Fish-2" : "Fish",
                        width: buttonWidth
                    ) {
                        selectedTab = .fish
                    }

                    tabButton(
                        title: "Sales",
                        isSelected: selectedTab == .sales,
                        imageName: selectedTab == .sales ? "Coins-2" : "Coins",
                        width: buttonWidth
                    ) {
                        selectedTab = .sales
                    }

                    tabButton(
                        title: "Statistics",
                        isSelected: selectedTab == .statistics,
                        imageName: selectedTab == .statistics ? "Statistics-2" : "Statistics",
                        width: buttonWidth
                    ) {
                        selectedTab = .statistics
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 12)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 92)
        .padding(.horizontal, 8)
    }

    private func tabButton(title: String, isSelected: Bool, imageName: String, width: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: withButtonSound(action)) {
            VStack(spacing: 4) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 24)

                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isSelected ? AppColors.tabSelected : .white)
            }
            .frame(maxWidth: .infinity, minHeight: 56, maxHeight: 56)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 36, style: .continuous)
                            .fill(Color.clear)
                    } else {
                        Color.clear
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .frame(width: width, height: 56)
    }
}

#if DEBUG
#Preview("App Launch (Root)") {
    let mockStore = FishStockStore(
        persistence: PersistenceManager(),
        notificationManager: NotificationManager()
    )
    return AppRootView(store: mockStore)
}
#endif


