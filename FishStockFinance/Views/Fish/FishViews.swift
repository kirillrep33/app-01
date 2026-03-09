import SwiftUI
import PhotosUI
import Charts

struct FishListView: View {
    @ObservedObject var viewModel: FishListViewModel

    @State private var showingFishForm = false
    @State private var editingFish: FishRecord?
    @State private var openSwipeFishId: UUID?
    @State private var fishToView: FishRecord?

    var body: some View {
        AppBackground {
            VStack(spacing: 14) {
                ScreenTitleView(title: "List of fish")
                    .padding(.horizontal, 20)

                List {
                    if viewModel.fishes.isEmpty {
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
                    
                    ForEach(viewModel.fishes) { fish in
                        ZStack {
                            SwipeRevealRow(
                                isOpen: Binding(
                                    get: { openSwipeFishId == fish.id },
                                    set: { open in
                                        openSwipeFishId = open ? fish.id : nil
                                    }
                                ),
                                actions: {
                                    VStack(spacing: 8) {
                                        Button(action: withButtonSound {
                                            viewModel.deleteFish(id: fish.id)
                                            openSwipeFishId = nil
                                        }) {
                                            Image("New")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 28, height: 28)
                                        }
                                        .buttonStyle(.plain)

                                        Button(action: withButtonSound {
                                            editingFish = fish
                                            openSwipeFishId = nil
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
                                    Button(action: withButtonSound {
                                        if openSwipeFishId != fish.id {
                                            fishToView = fish
                                        }
                        }) {
                            fishRow(fish)
                                    }
                                    .buttonStyle(.plain)
                                }
                            )
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }

                    HStack {
                        AddRecordBar { showingFishForm = true }
                    }
                    .padding(.vertical, 12)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .padding(.bottom, 4)
        }
        .fullScreenCover(isPresented: $showingFishForm) {
            FishFormView(mode: .create) { species, quantity, ageGroup, imageData in
                viewModel.addFish(species: species, quantity: quantity, ageGroup: ageGroup, imageData: imageData)
            }
        }
        .fullScreenCover(item: $editingFish) { fish in
            FishFormView(mode: .edit(fish)) { species, quantity, ageGroup, imageData in
                viewModel.updateFish(id: fish.id, species: species, quantity: quantity, ageGroup: ageGroup, imageData: imageData)
            }
        }
        .fullScreenCover(item: $fishToView) { fish in
            FishDetailView(viewModel: viewModel, fishId: fish.id)
        }
    }

    @ViewBuilder
    private func fishRow(_ fish: FishRecord) -> some View {
        HStack(spacing: 8) {
            if let data = fish.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
            } else {
            Text("🐟")
                .font(.system(size: 36))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(fish.species)
                    .font(.custom("Unbounded-Regular", size: 16))
                    .fontWeight(.semibold)
                    .singleLineScaled(0.55)
                    .layoutPriority(1)
                Text(fish.ageGroup.rawValue)
                    .font(.custom("Unbounded-Regular", size: 14))
                    .fontWeight(.light)
                    .foregroundStyle(AppColors.neon)
                    .singleLineScaled(0.6)
            }

            Spacer()

            Text("\(fish.quantity) pcs")
                .font(.custom("Unbounded-Regular", size: 16))
                .fontWeight(.medium)
                .singleLineScaled(0.55)

            AddCircleButton {
                applyQuickOperation(
                    fish,
                    quantity: 200,
                    kind: .incomingFry
                )
            }

            Button(action: withButtonSound {
                applyQuickOperation(
                    fish,
                    quantity: 50,
                    kind: .sold
                )
            }) {
                Image("Minus")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)

            Button(action: withButtonSound {
                applyQuickOperation(
                    fish,
                    quantity: 5,
                    kind: .dead
                )
            }) {
                Image("Group 3")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func applyQuickOperation(
        _ fish: FishRecord,
        quantity: Int,
        kind: FishOperationKind
    ) {
        if !kind.isIncoming, fish.quantity < quantity {
            return
        }

        viewModel.addOperation(
            fishId: fish.id,
            quantity: quantity,
            kind: kind,
            date: Date()
        )
    }
}

private struct FishOperationDraft: Identifiable {
    let id = UUID()
    let fish: FishRecord
    let presetKind: FishOperationKind?
    let existingOperation: FishOperation?

    init(fish: FishRecord, presetKind: FishOperationKind?, existingOperation: FishOperation? = nil) {
        self.fish = fish
        self.presetKind = presetKind
        self.existingOperation = existingOperation
    }
}

struct FishDetailView: View {
    @ObservedObject var viewModel: FishListViewModel
    let fishId: UUID

    @Environment(\.dismiss) private var dismiss

    @State private var operationDraft: FishOperationDraft?
    @State private var openSwipeOperationId: UUID?

    var body: some View {
        AppBackground {
            VStack(spacing: 0) {
                ScreenTitleView(title: fish?.species ?? "Fish", showBack: true) {
                    dismiss()
                }
                .padding(.horizontal, 20)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 14) {
                        if let fish {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(fish.species)
                                            .font(.custom("Unbounded-Regular", size: 24))
                                            .fontWeight(.bold)
                                            .foregroundColor(.black)
                                    Text("Quantity: \(fish.quantity)")
                                            .font(.custom("Unbounded-Regular", size: 16))
                                            .fontWeight(.medium)
                                            .foregroundColor(.black)
                                    Text("Age group: \(fish.ageGroup.rawValue)")
                                            .font(.custom("Unbounded-Regular", size: 14))
                                            .fontWeight(.regular)
                                            .foregroundColor(.black)
                                    Text("Last count date: \(Formatters.date.string(from: fish.lastCountDate))")
                                            .font(.custom("Unbounded-Regular", size: 14))
                                            .fontWeight(.regular)
                                            .foregroundColor(.black)
                                    }

                                    Spacer()

                                    if let data = fish.imageData, let uiImage = UIImage(data: data) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 150, height: 110)
                                    } else {
                                        Text("🐟")
                                            .font(.system(size: 90))
                                    }
                                }
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity)
                            .background(Color(red: 0.88, green: 1.0, blue: 0.25))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .padding(.horizontal, 20)

                            VStack(spacing: 12) {
                            if fish.operations.isEmpty {
                                VStack(spacing: 12) {
                                    Text("No data yet")
                                        .font(.custom("Unbounded-Regular", size: 18))
                                        .fontWeight(.medium)
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            }
                            
                            ForEach(fish.operations.sorted(by: { $0.date > $1.date })) { operation in
                                SwipeRevealRow(
                                    isOpen: Binding(
                                        get: { openSwipeOperationId == operation.id },
                                        set: { open in
                                            openSwipeOperationId = open ? operation.id : nil
                                        }
                                    ),
                                    actions: {
                                        HStack(spacing: 8) {
                                            Button(action: withButtonSound {
                                                viewModel.deleteOperation(fishId: fish.id, operationId: operation.id)
                                                openSwipeOperationId = nil
                                            }) {
                                                Image("New")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 28, height: 28)
                                            }
                                            .buttonStyle(.plain)

                                            Button(action: withButtonSound {
                                                operationDraft = FishOperationDraft(
                                                    fish: fish,
                                                    presetKind: operation.kind,
                                                    existingOperation: operation
                                                )
                                                openSwipeOperationId = nil
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
                                        operationRow(operation)
                                    }
                                )
                            }

                            HStack {
                                Spacer()
                                Button(action: withButtonSound {
                                    operationDraft = FishOperationDraft(
                                        fish: fish,
                                        presetKind: .sold
                                    )
                                }) {
                                    Circle()
                                        .fill(Color(red: 0.76, green: 0.88, blue: 0.10))
                                        .frame(width: 48, height: 48)
                                        .overlay(
                                            Image(systemName: "plus")
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                    }
                                .buttonStyle(.plain)
                                Spacer()
                            }
                            .padding(.top, 8)
                            }
                            .padding(.horizontal, 20)
                            
                            Color.clear
                                .frame(height: 100)
                        }
                    }
                }
                .verticalBounceBasedOnSizeIfAvailable()
            }
        }
        .overlay {
            if let draft = operationDraft {
                FishOperationOverlay(
                    fish: draft.fish,
                    initialQuantity: draft.existingOperation?.quantity ?? 0,
                    initialKind: draft.existingOperation?.kind ?? draft.presetKind ?? .sold,
                    initialDate: draft.existingOperation?.date ?? Date(),
                    onClose: { operationDraft = nil },
                    onSave: { quantity, kind, date in
                        if let existing = draft.existingOperation {
                            viewModel.updateOperation(
                                fishId: draft.fish.id,
                                operationId: existing.id,
                                quantity: quantity,
                                kind: kind,
                                date: date
                            )
                        } else {
                            viewModel.addOperation(fishId: draft.fish.id, quantity: quantity, kind: kind, date: date)
                        }
                        operationDraft = nil
                    }
                )
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private var fish: FishRecord? {
        viewModel.fish(by: fishId)
    }

    @ViewBuilder
    private func operationRow(_ operation: FishOperation) -> some View {
        HStack {
            HStack(spacing: 4) {
                Text(operation.kind.isIncoming ? "+\(operation.quantity) fry" : "-\(operation.quantity) fry")
                    .font(.custom("Unbounded-Regular", size: 16))
                    .fontWeight(.regular)
                    .foregroundColor(.black)
                
                if !operation.kind.isIncoming {
                    Text(operation.kind == .sold ? "sold" : "dead")
                        .font(.custom("Unbounded-Regular", size: 16))
                        .fontWeight(.regular)
                        .foregroundColor(operation.kind == .sold ? Color(red: 0.76, green: 0.88, blue: 0.10) : Color(red: 0.95, green: 0.51, blue: 0.51))
                }
            }
            
            Spacer()
            
            Text(formatDate(operation.date))
                .font(.custom("Unbounded-Regular", size: 14))
                .fontWeight(.regular)
                .foregroundColor(.black)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: date)
    }
}

struct FishFormView: View {
    enum Mode {
        case create
        case edit(FishRecord)

        var title: String {
            switch self {
            case .create: return "New fish"
            case .edit: return "Edit fish"
            }
        }
    }

    let mode: Mode
    let onSave: (String, Int, FishAgeGroup, Data?) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var species = ""
    @State private var quantity = ""
    @State private var ageGroup: FishAgeGroup = .young
    @State private var selectedImageData: Data?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @FocusState private var focusedField: Field?
    
    enum Field {
        case species, quantity
    }

    var body: some View {
            AppBackground {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
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

                        NotificationsEntryButton()
                    }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    }
                    .frame(height: 70)

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Circle()
                            .fill(Color(red: 0.78, green: 0.91, blue: 0.99))
                            .frame(width: 190, height: 190)
                            .overlay(
                    Circle()
                                    .stroke(Color.yellow, lineWidth: 3)
                            )
                            .overlay {
                                if let selectedImageData, let uiImage = UIImage(data: selectedImageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                        .frame(width: 190, height: 190)
                                        .clipShape(Circle())
                                } else {
                                    Text("upload image...")
                                        .foregroundStyle(.gray)
                                }
                            }
                    }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Type:").font(.custom("Unbounded-Regular", size: 20)).fontWeight(.bold)
                            .foregroundColor(Color(red: 0.01, green: 0.08, blue: 0.30))
                        HStack {
                            ZStack(alignment: .leading) {
                                if species.isEmpty {
                                    Text("type")
                                        .font(.custom("Unbounded-Regular", size: 20))
                                        .foregroundColor(Color(red: 0.01, green: 0.08, blue: 0.30).opacity(0.5))
                                }
                                TextField("", text: $species)
                                    .focused($focusedField, equals: .species)
                                    .submitLabel(.done)
                                    .frame(maxWidth: .infinity)
                            }
                            if !species.isEmpty {
                                Button(action: withButtonSound {
                                    species = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.purple)
                                }
                            }
                        }
                                .padding(10)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                            Text("Initial Quantity:").font(.custom("Unbounded-Regular", size: 20)).fontWeight(.bold)
                            .foregroundColor(Color(red: 0.01, green: 0.08, blue: 0.30))
                        HStack {
                            ZStack(alignment: .leading) {
                                if quantity.isEmpty {
                                    Text("initial quantity")
                                        .font(.custom("Unbounded-Regular", size: 20))
                                        .foregroundColor(Color(red: 0.01, green: 0.08, blue: 0.30).opacity(0.5))
                                }
                                TextField("", text: $quantity)
                                    .focused($focusedField, equals: .quantity)
                                    .keyboardType(.numberPad)
                            }
                            Image(systemName: "pencil")
                                .foregroundColor(Color(red: 0.78, green: 0.91, blue: 0.99))
                        }
                                .padding(10)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                            Text("Age Group:").font(.custom("Unbounded-Regular", size: 20)).fontWeight(.bold)
                            .foregroundColor(Color(red: 0.01, green: 0.08, blue: 0.30))
                        Menu {
                            ForEach(FishAgeGroup.allCases) { group in
                                Button(action: withButtonSound {
                                    ageGroup = group
                                }) {
                                    Text(group.rawValue)
                                }
                            }
                        } label: {
                            HStack {
                                Text(ageGroup.rawValue)
                                    .font(.custom("Unbounded-Regular", size: 20))
                                    .foregroundColor(.gray)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(Color(red: 0.78, green: 0.91, blue: 0.99))
                            }
                            .padding(10)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color(red: 0.82, green: 0.94, blue: 0.18))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(Color(red: 0.78, green: 0.91, blue: 0.99), lineWidth: 2)
                            )
                    )
                    .padding(.horizontal, 20)

                    SaveButton {
                        let normalized = species.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !normalized.isEmpty else { return }
                        onSave(normalized, Int(quantity) ?? 0, ageGroup, selectedImageData)
                        dismiss()
                    }

                    Spacer()
                }
                }
                .verticalBounceBasedOnSizeIfAvailable()
        }
        .onChange(of: selectedPhotoItem) { newValue in
            guard let newValue else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        selectedImageData = data
                    }
                }
            }
        }
        .onAppear(perform: setup)
    }

    private func setup() {
        if case .edit(let fish) = mode {
            species = fish.species
            quantity = String(fish.quantity)
            ageGroup = fish.ageGroup
            selectedImageData = fish.imageData
        }
    }
}

