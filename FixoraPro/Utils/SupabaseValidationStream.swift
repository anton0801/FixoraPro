import Foundation
import Supabase

final class SupabaseValidationStream: ValidationStream {
    
    private let client: SupabaseClient
    
    init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: "https://mbcntnwjwgnyedrbvjrx.supabase.co")!,
            supabaseKey: "sb_publishable_HrjaoQ9zTgOkyR8XQTtdQw_79bm5C-B"
        )
    }
    
    func validationSequence() -> AsyncThrowingStream<Bool, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let rows: [ValidationEntry] = try await client
                        .from("validation")
                        .select()
                        .limit(1)
                        .execute()
                        .value
                    
                    guard let row = rows.first else {
                        continuation.finish(throwing: FixoraError.validationRebuffed(detail: "no rows"))
                        return
                    }
                    
                    if !row.isValid {
                        continuation.finish(throwing: FixoraError.validationRebuffed(detail: "is_valid=false"))
                        return
                    }
                    
                    continuation.yield(true)
                    continuation.finish()
                } catch let error as FixoraError {
                    continuation.finish(throwing: error)
                } catch {
                    print("\(FixoraConstants.logBadge) Validation error: \(error)")
                    continuation.finish(throwing: FixoraError.validationRebuffed(detail: error.localizedDescription))
                }
            }
        }
    }
}

struct ValidationEntry: Codable {
    let id: Int?
    let isValid: Bool
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case isValid = "is_valid"
        case createdAt = "created_at"
    }
}
