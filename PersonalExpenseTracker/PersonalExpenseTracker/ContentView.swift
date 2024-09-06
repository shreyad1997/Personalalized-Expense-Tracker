import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        entity: VariableExpense.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \VariableExpense.timestamp, ascending: true)]
    ) private var variableExpenses: FetchedResults<VariableExpense>

    @FetchRequest(
        entity: MiscSubcategory.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \MiscSubcategory.subcategory, ascending: true)]
    ) private var miscSubcategories: FetchedResults<MiscSubcategory>

    @State private var groceries: String = ""
    @State private var miscExpense: String = ""
    @State private var miscCategory: String = "Travel"
    @State private var electric: String = ""
    @State private var workout: String = ""
    @State private var currentMonth: String = ""
    @State private var totalExpenditure: Double = 0.0
    @State private var savings: Double = 0.0
    @State private var mostSpentCategory: String = ""
    @State private var showFixedExpenditures: Bool = false
    @State private var showCategoryTotals: Bool = false

    // Fixed expense values
    @State private var rent: Double = 2155
    @State private var therapy: Double = 95
    @State private var internet: Double = 50
    @State private var fixedSubscription: Double = 30 // Fixed amount for subscription
    @State private var budgetLimit: Double = 3000 // Monthly budget limit

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("Add Expenses for \(currentMonth)")) {
                        TextField("Groceries", text: $groceries)
                        Button("Add Groceries") {
                            addVariableExpense(category: "Groceries", amount: Double(groceries) ?? 0)
                            groceries = ""
                        }

                        TextField("Misc Expense", text: $miscExpense)
                        Picker("Misc Category", selection: $miscCategory) {
                            Text("Travel").tag("Travel")
                            Text("Food Outside").tag("Food Outside")
                            Text("Shopping").tag("Shopping")
                            Text("Maintenance").tag("Maintenance")
                            Text("Experience").tag("Experience")
                            Text("New Subscription").tag("New Subscription")
                        }
                        .pickerStyle(MenuPickerStyle())
                        Button("Add Misc Expense") {
                            addMiscExpense(subcategory: miscCategory, amount: Double(miscExpense) ?? 0)
                            miscExpense = ""
                            miscCategory = "Travel"
                        }

                        TextField("Electric", text: $electric)
                        Button("Add Electric") {
                            addVariableExpense(category: "Electric", amount: Double(electric) ?? 0)
                            electric = ""
                        }

                        TextField("Workout", text: $workout)
                        Button("Add Workout") {
                            addVariableExpense(category: "Workout", amount: Double(workout) ?? 0)
                            workout = ""
                        }
                    }

                    Button("Calculate Total") {
                        calculateTotal()
                    }

                    DisclosureGroup("Fixed Expenditure", isExpanded: $showFixedExpenditures) {
                        VStack(alignment: .leading) {
                            Text("Rent: $\(rent, specifier: "%.2f")")
                            Text("Therapy: $\(therapy, specifier: "%.2f")")
                            Text("Internet: $\(internet, specifier: "%.2f")")
                            Text("Fixed Subscriptions: $\(fixedSubscription, specifier: "%.2f")") // Display Fixed Subscription
                        }
                    }

                    DisclosureGroup("Category Totals", isExpanded: $showCategoryTotals) {
                        VStack(alignment: .leading) {
                            Text("Groceries: $\(calculateCategoryTotal(category: "Groceries"), specifier: "%.2f")")
                            Text("Electric: $\(calculateCategoryTotal(category: "Electric"), specifier: "%.2f")")
                            Text("Workout: $\(calculateCategoryTotal(category: "Workout"), specifier: "%.2f")")
                            Text("Misc: $\(calculateCategoryTotal(category: "Misc"), specifier: "%.2f")")
                        }

                        // Misc Subcategory breakdown including New Subscription
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Misc Subcategories:")
                            Text("Travel: $\(calculateMiscSubcategoryTotal(subcategory: "Travel"), specifier: "%.2f")")
                            Text("Food Outside: $\(calculateMiscSubcategoryTotal(subcategory: "Food Outside"), specifier: "%.2f")")
                            Text("Shopping: $\(calculateMiscSubcategoryTotal(subcategory: "Shopping"), specifier: "%.2f")")
                            Text("Maintenance: $\(calculateMiscSubcategoryTotal(subcategory: "Maintenance"), specifier: "%.2f")")
                            Text("Experience: $\(calculateMiscSubcategoryTotal(subcategory: "Experience"), specifier: "%.2f")")
                            Text("New Subscription: $\(fixedSubscription + calculateMiscSubcategoryTotal(subcategory: "New Subscription"), specifier: "%.2f")") // Fixed and additional new subscriptions
                        }
                    }
                }

                List {
                    ForEach(variableExpenses.filter { isCurrentMonth($0.timestamp ?? Date()) }, id: \.self) { expense in
                        VStack(alignment: .leading) {
                            Text("Category: \(expense.category ?? "Unknown Category")")
                            Text("Amount: $\(expense.amount, specifier: "%.2f")")

                            // If it's a Misc expense, show the corresponding subcategory
                            if let category = expense.category, category == "Misc" {
                                if let miscExpense = miscSubcategories.first(where: { $0.expense == expense }) {
                                    Text("Subcategory: \(miscExpense.subcategory ?? "Unknown Subcategory")")
                                }
                            }

                            Text("Date: \(expense.timestamp ?? Date(), formatter: dateFormatter)")
                        }
                    }
                    .onDelete(perform: deleteExpenses)
                }
                .frame(maxHeight: 200) // Limit the height of the list

                Text("Savings: $\(savings, specifier: "%.2f")")
                Text("Most Spent Category: \(mostSpentCategory)")

                NavigationLink("View Past Months", destination: PastMonthsView())
            }
            .navigationTitle("Current Month Tracker")
            .onAppear {
                setDefaultMonth()
            }
        }
    }

    private func setDefaultMonth() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        currentMonth = dateFormatter.string(from: Date())
        loadData(for: currentMonth) // Load the current month's data by default
    }

    private func isCurrentMonth(_ date: Date) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        return dateFormatter.string(from: date) == currentMonth
    }

    private func addVariableExpense(category: String, amount: Double) {
        let newExpense = VariableExpense(context: viewContext)
        newExpense.category = category
        newExpense.amount = amount
        newExpense.timestamp = Date()
        saveContext()
        loadData(for: currentMonth) // Recalculate after adding
    }

    private func addMiscExpense(subcategory: String, amount: Double) {
        let newExpense = VariableExpense(context: viewContext)
        newExpense.category = "Misc"
        newExpense.amount = amount
        newExpense.timestamp = Date()

        let newSubcategory = MiscSubcategory(context: viewContext)
        newSubcategory.subcategory = subcategory
        newSubcategory.amount = amount
        newSubcategory.expense = newExpense

        saveContext()
        loadData(for: currentMonth) // Recalculate after adding
    }

    private func calculateTotal() {
        let fixedExpenseAmount = rent + therapy + internet + fixedSubscription // Include Fixed Subscription in total
        let variableExpenseAmount = variableExpenses.reduce(0) { $0 + $1.amount }
        totalExpenditure = fixedExpenseAmount + variableExpenseAmount

        savings = budgetLimit - totalExpenditure

        if savings < 2000 {
            print("Failing to meet budget: Only $\(String(format: "%.2f", savings)) saved")
        } else {
            print("You saved $\(String(format: "%.2f", savings)) this month!")
        }

        calculateMostSpentCategory()
    }

    private func calculateMostSpentCategory() {
        let groupedExpenses = Dictionary(grouping: variableExpenses, by: { $0.category ?? "Unknown" })
        let mostSpentCategoryEntry = groupedExpenses.max {
            $0.value.reduce(0) { $0 + $1.amount } < $1.value.reduce(0) { $0 + $1.amount }
        }

        if let mostSpentCategoryEntry = mostSpentCategoryEntry {
            mostSpentCategory = mostSpentCategoryEntry.key
        }
    }

    private func calculateCategoryTotal(category: String) -> Double {
        return variableExpenses.filter { $0.category == category && isCurrentMonth($0.timestamp ?? Date()) }.reduce(0) { $0 + $1.amount }
    }

    private func calculateMiscSubcategoryTotal(subcategory: String) -> Double {
        return miscSubcategories.filter { $0.subcategory == subcategory && isCurrentMonth($0.expense?.timestamp ?? Date()) }.reduce(0) { $0 + $1.amount }
    }

    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }

    private func loadData(for month: String) {
        // Implement logic to load data for the current or selected month.
    }

    private func deleteExpenses(offsets: IndexSet) {
        offsets.map { variableExpenses[$0] }.forEach(viewContext.delete)
        saveContext()
        loadData(for: currentMonth) // Recalculate after deleting an expense
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
