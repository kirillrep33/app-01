import SwiftUI

struct SalesListView: View {
    @ObservedObject var viewModel: SalesListViewModel

    @State private var saleToEdit: SaleRecord?
    @State private var saleToView: SaleRecord?
    @State private var showingCreate = false
    @State private var openSwipeSaleId: UUID?

    var body: some View {
        AppBackground {
            VStack(spacing: 12) {
                ScreenTitleView(title: "Sales")
                    .padding(.horizontal, 20)

                HStack(spacing: 12) {
                HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .padding(.leading, 12)
                        
                    TextField("Search...", text: $viewModel.searchText)
                            .padding(.vertical, 10)
                    }
                    .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    Button(action: withButtonSound {
                        viewModel.toggleSort()
                    }) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, 20)

                List {
                    if viewModel.filteredSales.isEmpty {
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
                    
                    ForEach(viewModel.filteredSales) { sale in
                        ZStack {
                            SwipeRevealRow(
                                isOpen: Binding(
                                    get: { openSwipeSaleId == sale.id },
                                    set: { open in
                                        openSwipeSaleId = open ? sale.id : nil
                                    }
                                ),
                                actions: {
                                    HStack(spacing: 8) {
                                        Button(action: withButtonSound {
                                            viewModel.deleteSale(id: sale.id)
                                            openSwipeSaleId = nil
                                        }) {
                                            Image("New")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 28, height: 28)
                                        }
                                        .buttonStyle(.plain)

                                        Button(action: withButtonSound {
                                saleToEdit = sale
                                            openSwipeSaleId = nil
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
                                        if openSwipeSaleId != sale.id {
                                            saleToView = sale
                                        }
                        }) {
                            HStack {
                                Text("\(sale.species) \(Formatters.number(sale.weightKg)) kg")
                                            .font(.custom("Unbounded-Regular", size: 16))
                                            .fontWeight(.regular)
                                            .foregroundColor(.black)
                                            .singleLineScaled(0.5)
                                            .layoutPriority(1)
                                Spacer()
                                Text("\(Formatters.number(sale.totalPrice)) lbs")
                                            .font(.custom("Unbounded-Regular", size: 16))
                                            .fontWeight(.regular)
                                            .foregroundColor(Color(red: 0.76, green: 0.88, blue: 0.10))
                                            .singleLineScaled(0.55)
                                Text(Formatters.date.string(from: sale.date))
                                            .font(.custom("Unbounded-Regular", size: 14))
                                            .fontWeight(.regular)
                                            .foregroundColor(.black)
                                            .singleLineScaled(0.55)
                                    }
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 16)
                                        .background(Color.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                    }
                                    .buttonStyle(.plain)
                                }
                            )
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                            }

                            Button {
                        showingCreate = true
                            } label: {
                    HStack {
                        Spacer()
                            Circle()
                                .fill(Color(red: 0.76, green: 0.88, blue: 0.10))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Image(systemName: "plus")
                                        .foregroundColor(.white)
                                        .font(.custom("Unbounded-Regular", size: 14))
                                        .fontWeight(.bold)
                                )
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .fullScreenCover(isPresented: $showingCreate) {
            SaleFormView(mode: .create(speciesOptions: viewModel.speciesOptions)) { draft in
                viewModel.addSale(draft)
            }
        }
        .fullScreenCover(item: $saleToEdit) { sale in
            SaleFormView(mode: .edit(sale: sale, speciesOptions: viewModel.speciesOptions)) { updated in
                viewModel.updateSale(updated)
            }
        }
        .fullScreenCover(item: $saleToView) { sale in
            SaleDetailView(sale: sale) {
                saleToEdit = sale
                saleToView = nil
            }
        }
    }
}

struct SaleDetailView: View {
    let sale: SaleRecord
    let onEdit: () -> Void

    @Environment(\.dismiss) private var dismiss
    
    private var isCompactPhone: Bool {
        UIScreen.main.bounds.width <= 350
    }

    var body: some View {
        AppBackground {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    ScreenTitleView(title: "\(sale.species) sale", showBack: true) {
                        dismiss()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(sale.species)
                                .font(.custom("Unbounded-Regular", size: isCompactPhone ? 32 : 42))
                                .fontWeight(.heavy)
                            Text("Weight: \(Formatters.number(sale.weightKg)) kg")
                                .font(.custom("Unbounded-Regular", size: isCompactPhone ? 15 : 17))
                            Text("\(Formatters.number(sale.totalPrice)) lbs")
                                .font(.custom("Unbounded-Regular", size: isCompactPhone ? 18 : 20))
                                .fontWeight(.bold)
                            Text("Date: \(Formatters.date.string(from: sale.date))")
                                .font(.custom("Unbounded-Regular", size: isCompactPhone ? 15 : 17))
                        }
                    }
                    .padding(.horizontal, 20)

                    GlassCard {
                        HStack {
                            Text("Buyer:")
                            Spacer()
                            Text(sale.buyer)
                        }
                    }
                    .padding(.horizontal, 20)

                    GlassCard {
                        HStack {
                            Text("Category:")
                            Spacer()
                            Text(sale.category.rawValue)
                        }
                    }
                    .padding(.horizontal, 20)

                    GlassCard {
                        HStack {
                            Spacer()
                            Text("\(Formatters.number(sale.pricePerKg)) pounds/kg")
                                .font(.custom("Unbounded-Regular", size: isCompactPhone ? 18 : 22))
                                .fontWeight(.bold)
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 24)

                    PrimaryActionButton(title: "Edit", action: onEdit)
                        .padding(.horizontal, 20)

                    Spacer(minLength: 80)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct SaleFormView: View {
    enum Mode {
        case create(speciesOptions: [String])
        case edit(sale: SaleRecord, speciesOptions: [String])

        var title: String {
            switch self {
            case .create: return "New sale"
            case .edit: return "Edit sale"
            }
        }

        var speciesOptions: [String] {
            switch self {
            case .create(let options): return options
            case .edit(_, let options): return options
            }
        }
    }

    let mode: Mode
    let onSave: (SaleRecord) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var draftId = UUID()
    @State private var species = ""
    @State private var weight = ""
    @State private var price = ""
    @State private var buyer = ""
    @State private var category: BuyerCategory = .wholesaler
    @State private var date = Date()
    @State private var isDatePickerExpanded = false
    @FocusState private var focusedField: Field?
    
    private var isCompactPhone: Bool {
        UIScreen.main.bounds.width <= 350
    }
    
    enum Field {
        case weight, price, buyer
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

    var body: some View {
        AppBackground {
            ZStack {
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

                                NotificationsEntryButton()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 2)
                        }
                        .frame(height: 70)

                        VStack(alignment: .leading, spacing: isCompactPhone ? 8 : 18) {
                    fieldSection(label: "Species") {
                        Menu {
                            ForEach([species] + mode.speciesOptions.filter { !$0.isEmpty && $0 != species }, id: \.self) { option in
                                Button(action: withButtonSound {
                                    species = option
                                }) {
                                    Text(option.isEmpty ? "-" : option)
                                }
                            }
                        } label: {
                            HStack {
                                Text(species.isEmpty ? "species" : species)
                                    .font(species.isEmpty ? .custom("Unbounded-Regular", size: isCompactPhone ? 15 : 17) : .custom("Unbounded-Regular", size: isCompactPhone ? 15 : 17))
                                    .fontWeight(species.isEmpty ? .regular : .semibold)
                                    .foregroundStyle(species.isEmpty ? Color.black.opacity(0.5) : .black)
                                    .singleLineScaled(0.6)
                                Spacer()
                                Image(systemName: "chevron.down")
                                        .font(.custom("Unbounded-Regular", size: isCompactPhone ? 14 : 16))
                                        .fontWeight(.medium)
                                    .foregroundStyle(Color(red: 0.53, green: 0.72, blue: 0.84))
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    fieldSection(label: "Weight") {
                        HStack {
                            ZStack(alignment: .leading) {
                                if weight.isEmpty {
                                    Text("weight")
                                        .font(.custom("Unbounded-Regular", size: isCompactPhone ? 15 : 17))
                                        .foregroundStyle(Color.black.opacity(0.5))
                                }
                                NumericTextField(text: $weight, keyboardType: .decimalPad)
                            }
                            Spacer()
                            if !weight.isEmpty {
                                Button(action: withButtonSound {
                                    weight = ""
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: isCompactPhone ? 16 : 18, weight: .medium))
                                        .foregroundStyle(.gray.opacity(0.6))
                                }
                            }
                        }
                    }

                    fieldSection(label: "Price") {
                        HStack {
                            ZStack(alignment: .leading) {
                                if price.isEmpty {
                                    Text("price")
                                        .font(.custom("Unbounded-Regular", size: isCompactPhone ? 15 : 17))
                                        .foregroundStyle(Color.black.opacity(0.5))
                                }
                                NumericTextField(text: $price, keyboardType: .decimalPad)
                            }
                            Spacer()
                            Image(systemName: "pencil")
                                .font(.custom("Unbounded-Regular", size: isCompactPhone ? 18 : 20))
                                .fontWeight(.medium)
                                .foregroundStyle(Color(red: 0.53, green: 0.72, blue: 0.84))
                        }
                    }

                    fieldSection(label: "Buyer") {
                        HStack {
                            ZStack(alignment: .leading) {
                                if buyer.isEmpty {
                                    Text("buyer")
                                        .font(.custom("Unbounded-Regular", size: isCompactPhone ? 15 : 17))
                                        .foregroundStyle(Color.black.opacity(0.5))
                                }
                                TextField("", text: $buyer)
                                    .focused($focusedField, equals: .buyer)
                                    .keyboardType(.default)
                                    .font(.custom("Unbounded-Regular", size: isCompactPhone ? 15 : 17))
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.black)
                                    .singleLineScaled(0.6)
                            }
                            Spacer()
                            if !buyer.isEmpty {
                                Button(action: withButtonSound {
                                    buyer = ""
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: isCompactPhone ? 16 : 18, weight: .medium))
                                        .foregroundStyle(.gray.opacity(0.6))
                                }
                            }
                        }
                    }

                    fieldSection(label: "Category") {
                        Menu {
                            ForEach(BuyerCategory.allCases) { cat in
                                Button(action: withButtonSound {
                                    category = cat
                                }) {
                                    Text(cat.rawValue)
                                }
                            }
                        } label: {
                            HStack {
                                Text(category.rawValue)
                                    .font(.custom("Unbounded-Regular", size: isCompactPhone ? 15 : 17))
                                    .foregroundStyle(Color.black.opacity(0.5))
                                    .singleLineScaled(0.6)
                                Spacer()
                                Image(systemName: "chevron.down")
                                        .font(.custom("Unbounded-Regular", size: isCompactPhone ? 14 : 16))
                                        .fontWeight(.medium)
                                    .foregroundStyle(Color(red: 0.53, green: 0.72, blue: 0.84))
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    fieldSection(
                        label: "Date",
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
                .padding(.top, 0)
                .padding(.horizontal, isCompactPhone ? 12 : 18)
                .scaleEffect(scale)
                .opacity(isDatePickerExpanded ? 0.3 : 1.0)

                        if !isDatePickerExpanded {
                            SaveButton {
                                guard !species.isEmpty else { return }

                                let sale = SaleRecord(
                                    id: draftId,
                                    species: species,
                                    weightKg: Double(weight.replacingOccurrences(of: ",", with: ".")) ?? 0,
                                    totalPrice: Double(price.replacingOccurrences(of: ",", with: ".")) ?? 0,
                                    buyer: buyer.isEmpty ? "Unknown" : buyer,
                                    category: category,
                                    date: date
                                )
                                onSave(sale)
                                dismiss()
                            }
                            .padding(.top, isCompactPhone ? 12 : 16)
                            .scaleEffect(scale)
                            .transition(.opacity)
                        }

                        // Небольшой запас снизу вместо жёсткого отступа 300pt,
                        // чтобы все элементы влезали на SE без необходимости скролла.
                        Spacer(minLength: isCompactPhone ? 32 : 64)
                    }
                }
                .verticalBounceBasedOnSizeIfAvailable()
                // Масштабируем содержимое от верхнего края, чтобы при уменьшении формы
                // верх не «отъезжал» вниз и не появлялся лишний отступ.
                .scaleEffect(scale, anchor: .top)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
                
                if isDatePickerExpanded {
                    ZStack {
                        Color.black.opacity(0.6)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isDatePickerExpanded = false
                                }
                            }
                        
                        GeometryReader { calendarGeometry in
                            let calendarScale = scaleForScreen(size: calendarGeometry.size)
                            
                            CalendarPickerView(date: $date)
                                .frame(maxWidth: isCompactPhone ? min(404, calendarGeometry.size.width - 36) : 404)
                                .scaleEffect(calendarScale)
                                .transition(.opacity.combined(with: .scale))
                                .offset(y: 80)
                        }
                    }
                }
            }
        }
        .onAppear(perform: setup)
    }

    private func scaleForScreen(size: CGSize) -> CGFloat {
        // Высота, под которую разрабатывался макет формы New sale.
        let requiredHeight: CGFloat = 780
        let topPadding: CGFloat = isCompactPhone ? 80 : 110
        let bottomPadding: CGFloat = isCompactPhone ? 24 : 40
        let availableHeight = size.height - topPadding - bottomPadding
        let heightScale = min(1.0, availableHeight / requiredHeight)
        
        let horizontalPadding: CGFloat = isCompactPhone ? 24 : 36
        let widthScale = min(1.0, (size.width - horizontalPadding) / 404)

        // Масштаб выбираем минимальный по высоте и ширине,
        // без минимального порога — так на SE контент гарантированно влезает
        // целиком и не требует скролла.
        return min(heightScale, widthScale)
    }

    private func setup() {
        switch mode {
        case .create:
            species = ""
            weight = ""
            price = ""
            buyer = ""
            category = .wholesaler
            date = Date()
        case .edit(let sale, _):
            draftId = sale.id
            species = sale.species
            weight = Formatters.number(sale.weightKg)
            price = Formatters.number(sale.totalPrice)
            buyer = sale.buyer
            category = sale.category
            date = sale.date
        }
    }
}
