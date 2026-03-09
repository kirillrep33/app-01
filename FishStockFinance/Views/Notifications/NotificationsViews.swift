import SwiftUI

struct NotificationsView: View {
    @ObservedObject var viewModel: NotificationsViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var showingForm = false
    @State private var editingReminder: ReminderRecord?
    @State private var openSwipeReminderId: UUID?

    var body: some View {
        AppBackground {
            VStack(spacing: 12) {
                ScreenTitleView(title: "Notifications", showBack: true, showNotifications: true, notificationHighlighted: true) {
                    dismiss()
                }
                .padding(.horizontal, 20)

                if let todayReminder {
                    GlassCard {
                        HStack {
                            AlertBadgeIcon(imageName: "Frame 15")
                            VStack(alignment: .leading, spacing: 4) {
                                Text(todayReminder.details)
                                    .font(.custom("Unbounded-Regular", size: 16))
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }

                List {
                    if viewModel.reminders.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            Text("No data yet")
                                .font(.custom("Unbounded-Regular", size: 18))
                                .fontWeight(.medium)
                                .foregroundStyle(.white.opacity(0.7))
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                    
                    ForEach(viewModel.reminders.sorted(by: { $0.date < $1.date })) { reminder in
                        ZStack {
                            SwipeRevealRow(
                                isOpen: Binding(
                                    get: { openSwipeReminderId == reminder.id },
                                    set: { open in
                                        openSwipeReminderId = open ? reminder.id : nil
                                    }
                                ),
                                actions: {
                                    VStack(spacing: 8) {
                                        Button(action: withButtonSound {
                                            viewModel.delete(id: reminder.id)
                                            openSwipeReminderId = nil
                                        }) {
                                            Image("New")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 28, height: 28)
                                        }
                                        .buttonStyle(.plain)

                                        Button(action: withButtonSound {
                                            editingReminder = reminder
                                            openSwipeReminderId = nil
                                        }) {
                                            Image("Group 481")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 28, height: 28)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.trailing, 12)
                                },
                                content: {
                        HStack {
                            AlertBadgeIcon(imageName: reminder.date < Date() ? "Frame 15" : "Frame 16")
                            Text(reminder.name)
                                            .font(.custom("Unbounded-Regular", size: 16))
                                            .fontWeight(.regular)
                            Spacer()
                            Text(relativeDate(reminder.date))
                                            .font(.custom("Unbounded-Regular", size: 14))
                                            .fontWeight(.regular)
                                .foregroundStyle(reminder.date < Date() ? .red : AppColors.neon)
                        }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                            )
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }

                    HStack {
                        Spacer()
                        Button(action: withButtonSound {
                            showingForm = true
                        }) {
                            Circle()
                                .fill(Color(red: 0.76, green: 0.88, blue: 0.10))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Image(systemName: "plus")
                                        .font(.custom("Unbounded-Regular", size: 20))
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                )
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .fullScreenCover(isPresented: $showingForm) {
            ReminderFormView(mode: .create) { name, details, date in
                viewModel.add(name: name, details: details, date: date)
            }
        }
        .fullScreenCover(item: $editingReminder) { reminder in
            ReminderFormView(mode: .edit(reminder: reminder)) { name, details, date in
                viewModel.update(id: reminder.id, name: name, details: details, date: date)
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private var todayReminder: ReminderRecord? {
        viewModel.reminders.first(where: { Calendar.current.isDateInToday($0.date) })
    }

    private func relativeDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        }

        return Formatters.date.string(from: date)
    }
}

private struct AlertBadgeIcon: View {
    let imageName: String

    var body: some View {
        if UIImage(named: imageName) != nil {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
        } else {
            Circle()
                .fill(imageName == "Frame 15" ? Color.red : Color.blue)
                .frame(width: 24, height: 24)
                .overlay(
                    Text("!")
                        .font(.custom("Unbounded-Regular", size: 14))
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                )
        }
    }
}

struct ReminderFormView: View {
    enum Mode {
        case create
        case edit(reminder: ReminderRecord)

        var title: String { "Notifications" }
    }

    let mode: Mode
    let onSave: (String, String, Date) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var details = ""
    @State private var date = Date()
    @State private var isDatePickerExpanded = false
    @FocusState private var focusedField: Field?
    
    private var isCompactPhone: Bool {
        UIScreen.main.bounds.width <= 350
    }
    
    enum Field {
        case name, details
    }

    var body: some View {
            AppBackground {
                GeometryReader { geometry in
                    let scale = scaleForScreen(size: geometry.size)

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            GeometryReader { _ in
                                HStack {
                                    Button(action: withButtonSound { dismiss() }) {
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

                                    Spacer()

                                    Text(mode.title)
                                        .font(.custom("Unbounded-Regular", size: 22))
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.white)
                                        .shadow(color: .black.opacity(0.35), radius: 0, x: 0, y: 5)
                                        .singleLineScaled(0.5)

                                    Spacer()

                                    NotificationsEntryButton(highlighted: true)
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 12)
                            }
                            .frame(height: 70)

                            VStack(alignment: .leading, spacing: isCompactPhone ? 16 : 34) {
                                fieldSection(label: "Name:") {
                                    HStack {
                                        ZStack(alignment: .leading) {
                                            if name.isEmpty {
                                                Text("name")
                                                    .font(.custom("Unbounded-Regular", size: isCompactPhone ? 15 : 17))
                                                    .foregroundStyle(Color.black.opacity(0.5))
                                            }
                                            TextField("", text: $name)
                                                .focused($focusedField, equals: .name)
                                                .keyboardType(.default)
                                                .font(.custom("Unbounded-Regular", size: isCompactPhone ? 15 : 17))
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.black)
                                                .singleLineScaled(0.6)
                                        }
                                        Spacer()
                                        Image(systemName: "pencil")
                                            .font(.system(size: isCompactPhone ? 18 : 20, weight: .medium))
                                            .foregroundStyle(Color(red: 0.53, green: 0.72, blue: 0.84))
                                    }
                                }

                                fieldSection(label: "Description:") {
                                    HStack {
                                        ZStack(alignment: .leading) {
                                            if details.isEmpty {
                                                Text("description")
                                                    .font(.custom("Unbounded-Regular", size: isCompactPhone ? 15 : 17))
                                                    .foregroundStyle(Color.black.opacity(0.5))
                                            }
                                            TextField("", text: $details)
                                                .focused($focusedField, equals: .details)
                                                .keyboardType(.default)
                                                .font(.custom("Unbounded-Regular", size: isCompactPhone ? 15 : 17))
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.black)
                                                .singleLineScaled(0.6)
                                        }
                                        Spacer()
                                        if !details.isEmpty {
                                            Button(action: withButtonSound {
                                                details = ""
                                            }) {
                                                Image(systemName: "xmark")
                                                    .font(.system(size: isCompactPhone ? 16 : 18, weight: .medium))
                                                    .foregroundStyle(Color(red: 0.53, green: 0.72, blue: 0.84))
                                            }
                                        }
                                    }
                                }

                                fieldSection(
                                    label: "Date:",
                                    borderColor: isDatePickerExpanded
                                        ? Color(red: 0.38, green: 0.00, blue: 1.0)
                                        : Color(red: 0.50, green: 0.68, blue: 0.84)
                                ) {
                                    Button(action: withButtonSound {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            isDatePickerExpanded.toggle()
                                        }
                                    }) {
                                        HStack {
                                            Text(Formatters.date.string(from: date))
                                                .font(.custom("Unbounded-Regular", size: isCompactPhone ? 13 : 15))
                                                .fontWeight(.semibold)
                                                .foregroundStyle(Color(red: 0.15, green: 0.0, blue: 0.46).opacity(0.5))
                                                .singleLineScaled(0.6)
                                            Spacer()
                                            Image(systemName: isDatePickerExpanded ? "chevron.up" : "chevron.down")
                                                .font(.system(size: isCompactPhone ? 14 : 16, weight: .medium))
                                                .foregroundStyle(Color(red: 0.45, green: 0.64, blue: 0.77))
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(isCompactPhone ? 14 : 20)
                            .frame(maxWidth: isCompactPhone ? min(404, geometry.size.width - 36) : 404)
                            .background(Color(red: 0.88, green: 1.0, blue: 0.25))
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .padding(.top, isCompactPhone ? 8 : 12)
                            .padding(.horizontal, isCompactPhone ? 12 : 18)

                            ZStack {
                                if isDatePickerExpanded {
                                    CalendarPickerView(date: $date)
                                        .frame(maxWidth: isCompactPhone ? min(404, geometry.size.width - 36) : 404)
                                        .padding(.top, 6)
                                        .padding(.horizontal, isCompactPhone ? 12 : 18)
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                } else {
                                    SaveButton {
                                        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                                        guard !normalizedName.isEmpty else { return }
                                        onSave(normalizedName, details, date)
                                        dismiss()
                                    }
                                    .transition(.opacity)
                                }
                            }
                            .frame(minHeight: isDatePickerExpanded ? 400 : 80)
                            .animation(.none, value: isDatePickerExpanded)

                            Color.clear
                                .frame(height: 400)
                        }
                        .padding(.top, 20)
                    }
                    .verticalBounceBasedOnSizeIfAvailable()
                    .scaleEffect(scale)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
        }
        .onAppear(perform: setup)
    }
    
    @ViewBuilder
    private func fieldSection<Content: View>(label: String, borderColor: Color = Color(red: 0.53, green: 0.72, blue: 0.84), @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: isCompactPhone ? 5 : 8) {
            Text(label)
                .font(.custom("Unbounded-Regular", size: isCompactPhone ? 14 : 17))
                .fontWeight(.semibold)
                .foregroundStyle(Color(red: 0.15, green: 0.0, blue: 0.46))
                .singleLineScaled(0.7)

            HStack {
                content()
            }
            .padding(.horizontal, isCompactPhone ? 10 : 16)
            .frame(height: isCompactPhone ? 48 : 56)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 37, style: .continuous)
                    .stroke(borderColor, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 37, style: .continuous))
        }
    }

    private func setup() {
        guard case .edit(let reminder) = mode else { return }
        name = reminder.name
        details = reminder.details
        date = reminder.date
    }

    private func scaleForScreen(size: CGSize) -> CGFloat {
        let requiredHeight: CGFloat = 720
        let topPadding: CGFloat = isCompactPhone ? 80 : 110
        let bottomPadding: CGFloat = isCompactPhone ? 24 : 40
        let availableHeight = size.height - topPadding - bottomPadding
        let heightScale = min(1.0, availableHeight / requiredHeight)

        let horizontalPadding: CGFloat = isCompactPhone ? 24 : 36
        let widthScale = min(1.0, (size.width - horizontalPadding) / 404)

        let scale = min(heightScale, widthScale)
        let minScale: CGFloat = isCompactPhone ? 0.7 : 0.8
        return max(minScale, scale)
    }
}
