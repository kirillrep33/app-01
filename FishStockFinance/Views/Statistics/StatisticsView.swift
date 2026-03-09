import SwiftUI
import Charts

struct StatisticsView: View {
    @ObservedObject var viewModel: StatisticsViewModel
    private var isCompactPhone: Bool {
        UIScreen.main.bounds.width <= 350
    }

    var body: some View {
        AppBackground {
            GeometryReader { geometry in
                let scale = scaleForScreen(size: geometry.size)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        ScreenTitleView(title: "Statistics")
                            .padding(.horizontal, 20)

                        HStack(spacing: 14) {
                            modeButton(.livestock)
                            modeButton(.sales)
                        }
                        .padding(.horizontal, 20)

                        if viewModel.mode == .sales {
                            salesContent
                        } else {
                            livestockContent
                        }

                        Color.clear
                            .frame(height: 400)
                    }
                    .padding(.bottom, 24)
                }
                .verticalBounceBasedOnSizeIfAvailable()
                .scaleEffect(scale)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
    }

    @ViewBuilder
    private var salesContent: some View {
        GlassCard {
            HStack {
                Text("Monthly revenue:")
                    .font(.custom("Unbounded-Regular", size: 17))
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.24, green: 0.25, blue: 0.36))
                    .singleLineScaled(0.55)
                Spacer()
                Text(Formatters.currency(viewModel.monthlyRevenue))
                    .font(.custom("Unbounded-Regular", size: 14))
                    .fontWeight(.light)
                    .foregroundColor(Color(red: 0.24, green: 0.25, blue: 0.36))
                    .singleLineScaled(0.55)
            }
            .padding(.vertical, 12)
        }
        .padding(.horizontal, 20)

        GlassCard {
            Text("Revenue by month")
                .font(.custom("Unbounded-Regular", size: 14))
                .fontWeight(.medium)
                .foregroundColor(Color(red: 0.24, green: 0.25, blue: 0.36))
                .singleLineScaled(0.6)
        }
        .padding(.horizontal, 20)
        
        VStack(alignment: .leading, spacing: 0) {
            if viewModel.last6MonthsRevenue.allSatisfy({ $0.value == 0 }) {
                VStack {
                    Text("No data yet")
                        .font(.custom("Unbounded-Regular", size: 18))
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 162)
                .padding(.horizontal, 20)
            } else {
                let maxValue = max(viewModel.last6MonthsRevenue.map(\.value).max() ?? 0, 1)
                let axisTop = max(200_000, ceil(maxValue / 50_000) * 50_000)
                let axisValues: [Double] = [axisTop, axisTop * 0.5, axisTop * 0.25, axisTop * 0.05, 0]
                let monthItems = viewModel.last6MonthsRevenue
                
                HStack(alignment: .bottom, spacing: 0) {
                    ZStack(alignment: .bottomLeading) {
                        VStack(spacing: 0) {
                            ForEach(0..<4, id: \.self) { index in
                                if index > 0 {
                                    Spacer()
                                }
                                Rectangle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 1)
                                if index < 3 {
                                    Spacer()
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: 96)
                        .padding(.horizontal, 12)
                        .padding(.top, 19)
                        
                        VStack(spacing: 4) {
                            HStack(alignment: .bottom, spacing: 0) {
                                ForEach(monthItems) { item in
                                    ZStack(alignment: .bottom) {
                                        Rectangle()
                                            .fill(item.isCurrentMonth ? Color(red: 224/255, green: 255/255, blue: 65/255) : Color.white)
                                            .frame(
                                                width: isCompactPhone ? 8 : 12,
                                                height: max(1, CGFloat(item.value / axisTop) * 96)
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                                }
                            }
                            .frame(height: 96)

                            HStack(alignment: .center, spacing: 0) {
                                ForEach(monthItems) { item in
                                    Text(item.monthName)
                                        .font(.custom("Unbounded-Regular", size: 14))
                                        .fontWeight(.regular)
                                        .foregroundColor(.white)
                                        .singleLineScaled(0.3)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.3)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 19)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 130)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(axisValues, id: \.self) { value in
                            Text("\(Int(value))")
                                .font(.custom("Unbounded-Regular", size: 12))
                                .fontWeight(.regular)
                                .foregroundColor(.white)
                                .singleLineScaled(0.5)
                        }
                    }
                    .frame(width: 32, height: 109, alignment: .bottom)
                    .padding(.leading, 4)
                }
                .frame(height: 130)
                .padding(.horizontal, 20)
            }
        }
        .padding(.horizontal, 20)

        GlassCard {
            HStack {
                Text("TOP buyers:")
                    .font(.custom("Unbounded-Regular", size: 17))
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.24, green: 0.25, blue: 0.36))
                    .singleLineScaled(0.55)
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    if let topBuyer = viewModel.topBuyer {
                        Text(topBuyer.name)
                            .font(.custom("Unbounded-Regular", size: 14))
                            .fontWeight(.light)
                            .foregroundColor(Color(red: 0.24, green: 0.25, blue: 0.36))
                            .singleLineScaled(0.55)
                        Text(Formatters.currency(topBuyer.total))
                            .font(.custom("Unbounded-Regular", size: 14))
                            .fontWeight(.light)
                            .foregroundColor(Color(red: 0.24, green: 0.25, blue: 0.36))
                            .singleLineScaled(0.55)
                    } else {
                        Text("No sales yet")
                            .font(.custom("Unbounded-Regular", size: 14))
                            .fontWeight(.light)
                            .foregroundColor(Color(red: 0.24, green: 0.25, blue: 0.36))
                            .singleLineScaled(0.55)
                    }
                }
            }
            .padding(.vertical, 12)
        }
        .padding(.horizontal, 20)

        buyersPieChartCard

        VStack(alignment: .center, spacing: 34) {
            HStack {
                Text("Annual revenue:")
                    .font(.custom("Unbounded-Regular", size: 17))
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .singleLineScaled(0.55)
                Spacer()
            }
                Text(Formatters.currency(viewModel.annualRevenue))
                .font(.custom("Unbounded-Regular", size: 24))
                .fontWeight(.bold)
                .foregroundColor(.black)
                .singleLineScaled(0.55)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color(red: 0.88, green: 1.0, blue: 0.25))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 20)

        GlassCard {
            HStack {
                Text("Average price per kg:")
                    .font(.custom("Unbounded-Regular", size: 14))
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.24, green: 0.25, blue: 0.36))
                    .singleLineScaled(0.55)
                Spacer()
                Text("\(Formatters.number(viewModel.averagePricePerKg)) pounds/kg")
                    .font(.custom("Unbounded-Regular", size: 15))
                    .fontWeight(.light)
                    .foregroundColor(Color(red: 0.24, green: 0.25, blue: 0.36))
                    .singleLineScaled(0.5)
            }
            .padding(.vertical, 12)
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private var buyersPieChartCard: some View {
        let buyers = viewModel.buyersDistribution
        let colors: [Color] = [
            Color(red: 0.88, green: 1.0, blue: 0.25),
            Color(red: 0.78, green: 0.92, blue: 1.0),
            Color(red: 1.0, green: 0.93, blue: 0.69)
        ]
        
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Buyers")
                    .font(.custom("Unbounded-Regular", size: 14))
                    .fontWeight(.regular)
                    .foregroundColor(.black)
                    .singleLineScaled(0.6)
                
                HStack(alignment: .top, spacing: isCompactPhone ? 12 : 20) {
                    ZStack {
                        if buyers.isEmpty {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: isCompactPhone ? 92 : 100, height: isCompactPhone ? 92 : 100)
                            Text("No data")
                                .font(.custom("Unbounded-Regular", size: 14))
                                .fontWeight(.regular)
                                .foregroundColor(.black)
                                .singleLineScaled(0.6)
                        } else {
                            let shownBuyers = Array(buyers.prefix(3))
                            let chartSize: CGFloat = isCompactPhone ? 92 : 100
                            let lineWidth: CGFloat = chartSize
                            let labelColors: [Color] = [
                                .black,
                                Color(red: 0.31, green: 0.65, blue: 0.97),
                                Color(red: 0.95, green: 0.58, blue: 0.20)
                            ]
                            let labelOffsets = pieChartLabelOffsets(for: shownBuyers, chartSize: chartSize)

                            ForEach(Array(shownBuyers.enumerated()), id: \.offset) { index, buyer in
                                let start = shownBuyers.prefix(index).reduce(0.0) { $0 + $1.percent } / 100
                                let end = start + (buyer.percent / 100)
                                let labelOffset = labelOffsets[index]
                                let labelColor = labelColors[min(index, labelColors.count - 1)]

                                Circle()
                                    .trim(from: start, to: end)
                                    .stroke(colors[index], lineWidth: lineWidth)
                                    .rotationEffect(.degrees(-90))
                                    .frame(width: chartSize, height: chartSize)
                                    .clipShape(Circle())

                                Text(String(format: "%.1f%%", buyer.percent))
                                    .font(.custom("Unbounded-Regular", size: 14))
                                    .fontWeight(.regular)
                                    .foregroundColor(labelColor)
                                    .singleLineScaled(0.5)
                                    .offset(x: labelOffset.width, y: labelOffset.height)
                                    .zIndex(1)
                            }
                        }
                    }
                    .frame(width: isCompactPhone ? 92 : 100, height: isCompactPhone ? 92 : 100)
                    
                    VStack(alignment: .leading, spacing: isCompactPhone ? 10 : 16) {
                        ForEach(Array(buyers.enumerated()), id: \.offset) { index, buyer in
                            if index < colors.count {
                                buyerLegendItem(
                                    color: colors[index],
                                    name: buyer.name,
                                    percent: String(format: "%.1f%%", buyer.percent)
                                )
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private func buyerLegendItem(color: Color, name: String, percent: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 11, height: 11)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.custom("Unbounded-Regular", size: 16))
                    .fontWeight(.regular)
                    .foregroundColor(.black)
                    .singleLineScaled(0.55)
                Text(percent)
                    .font(.custom("Unbounded-Regular", size: 14))
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .singleLineScaled(0.55)
            }
        }
    }

    @ViewBuilder
    private var livestockContent: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 4) {
                Text("Monthly Livestock Dynamics")
                    .font(.custom("Unbounded-Regular", size: 20))
                    .fontWeight(.bold)
                    .singleLineScaled(0.5)
                Text("Total fish (head count) at key days of the current month")
                    .font(.custom("Unbounded-Regular", size: 12))
                    .fontWeight(.regular)
                    .foregroundColor(Color(red: 0.24, green: 0.25, blue: 0.36))
                    .singleLineScaled(0.55)
            }
        }
        .padding(.horizontal, 20)

        if viewModel.fishes.isEmpty {
            VStack(spacing: 12) {
                Text("No data yet")
                    .font(.custom("Unbounded-Regular", size: 18))
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 210)
            .background(AppColors.card.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal, 20)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                if viewModel.livestockBars.isEmpty {
                    VStack {
                        Text("No data yet")
                            .font(.custom("Unbounded-Regular", size: 18))
                            .fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 210)
                    .padding(.horizontal, 20)
                } else {
                    let maxValue = max(viewModel.livestockBars.map(\.value).max() ?? 0, 1)
                    let axisTop = max(100, ceil(Double(maxValue) / 50) * 50)
                    let axisValues: [Double] = [axisTop, axisTop * 0.75, axisTop * 0.5, axisTop * 0.25, 0]
                    let dayItems = viewModel.livestockBars
                    
                    HStack(alignment: .bottom, spacing: 0) {
                        ZStack(alignment: .bottomLeading) {
                            VStack(spacing: 0) {
                                ForEach(0..<4, id: \.self) { index in
                                    if index > 0 {
                                        Spacer()
                                    }
                                    Rectangle()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(height: 1)
                                    if index < 3 {
                                        Spacer()
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: 180)
                            .padding(.horizontal, 12)
                            .padding(.top, 19)
                            
                            VStack(spacing: 4) {
                                HStack(alignment: .bottom, spacing: 0) {
                                    ForEach(dayItems) { item in
                                        ZStack(alignment: .bottom) {
                                            Rectangle()
                                                .fill(item.isCurrentPoint ? Color(red: 224/255, green: 255/255, blue: 65/255) : Color.white)
                                                .frame(
                                                    width: isCompactPhone ? 8 : 12,
                                                    height: max(1, CGFloat(item.value / axisTop) * 180)
                                                )
                                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                        }
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                                    }
                                }
                                .frame(height: 180)

                                HStack(alignment: .center, spacing: 0) {
                                    ForEach(dayItems) { item in
                                        Text(item.label)
                                            .font(.custom("Unbounded-Regular", size: 14))
                                            .fontWeight(.regular)
                                            .foregroundColor(.white)
                                            .singleLineScaled(0.3)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.3)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                    }
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.top, 19)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 228)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(axisValues, id: \.self) { value in
                                Text("\(Int(value))")
                                    .font(.custom("Unbounded-Regular", size: 12))
                                    .fontWeight(.regular)
                                    .foregroundColor(.white)
                                    .singleLineScaled(0.5)
                            }
                        }
                        .frame(width: 32, height: 199, alignment: .bottom)
                        .padding(.leading, 4)
                    }
                    .frame(height: 228)
                    .padding(.horizontal, 20)
                }
            }
            .padding(.horizontal, 20)
        }

        ZStack {
            Image("image - 2026-03-02T141947.470 2")
                .resizable()
                .scaledToFit()

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: isCompactPhone ? 20 : 32) {
                    Text("Type")
                        .foregroundColor(Color(red: 0.15, green: 0.0, blue: 0.46))
                        .font(.custom("Unbounded-Regular", size: 22))
                        .fontWeight(.regular)
                        .singleLineScaled(0.3)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image("Plus")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)

                    Image("Minus")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)

                    Text("Result")
                        .foregroundColor(Color(red: 0.15, green: 0.0, blue: 0.46))
                        .font(.custom("Unbounded-Regular", size: 22))
                        .fontWeight(.regular)
                        .singleLineScaled(0.3)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal, isCompactPhone ? 24 : 80)
                .padding(.top, isCompactPhone ? 32 : 60)

                Rectangle()
                    .fill(Color.black)
                    .frame(height: 1)
                    .padding(.horizontal, isCompactPhone ? 24 : 80)
                    .padding(.top, 8)

                VStack(spacing: 20) {
                    if viewModel.livestockTableRows.isEmpty {
                        Text("No data yet")
                            .font(.custom("Unbounded-Regular", size: 18))
                            .fontWeight(.medium)
                            .foregroundStyle(.black.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    }
                    
                    ForEach(viewModel.livestockTableRows, id: \.species) { row in
                    HStack(spacing: isCompactPhone ? 20 : 32) {
                        Text(row.species)
                                .font(.custom("Unbounded-Regular", size: 14))
                                .fontWeight(.light)
                                .foregroundColor(.black)
                                .singleLineScaled(0.3)
                                .frame(maxWidth: .infinity, alignment: .leading)

                        Text("+\(row.inValue)")
                                .font(.custom("Unbounded-Regular", size: 14))
                                .fontWeight(.light)
                                .foregroundColor(.black)
                                .singleLineScaled(0.3)

                        Text("-\(row.outValue)")
                                .font(.custom("Unbounded-Regular", size: 14))
                                .fontWeight(.light)
                                .foregroundColor(.black)
                                .singleLineScaled(0.3)

                        Text("+\(row.result)")
                                .font(.custom("Unbounded-Regular", size: 14))
                                .fontWeight(.light)
                                .foregroundColor(Color(red: 0.76, green: 0.88, blue: 0.10))
                                .singleLineScaled(0.3)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                        .padding(.horizontal, isCompactPhone ? 24 : 80)
                    }
                }
                .padding(.top, 20)

                Spacer()
            }
        }
        .padding(.horizontal, 24)
    }

    private func modeButton(_ mode: StatisticsViewModel.Mode) -> some View {
        Button(action: withButtonSound {
            viewModel.mode = mode
        }) {
            ZStack {
                Image(viewModel.mode == mode ? "on" : "off")
                    .resizable()
                    .scaledToFit()

            Text(mode.rawValue)
                    .font(.custom("Unbounded-Regular", size: 20))
                    .fontWeight(.bold)
                .foregroundStyle(.white)
                .singleLineScaled(0.5)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.plain)
    }

    private func monthTitle(_ month: Int) -> String {
        let symbols = Calendar.current.shortMonthSymbols
        return symbols[month - 1]
    }

    private func pieChartLabelOffsets(
        for buyers: [(name: String, total: Double, percent: Double)],
        chartSize: CGFloat
    ) -> [CGSize] {
        guard !buyers.isEmpty else { return [] }

        let minDistance = chartSize * 0.27
        let minRadius = chartSize * 0.17
        let maxRadius = chartSize * 0.37
        let radiusStep = chartSize * 0.05

        var angles: [CGFloat] = []
        var radii: [CGFloat] = []

        for (index, buyer) in buyers.enumerated() {
            let start = buyers.prefix(index).reduce(0.0) { $0 + $1.percent } / 100
            let end = start + (buyer.percent / 100)
            let mid = (start + end) / 2
            let angle = CGFloat(mid * 2 * .pi - .pi / 2)

            let sectorSize = buyer.percent / 100
            let baseRadius: CGFloat = sectorSize < 0.06 ? chartSize * 0.34 : chartSize * 0.28

            angles.append(angle)
            radii.append(baseRadius)
        }

        for _ in 0..<6 {
            var hasOverlap = false

            for i in 0..<buyers.count {
                for j in (i + 1)..<buyers.count {
                    let p1 = CGPoint(x: cos(angles[i]) * radii[i], y: sin(angles[i]) * radii[i])
                    let p2 = CGPoint(x: cos(angles[j]) * radii[j], y: sin(angles[j]) * radii[j])
                    let distance = hypot(p1.x - p2.x, p1.y - p2.y)

                    if distance < minDistance {
                        hasOverlap = true
                        radii[j] = max(minRadius, radii[j] - radiusStep)
                        radii[i] = min(maxRadius, radii[i] + radiusStep * 0.4)
                    }
                }
            }

            if !hasOverlap {
                break
            }
        }

        return zip(angles, radii).map { angle, radius in
            CGSize(width: cos(angle) * radius, height: sin(angle) * radius)
        }
    }

    private func scaleForScreen(size: CGSize) -> CGFloat {
        let requiredHeight: CGFloat = 900
        let topPadding: CGFloat = isCompactPhone ? 80 : 120
        let bottomPadding: CGFloat = isCompactPhone ? 32 : 48
        let availableHeight = size.height - topPadding - bottomPadding
        let heightScale = min(1.0, availableHeight / requiredHeight)

        let horizontalPadding: CGFloat = isCompactPhone ? 20 : 32
        let widthScale = min(1.0, (size.width - horizontalPadding) / size.width)

        let scale = min(heightScale, widthScale)
        let minScale: CGFloat = isCompactPhone ? 0.8 : 0.9
        return max(minScale, scale)
    }
}
