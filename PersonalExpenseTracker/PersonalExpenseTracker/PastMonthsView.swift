import SwiftUI
import CoreData

struct PastMonthsView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        entity: VariableExpense.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \VariableExpense.timestamp, ascending: true)]
    ) private var variableExpenses: FetchedResults<VariableExpense>

    @FetchRequest(
        entity: MiscSubcategory.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \MiscSubcategory.subcategory, ascending: true)]
    ) private var miscSubcategories: FetchedResults<MiscSubcategory>

    @FetchRequest(
        entity: MonthlySummary.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \MonthlySummary.month, ascending: true)]
    ) private var monthlySummaries: FetchedResults<MonthlySummary>

    @State private var selectedMonth: String = ""
    @State private var totalExpenditure: Double = 0.0
    @State private var savings: Double = 0.0
    @State private var mostSpentCategory: String = ""

    var body: some View {
        VStack {
            Picker("Select Month", selection: $selectedMonth) {
                ForEach(monthlySummaries.map { $0.month }, id: \.self) { month in
                    Text(month ?? "").tag(month ?? "")
                }
            }
            .pickerStyle(MenuPickerStyle())
            .onChange(of: selectedMonth) { newValue in
                loadMonthlyData(for: newValue)
            }

            VStack(alignment: .leading) {
                // Display totals for the selected past month
                Text("Total Expenditure: $\(totalExpenditure, specifier: "%.2f")")
                Text("Savings: $\(savings, specifier: "%.2f")")
                Text("Most Spent Category: \(mostSpentCategory)")
            }
            .padding()

            // Display summary of the fixed expenditures
            DisclosureGroup("Fixed Expenditure") {
                Text("Rent: $2155.00")
                Text("Therapy: $95.00")
                Text("Internet: $50.00")
            }
            .padding()

            // Display category totals
            DisclosureGroup("Category Totals") {
                Text("Groceries: $\(calculateCategoryTotal(category: "Groceries"), specifier: "%.2f")")
                Text("Electric: $\(calculateCategoryTotal(category: "Electric"), specifier: "%.2f")")
                Text("Workout: $\(calculateCategoryTotal(category: "Workout"), specifier: "%.2f")")
                Text("Misc: $\(calculateCategoryTotal(category: "Misc"), specifier: "%.2f")")

                // Display subcategories of Misc
                VStack(alignment: .leading, spacing: 5) {
                    Text("  Subcategories:")
                    Text("  Travel: $\(calculateMiscSubcategoryTotal(subcategory: "Travel"), specifier: "%.2f")")
                    Text("  Food Outside: $\(calculateMiscSubcategoryTotal(subcategory: "Food Outside"), specifier: "%.2f")")
                    Text("  Shopping: $\(calculateMiscSubcategoryTotal(subcategory: "Shopping"), specifier: "%.2f")")
                    Text("  Maintenance: $\(calculateMiscSubcategoryTotal(subcategory: "Maintenance"), specifier: "%.2f")")
                    Text("  Experience: $\(calculateMiscSubcategoryTotal(subcategory: "Experience"), specifier: "%.2f")")
                    
                    // Re-add "New Subscription" subcategory
                    Text("  New Subscription: $\(calculateMiscSubcategoryTotal(subcategory: "New Subscription"), specifier: "%.2f")")
                    
                    // Display fixed subscription as part of Misc
                    Text("  Fixed Subscriptions: $\(calculateFixedSubscriptions(), specifier: "%.2f")")
                }
            }
            .padding()

            // List to display Misc subcategories for the selected month
            List {
                ForEach(variableExpenses.filter { $0.category == "Misc" && isPastMonth($0.timestamp ?? Date()) }, id: \.self) { expense in
                    VStack(alignment: .leading) {
                        Text("Amount: $\(expense.amount, specifier: "%.2f")")
                        if let miscExpense = miscSubcategories.first(where: { $0.expense == expense }) {
                            Text("Subcategory: \(miscExpense.subcategory ?? "Unknown")")
                        }
                        Text("Date: \(expense.timestamp ?? Date(), formatter: dateFormatter)")
                    }
                }
            }
        }
        .navigationTitle("Past Months Tracker")
    }

    private func loadMonthlyData(for month: String) {
        guard let summary = monthlySummaries.first(where: { $0.month == month }) else {
            totalExpenditure = 0.0
            savings = 0.0
            mostSpentCategory = ""
            return
        }
        totalExpenditure = summary.totalExpenditure
        savings = summary.savings
        mostSpentCategory = summary.mostSpentCategory ?? ""
    }

    private func calculateCategoryTotal(category: String) -> Double {
        return variableExpenses.filter { $0.category == category && isPastMonth($0.timestamp ?? Date()) }.reduce(0) { $0 + $1.amount }
    }

    private func calculateMiscSubcategoryTotal(subcategory: String) -> Double {
        return miscSubcategories.filter { $0.subcategory == subcategory && isPastMonth($0.expense?.timestamp ?? Date()) }.reduce(0) { $0 + $1.amount }
    }

    private func calculateFixedSubscriptions() -> Double {
        let fixedSubscriptionAmount = 30.0 // Fixed subscription amount for Hulu, Spotify, etc.
        let newSubscriptionAmount = calculateMiscSubcategoryTotal(subcategory: "New Subscription")
        return fixedSubscriptionAmount + newSubscriptionAmount
    }

    private func isPastMonth(_ date: Date) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        return dateFormatter.string(from: date) == selectedMonth
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}
