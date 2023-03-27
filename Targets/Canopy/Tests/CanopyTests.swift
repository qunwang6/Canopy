@testable import Canopy
import CanopyTestTools
import CloudKit
import XCTest

final class CanopyTests: XCTestCase {
  func test_init_with_default_settings() async {
    let _ = Canopy(
      container: MockCKContainer(),
      publicCloudDatabase: MockDatabase(),
      privateCloudDatabase: MockDatabase(),
      sharedCloudDatabase: MockDatabase(),
      tokenStore: TestTokenStore()
    )
  }
  
  func test_settings_provider_uses_modified_value() async {
    let changedRecordID = CKRecord.ID(recordName: "SomeRecordName")
    let changedRecord = CKRecord(recordType: "TestRecord", recordID: changedRecordID)
    
    struct ModifiableSettings: CanopySettingsType {
      var modifyRecordsBehavior: RequestBehavior = .regular(nil)
      var fetchZoneChangesBehavior: RequestBehavior = .regular(nil)
      var fetchDatabaseChangesBehavior: RequestBehavior = .regular(nil)
      var autoBatchTooLargeModifyOperations: Bool = true
      var autoRetryForRetriableErrors: Bool = true
    }
    
    var modifiableSettings = ModifiableSettings()
    
    let canopy = Canopy(
      container: MockCKContainer(),
      publicCloudDatabase: MockDatabase(),
      privateCloudDatabase: MockDatabase(
        operationResults: [
          .modify(
            .init(
              savedRecordResults: [
                .init(recordID: changedRecordID, result: .success(changedRecord))
              ],
              deletedRecordIDResults: [],
              modifyResult: .init(result: .success(()))
            )
          ),
          .modify(
            .init(
              savedRecordResults: [],
              deletedRecordIDResults: [],
              modifyResult: .init(result: .success(()))
            )
          )
        ]
      ),
      sharedCloudDatabase: MockDatabase(),
      settings: { modifiableSettings },
      tokenStore: TestTokenStore()
    )
    
    let api = await canopy.databaseAPI(usingDatabaseScope: .private)

    // First request will succeed.
    let result1 = try! await api.modifyRecords(saving: [changedRecord], deleting: nil, perRecordProgressBlock: nil, qualityOfService: .default).get()
    XCTAssertTrue(result1.savedRecords.count == 1)
    XCTAssertTrue(result1.savedRecords[0].isEqualToRecord(changedRecord))
    
    // Second request will fail after modifying the settings.
    modifiableSettings.modifyRecordsBehavior = .simulatedFail(nil)
    
    do {
      let _ = try await api.modifyRecords(saving: [changedRecord], deleting: nil, perRecordProgressBlock: nil, qualityOfService: .default).get()
    } catch {
      XCTAssertTrue(error is CKRecordError)
    }
  }
  
  func test_returns_same_api_instances() async {
    let canopy = Canopy(
      container: MockCKContainer(),
      publicCloudDatabase: MockDatabase(),
      privateCloudDatabase: MockDatabase(),
      sharedCloudDatabase: MockDatabase()
    )
    
    let privateApi1 = await canopy.databaseAPI(usingDatabaseScope: .private) as! CKDatabaseAPI
    let privateApi2 = await canopy.databaseAPI(usingDatabaseScope: .private) as! CKDatabaseAPI
    XCTAssertTrue(privateApi1 === privateApi2)

    let publicApi1 = await canopy.databaseAPI(usingDatabaseScope: .public) as! CKDatabaseAPI
    let publicApi2 = await canopy.databaseAPI(usingDatabaseScope: .public) as! CKDatabaseAPI
    XCTAssertTrue(publicApi1 === publicApi2)

    let sharedApi1 = await canopy.databaseAPI(usingDatabaseScope: .shared) as! CKDatabaseAPI
    let sharedApi2 = await canopy.databaseAPI(usingDatabaseScope: .shared) as! CKDatabaseAPI
    XCTAssertTrue(sharedApi1 === sharedApi2)

    let containerApi1 = await canopy.containerAPI() as! CKContainerAPI
    let containerApi2 = await canopy.containerAPI() as! CKContainerAPI
    
    XCTAssertTrue(containerApi1 === containerApi2)
  }
}
