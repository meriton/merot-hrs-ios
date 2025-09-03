import Foundation
import AppIntents

@available(iOS 16.0, *)
struct MerotHRSAppIntent: AppIntent {
    static var title: LocalizedStringResource = "MEROT HRS"
    static var description = IntentDescription("Interact with MEROT HRS")
    
    func perform() async throws -> some IntentResult {
        return .result()
    }
}