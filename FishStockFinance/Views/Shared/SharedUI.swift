import SwiftUI

enum AppColors {
    static let accent = Color("AccentColor")
    static let neon = Color(red: 0.82, green: 0.94, blue: 0.18)
    static let card = Color.white.opacity(0.92)
    static let tabSelected = Color(red: 224/255, green: 255/255, blue: 65/255)
}

enum AppLayout {
    static func maxContentWidth(for width: CGFloat) -> CGFloat {
        min(width, 760)
    }
}

enum Formatters {
    static let date: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()

    static func currency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let raw = formatter.string(from: value as NSNumber) ?? "0"
        return "£\(raw)"
    }

    static func number(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = value == floor(value) ? 0 : 2
        return formatter.string(from: value as NSNumber) ?? "0"
    }
}

struct AppBackground<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if UIImage(named: "bg") != nil {
                    Image("bg")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                } else {
                    LinearGradient(
                        colors: [
                            Color(red: 0.22, green: 0.82, blue: 0.90),
                            Color(red: 0.01, green: 0.25, blue: 0.60)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                }

                content
                    .frame(maxWidth: AppLayout.maxContentWidth(for: geometry.size.width), alignment: .top)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
    }
}

func withButtonSound(_ action: @escaping () -> Void) -> () -> Void {
    return {
        SoundManager.shared.playButtonSound()
        action()
    }
}

extension View {
    func singleLineScaled(_ minScale: CGFloat = 0.6) -> some View {
        self
            .lineLimit(1)
            .minimumScaleFactor(minScale)
            .allowsTightening(true)
    }

    @ViewBuilder
    func verticalBounceBasedOnSizeIfAvailable() -> some View {
        self
    }
}

struct ScreenTitleView: View {
    let title: String
    var showBack: Bool = false
    var showNotifications: Bool = true
    var notificationHighlighted: Bool = false
    var onBack: (() -> Void)? = nil

    var body: some View {
        ZStack {
            HStack {
                if showBack {
                    Button(action: withButtonSound { onBack?() }) {
                        if UIImage(named: "exit") != nil {
                            Image("exit")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                        } else {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundStyle(.white)
                        }
                    }
                } else {
                    Color.clear
                        .frame(width: 24, height: 24)
                }

                Spacer()

                if showNotifications {
                    NotificationsEntryButton(highlighted: notificationHighlighted)
                } else {
                    Color.clear
                        .frame(width: 44, height: 44)
                }
            }
            .frame(maxWidth: .infinity)

            Text(title)
                .font(.custom("Unbounded-Regular", size: 22))
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.35), radius: 0, x: 0, y: 5)
                .singleLineScaled(0.5)
                .padding(.horizontal, 56)
        }
        .padding(.top, 12)
        .frame(height: 70)
    }
}

struct NotificationsEntryButton: View {
    var highlighted: Bool = false
    @State private var showingNotifications = false

    var body: some View {
        Button(action: withButtonSound {
            guard !highlighted else { return }
            showingNotifications = true
        }) {
            if UIImage(named: "Group 5") != nil {
                Image("Group 5")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
            } else {
                Circle()
                    .fill(Color.pink.opacity(0.7))
                    .frame(width: 40, height: 40)
                    .overlay(Image(systemName: "bell.badge").foregroundStyle(.white))
            }
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showingNotifications) {
            NavigationStack {
                NotificationsView(viewModel: NotificationsViewModel(store: AppContext.shared.store))
            }
        }
    }
}

struct GlassCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

struct PrimaryActionButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: withButtonSound(action)) {
            Text(title)
                .font(.custom("Unbounded-Regular", size: 17))
                .foregroundStyle(.white)
                .padding(.vertical, 14)
                .frame(maxWidth: 220)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.00, green: 0.08, blue: 0.30), Color(red: 0.05, green: 0.16, blue: 0.43)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            Capsule()
                                .stroke(LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing), lineWidth: 3)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

struct SaveButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: withButtonSound(action)) {
            Text("Save")
                .font(.custom("Unbounded-Regular", size: 17))
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: 220)
                .padding(.vertical, 14)
                .background(
                    Group {
                        if UIImage(named: "off") != nil {
                            Image("off")
                                .resizable()
                                .scaledToFit()
                        } else {
                            Capsule()
                                .fill(Color(red: 0.00, green: 0.08, blue: 0.30))
                        }
                    }
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct AddCircleButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: withButtonSound(action)) {
            Circle()
                .fill(AppColors.neon)
                .frame(width: 24, height: 24)
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                )
        }
        .buttonStyle(.plain)
    }
}

struct AddRecordBar: View {
    var action: () -> Void

    var body: some View {
        Button(action: withButtonSound(action)) {
            ZStack {
                Capsule()
                    .fill(Color.white)
                    .frame(height: 48)
                    .shadow(color: Color(red: 0.95, green: 0.79, blue: 0.51).opacity(0.8), radius: 16, x: 0, y: 4)

                Circle()
                    .fill(AppColors.neon)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    )
            }
        }
        .buttonStyle(.plain)
    }
}

struct CalendarPickerView: View {
    @Binding var date: Date

    @State private var visibleYear: Int
    @State private var visibleMonth: Int

    private let calendar = Calendar.current

