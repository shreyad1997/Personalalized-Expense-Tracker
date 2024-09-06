import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    // MARK: - Preview Data
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        // Add sample data for preview
        let rent = FixedExpense(context: viewContext)
        rent.category = "Rent"
        rent.amount = 2150.0

        let internet = FixedExpense(context: viewContext)
        internet.category = "Internet"
        internet.amount = 50.0

        let therapy = FixedExpense(context: viewContext)
        therapy.category = "Therapy"
        therapy.amount = 73.0

        let constantSubscription = FixedExpense(context: viewContext)
        constantSubscription.category = "Constant Subscription"
        constantSubscription.amount = 30.0

        let newExpense = VariableExpense(context: viewContext)
        newExpense.category = "Groceries"
        newExpense.amount = 100.0
        newExpense.timestamp = Date()

        let newSubcategory = MiscSubcategory(context: viewContext)
        newSubcategory.subcategory = "Travel"
        newSubcategory.amount = 50.0
        newSubcategory.expense = newExpense

        let newSummary = MonthlySummary(context: viewContext)
        newSummary.month = "August"
        newSummary.totalExpenditure = 2330.0
        newSummary.savings = 670.0
        newSummary.miscExpenditure = 50.0
        newSummary.mostSpentCategory = "Groceries"

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    // MARK: - CoreData Container
    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "PersonalExpenseTrackerModel")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }

    // MARK: - Methods for Month-based Saving and Retrieval

    // Save current month data when the month ends
    func saveCurrentMonthExpenses(month: String, totalExpenditure: Double, savings: Double, miscExpenditure: Double, mostSpentCategory: String) {
        let viewContext = container.viewContext
        let summary = MonthlySummary(context: viewContext)
        summary.month = month
        summary.totalExpenditure = totalExpenditure
        summary.savings = savings
        summary.miscExpenditure = miscExpenditure
        summary.mostSpentCategory = mostSpentCategory
        
        // Save data to Core Data
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }

    // Load past month summary data
    func loadSummaryForMonth(_ month: String) -> MonthlySummary? {
        let viewContext = container.viewContext
        let request: NSFetchRequest<MonthlySummary> = MonthlySummary.fetchRequest()
        request.predicate = NSPredicate(format: "month == %@", month)

        do {
            let result = try viewContext.fetch(request)
            return result.first
        } catch {
            let nsError = error as NSError
            print("Error fetching summary for month \(month): \(nsError.localizedDescription)")
            return nil
        }
    }

    // Check if a past month exists
    func doesPastMonthExist(month: String) -> Bool {
        let viewContext = container.viewContext
        let request: NSFetchRequest<MonthlySummary> = MonthlySummary.fetchRequest()
        request.predicate = NSPredicate(format: "month == %@", month)

        do {
            let count = try viewContext.count(for: request)
            return count > 0
        } catch {
            let nsError = error as NSError
            print("Error checking existence for month \(month): \(nsError.localizedDescription)")
            return false
        }
    }

    // Reset current month data after saving to past months
    func resetCurrentMonthData() {
        let viewContext = container.viewContext

        // Clear the current month's variable expenses
        let variableRequest: NSFetchRequest<NSFetchRequestResult> = VariableExpense.fetchRequest()
        let deleteVariableExpenses = NSBatchDeleteRequest(fetchRequest: variableRequest)

        do {
            try viewContext.execute(deleteVariableExpenses)
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Failed to reset current month data: \(nsError), \(nsError.userInfo)")
        }
    }
}
