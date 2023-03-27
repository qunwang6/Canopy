import CloudKit

/// CKFetchRecordsOperation successful result
public struct FetchRecordsResult {
  /// Records that were found.
  public let foundRecords: [CKRecord]
  
  /// Records that were not found based on the ID, but the operation was otherwise successful.
  public let notFoundRecordIDs: [CKRecord.ID]
  
  public init(foundRecords: [CKRecord], notFoundRecordIDs: [CKRecord.ID]) {
    self.foundRecords = foundRecords
    self.notFoundRecordIDs = notFoundRecordIDs
  }
}