struct FishOperationOverlay: View {
    let fish: FishRecord
    let initialQuantity: Int
    let initialKind: FishOperationKind
    let initialDate: Date
    let onClose: () -> Void
    let onSave: (Int, FishOperationKind, Date) -> Void

    @State private var quantityText: String
    @State private var kind: FishOperationKind
    @State private var date: Date
    @State private var isCalendarExpanded = false
    @FocusState private var isQuantityFocused: Bool

    init(
        fish: FishRecord,
        initialQuantity: Int,
        initialKind: FishOperationKind,
        initialDate: Date,
        onClose: @escaping () -> Void,
        onSave: @escaping (Int, FishOperationKind, Date) -> Void
    ) {
        self.fish = fish
        self.initialQuantity = initialQuantity
        self.initialKind = initialKind
        self.initialDate = initialDate
        self.onClose = onClose
        self.onSave = onSave
        _quantityText = State(initialValue: String(initialQuantity))
        _kind = State(initialValue: initialKind)
        _date = State(initialValue: initialDate)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.42)
                    .ignoresSafeArea()
                    .onTapGesture {
                        onClose()
                    }

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 10) {
                        if !isCalendarExpanded {
                            Spacer()
                                .frame(height: max(0, (geometry.size.height - 400) / 2))
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                    Text("Quantity")
                        .font(.custom("Unbounded-Regular", size: 14))
                        .fontWeight(.bold)
                        .foregroundStyle(Color(red: 0.19, green: 0.05, blue: 0.55))
                        .singleLineScaled(0.7)

                    fieldContainer {
                        ZStack(alignment: .leading) {
                            if quantityText.isEmpty {
                                Text("quantity")
                                    .font(.custom("Unbounded-Regular", size: 18))
                                    .foregroundStyle(Color(red: 0.53, green: 0.45, blue: 0.70).opacity(0.5))
                            }
                            TextField("", text: $quantityText)
                                .keyboardType(.numberPad)
                                .focused($isQuantityFocused)
                                .font(.custom("Unbounded-Regular", size: 18))
                                .fontWeight(.bold)
                                .foregroundStyle(Color(red: 0.53, green: 0.45, blue: 0.70))
                                .singleLineScaled(0.6)
                        }
                        Image(systemName: "pencil")
                            .font(.custom("Unbounded-Regular", size: 22))
                            .fontWeight(.medium)
                            .foregroundStyle(Color(red: 0.70, green: 0.80, blue: 0.88))
                    }

                    Text("Status:")
                        .font(.custom("Unbounded-Regular", size: 14))
                        .fontWeight(.bold)
                        .foregroundStyle(Color(red: 0.19, green: 0.05, blue: 0.55))
                        .singleLineScaled(0.7)

                    Menu {
                        ForEach(FishOperationKind.allCases) { option in
                            Button(action: withButtonSound {
                                kind = option
                            }) {
                                Text(option.rawValue)
                            }
                        }
                    } label: {
                        fieldContainer {
                            Text(kind.rawValue)
                                .font(.custom("Unbounded-Regular", size: 18))
                                .foregroundStyle(Color(red: 0.53, green: 0.45, blue: 0.70))
                                .singleLineScaled(0.6)
                            Image(systemName: "chevron.down")
                                .font(.custom("Unbounded-Regular", size: 16))
                                .fontWeight(.bold)
                                .foregroundStyle(Color(red: 0.45, green: 0.64, blue: 0.77))
                        }
                    }
                    .buttonStyle(.plain)

                    Text("Date:")
                        .font(.custom("Unbounded-Regular", size: 14))
                        .fontWeight(.bold)
                        .foregroundStyle(Color(red: 0.19, green: 0.05, blue: 0.55))
                        .singleLineScaled(0.7)

                    Button(action: withButtonSound {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isCalendarExpanded.toggle()
                        }
                    }) {
                        fieldContainer(
                            borderColor: isCalendarExpanded
                            ? Color(red: 0.38, green: 0.00, blue: 1.0)
                            : Color(red: 0.50, green: 0.68, blue: 0.84)
                        ) {
                            Text(Formatters.date.string(from: date))
                                .font(.custom("Unbounded-Regular", size: 18))
                                .fontWeight(.bold)
                                .foregroundStyle(Color(red: 0.53, green: 0.45, blue: 0.70))
                                .singleLineScaled(0.6)
                            Image(systemName: isCalendarExpanded ? "chevron.up" : "chevron.down")
                                .font(.custom("Unbounded-Regular", size: 16))
                                .fontWeight(.bold)
                                .foregroundStyle(Color(red: 0.45, green: 0.64, blue: 0.77))
                        }
                    }
                    .buttonStyle(.plain)
                        }
                        .padding(16)
                        .background(Color(red: 0.82, green: 0.95, blue: 0.17))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                        ZStack {
                            if isCalendarExpanded {
                                CalendarPickerView(date: $date)
                                    .frame(maxWidth: 460)
                                    .padding(.top, 6)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            } else {
                                ZStack {
                                    Capsule()
                                        .fill(Color(red: 0.53, green: 0.57, blue: 0.66))
                                        .frame(height: 56)

                                    SaveButton {
                                        let quantity = max(0, Int(quantityText) ?? 0)
                                        onSave(quantity, kind, date)
                                    }
                                }
                                .transition(.opacity)
                            }
                        }
                        .frame(minHeight: isCalendarExpanded ? 400 : 80)
                        .animation(.none, value: isCalendarExpanded)

                        if isCalendarExpanded {
                            Color.clear
                                .frame(height: 400)
                        } else {
                            Spacer()
                                .frame(height: max(0, (geometry.size.height - 400) / 2))
                        }
                    }
                    .padding(.horizontal, 12)
                    .frame(minHeight: geometry.size.height)
                }
                .frame(maxWidth: 460)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    @ViewBuilder
    private func fieldContainer<Content: View>(
        borderColor: Color = Color(red: 0.50, green: 0.68, blue: 0.84),
        @ViewBuilder _ content: () -> Content
    ) -> some View {
        HStack {
            content()
            Spacer(minLength: 12)
        }
        .padding(.horizontal, 14)
        .frame(height: 56)
        .background(Color(red: 0.86, green: 0.86, blue: 0.86))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(borderColor, lineWidth: 2.8)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}


