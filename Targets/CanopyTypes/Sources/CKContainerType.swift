import CloudKit

public protocol CKContainerType {
  func fetchUserRecordID(completionHandler: @escaping @Sendable (CKRecord.ID?, Error?) -> Void)
  func accountStatus(completionHandler: @escaping @Sendable (CKAccountStatus, Error?) -> Void)
  func add(_ operation: CKOperation)
}
