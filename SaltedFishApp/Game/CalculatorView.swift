import SwiftUI

struct CalculatorView: View {
    @Binding var isPresented: Bool
    @State private var displayValue = "0"
    @State private var previousValue: Double = 0
    @State private var currentOperation: String? = nil
    @State private var shouldResetDisplay = false

    private let buttonGrid: [[CalcButton]] = [
        [.init("AC", .func_), .init("±", .func_), .init("%", .func_), .init("÷", .op)],
        [.init("7", .num), .init("8", .num), .init("9", .num), .init("×", .op)],
        [.init("4", .num), .init("5", .num), .init("6", .num), .init("−", .op)],
        [.init("1", .num), .init("2", .num), .init("3", .num), .init("+", .op)],
        [.init("0", .num, span: 2), .init(".", .num), .init("=", .op)],
    ]

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // Display
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(displayValue)
                            .font(.system(size: displayFontSize, weight: .light, design: .default))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.4)
                            .padding(.trailing, 24)
                            .padding(.bottom, 12)
                    }
                }
                .frame(height: geo.size.height * 0.22)

                // Button grid
                let cellW = geo.size.width / 4
                let cellH = (geo.size.height * 0.78) / 5

                VStack(spacing: 1) {
                    ForEach(0..<5, id: \.self) { row in
                        HStack(spacing: 1) {
                            ForEach(buttonGrid[row], id: \.label) { btn in
                                CalcButtonView(button: btn, width: cellW * CGFloat(btn.span) - 1, height: cellH - 1) {
                                    handleInput(btn.label)
                                }
                            }
                        }
                    }
                }
            }
            .background(Color(red: 0.11, green: 0.11, blue: 0.118))
        }
        .ignoresSafeArea()
    }

    private var displayFontSize: CGFloat {
        if displayValue.count > 12 { return 36 }
        if displayValue.count > 9 { return 48 }
        return 64
    }

    private func handleInput(_ label: String) {
        switch label {
        case "AC":
            displayValue = "0"
            previousValue = 0
            currentOperation = nil
            shouldResetDisplay = false
        case "±":
            if let val = Double(displayValue) {
                displayValue = formatNumber(-val)
            }
        case "%":
            if let val = Double(displayValue) {
                displayValue = formatNumber(val / 100)
            }
        case "+", "−", "×", "÷":
            if let val = Double(displayValue) {
                if currentOperation != nil && !shouldResetDisplay {
                    performCalculation()
                } else {
                    previousValue = val
                }
            }
            currentOperation = label
            shouldResetDisplay = true
        case "=":
            performCalculation()
            currentOperation = nil
            // Return to game on =
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPresented = false
            }
        case ".":
            if shouldResetDisplay {
                displayValue = "0."
                shouldResetDisplay = false
            } else if !displayValue.contains(".") {
                displayValue += "."
            }
        default:
            // Number
            if shouldResetDisplay || displayValue == "0" {
                displayValue = label
                shouldResetDisplay = false
            } else {
                if displayValue.count < 15 {
                    displayValue += label
                }
            }
        }
    }

    private func performCalculation() {
        guard let op = currentOperation, let current = Double(displayValue) else { return }
        var result: Double
        switch op {
        case "+": result = previousValue + current
        case "−": result = previousValue - current
        case "×": result = previousValue * current
        case "÷": result = current != 0 ? previousValue / current : 0
        default: return
        }
        displayValue = formatNumber(result)
        previousValue = result
        shouldResetDisplay = true
    }

    private func formatNumber(_ value: Double) -> String {
        if value == floor(value) && abs(value) < 1e15 {
            return String(format: "%.0f", value)
        }
        let str = String(format: "%.8f", value)
        // Trim trailing zeros
        var trimmed = str
        while trimmed.hasSuffix("0") { trimmed = String(trimmed.dropLast()) }
        if trimmed.hasSuffix(".") { trimmed = String(trimmed.dropLast()) }
        return trimmed
    }
}

// MARK: - Calc Button Model
enum CalcButtonCategory {
    case num, op, func_
}

struct CalcButton: Identifiable {
    let label: String
    let category: CalcButtonCategory
    var span: Int = 1
    var id: String { label }

    init(_ label: String, _ category: CalcButtonCategory, span: Int = 1) {
        self.label = label
        self.category = category
        self.span = span
    }
}

struct CalcButtonView: View {
    let button: CalcButton
    let width: CGFloat
    let height: CGFloat
    let action: () -> Void

    var bgColor: Color {
        switch button.category {
        case .op: return Color(red: 1, green: 0.58, blue: 0)
        case .func_: return Color(red: 0.65, green: 0.65, blue: 0.65)
        case .num: return Color(red: 0.2, green: 0.2, blue: 0.2)
        }
    }

    var textColor: Color {
        switch button.category {
        case .func_: return .black
        default: return .white
        }
    }

    var body: some View {
        Button(action: action) {
            Text(button.label)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(textColor)
                .frame(width: width, height: height)
                .background(bgColor)
        }
    }
}