    init(date: Binding<Date>) {
        _date = date
        let components = Calendar.current.dateComponents([.year, .month], from: date.wrappedValue)
        _visibleYear = State(initialValue: components.year ?? 2025)
        _visibleMonth = State(initialValue: components.month ?? 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            weekdayRow
            weeksGrid
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(red: 0.78, green: 0.91, blue: 0.99))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(red: 0.11, green: 0.15, blue: 0.38), lineWidth: 1)
        )
    }

    private var header: some View {
        HStack {
            Button(action: withButtonSound { moveMonth(by: -1) }) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "chevron.left")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color(red: 0.22, green: 0.16, blue: 0.16))
                    )
            }
            .buttonStyle(.plain)

            Spacer()

            HStack(spacing: 2) {
                Text(monthName)
                    .font(.custom("Unbounded-Regular", size: 24))
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.13, green: 0.01, blue: 0.01))
                    .singleLineScaled(0.6)
                    .padding(.horizontal, 12)
                    .frame(height: 44)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                Text(String(visibleYear))
                    .font(.custom("Unbounded-Regular", size: 24))
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.13, green: 0.01, blue: 0.01))
                    .singleLineScaled(0.6)
                    .padding(.horizontal, 12)
                    .frame(height: 44)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }

            Spacer()

            Button(action: withButtonSound { moveMonth(by: 1) }) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "chevron.right")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color(red: 0.22, green: 0.16, blue: 0.16))
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(height: 44)
    }

    private var monthName: String {
        calendar.monthSymbols[visibleMonth - 1]
    }

    private var weekdayRow: some View {
        let symbols = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

        return HStack {
            ForEach(symbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.custom("Unbounded-Regular", size: 17))
                    .fontWeight(.medium)
                    .foregroundColor(Color(red: 0.31, green: 0.27, blue: 0.27))
                    .singleLineScaled(0.6)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 4)
    }

    private var weeksGrid: some View {
        let days = generateDays()

        return VStack(spacing: 4) {
            ForEach(0..<6, id: \.self) { weekIndex in
                HStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { dayIndex in
                        let index = weekIndex * 7 + dayIndex
                        if index < days.count {
                            dayCell(days[index])
                        } else {
                            Spacer()
                        }
                    }
                }
                .frame(height: 44)
            }
        }
        .padding(.top, 2)
    }

    private struct DayItem: Identifiable {
        let id = UUID()
        let date: Date?
        let isCurrentMonth: Bool
    }

    private func generateDays() -> [DayItem] {
        var result: [DayItem] = []

        var components = DateComponents()
        components.year = visibleYear
        components.month = visibleMonth
        components.day = 1

        guard let firstOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else {
            return []
        }

        let weekday = calendar.component(.weekday, from: firstOfMonth)
        let leadingEmpty = (weekday + 5) % 7

        for _ in 0..<leadingEmpty {
            result.append(DayItem(date: nil, isCurrentMonth: false))
        }

        for day in range {
            var c = components
            c.day = day
            let date = calendar.date(from: c)!
            result.append(DayItem(date: date, isCurrentMonth: true))
        }

        while result.count % 7 != 0 {
            result.append(DayItem(date: nil, isCurrentMonth: false))
        }

        return result
    }

    private func dayCell(_ item: DayItem) -> some View {
        guard let date = item.date else {
            return AnyView(
                Text("")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            )
        }

        let isSelected = calendar.isDate(date, inSameDayAs: self.date)
        let isCurrentMonth = item.isCurrentMonth
        let dayText = "\(calendar.component(.day, from: date))"

        return AnyView(
            Button(action: withButtonSound {
                if isCurrentMonth {
                    self.date = date
                }
            }) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isSelected ? Color(red: 0.29, green: 0.44, blue: 0.97) : Color.white.opacity(isCurrentMonth ? 1 : 0))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
                    )
                    .overlay(
                        Text(dayText)
                            .font(.custom("Unbounded-Regular", size: 18))
                            .fontWeight(.medium)
                            .foregroundColor(
                                isSelected ? .white :
                                isCurrentMonth ? Color(red: 0.31, green: 0.27, blue: 0.27) :
                                Color(red: 0.66, green: 0.73, blue: 0.82)
                            )
                            .singleLineScaled(0.6)
                    )
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        )
    }

    private func moveMonth(by delta: Int) {
        var month = visibleMonth + delta
        var year = visibleYear

        if month < 1 {
            month = 12
            year -= 1
        } else if month > 12 {
            month = 1
            year += 1
        }

        visibleMonth = month
        visibleYear = year
    }
}

struct SwipeRevealRow<Actions: View, Content: View>: View {
    @Binding var isOpen: Bool
    @ViewBuilder var actions: () -> Actions
    @ViewBuilder var content: () -> Content

    @State private var dragOffset: CGFloat = 0

    private let revealWidth: CGFloat = 80

    var body: some View {
        ZStack(alignment: .trailing) {
            actions()
                .frame(width: revealWidth, alignment: .trailing)
                .opacity(isOpen || dragOffset < 0 ? 1 : 0)
                .allowsHitTesting(isOpen || dragOffset < 0)
                .zIndex(isOpen ? 2 : 0)

            content()
                .offset(x: currentOffset)
                .zIndex(1)
                .highPriorityGesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            let translation = value.translation.width
                            if translation < 0 || isOpen {
                                dragOffset = clamp(translation + (isOpen ? -revealWidth : 0))
                            }
                        }
                        .onEnded { value in
                            let translation = value.translation.width
                            let projected = translation + (isOpen ? -revealWidth : 0)
                            let shouldOpen = projected < -revealWidth * 0.45
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                isOpen = shouldOpen
                                dragOffset = 0
                            }
                        }
                )
        }
        .clipped()
        .onTapGesture {
            if isOpen {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                    isOpen = false
                }
            }
        }
    }

    private var currentOffset: CGFloat {
        let base = isOpen ? -revealWidth : 0
        return clamp(base + dragOffset)
    }

    private func clamp(_ value: CGFloat) -> CGFloat {
        min(0, max(-revealWidth, value))
    }
}
