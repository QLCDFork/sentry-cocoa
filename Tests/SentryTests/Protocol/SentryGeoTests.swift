import XCTest

class SentryGeoTests: XCTestCase {
    func testSerializationWithAllProperties() throws {
        let geo = try XCTUnwrap(TestData.geo.copy() as? Geo)
        let actual = geo.serialize()

        // Changing the original doesn't modify the serialized
        geo.city = ""
        geo.countryCode = ""
        geo.region = ""
        
        XCTAssertEqual(TestData.geo.city, actual["city"] as? String)
        XCTAssertEqual(TestData.geo.countryCode, actual["country_code"] as? String)
        XCTAssertEqual(TestData.geo.region, actual["region"] as? String)
    }
    
    func testHash() {
        XCTAssertEqual(TestData.geo.hash(), TestData.geo.hash())
        
        let geo2 = TestData.geo
        geo2.city = "Berlin"
        XCTAssertNotEqual(TestData.geo.hash(), geo2.hash())
    }
    
    func testIsEqualToSelf() {
        XCTAssertEqual(TestData.geo, TestData.geo)
        XCTAssertTrue(TestData.geo.isEqual(to: TestData.geo))
    }
    
    func testIsNotEqualToOtherClass() {
        XCTAssertFalse(TestData.geo.isEqual(1))
    }
    
    func testIsEqualToCopy() {
        XCTAssertEqual(TestData.geo, try XCTUnwrap(TestData.geo.copy() as? Geo))
    }
    
    func testNotIsEqual() throws {
        try testIsNotEqual { geo in geo.city = "" }
        try testIsNotEqual { geo in geo.countryCode = "" }
        try testIsNotEqual { geo in geo.region = "" }
    }
    
    func testIsNotEqual(block: (Geo) -> Void) throws {
        let geo = try XCTUnwrap(TestData.geo.copy() as? Geo)
        block(geo)
        XCTAssertNotEqual(TestData.geo, geo)
    }
    
    func testCopyWithZone_CopiesDeepCopy() throws {
        let geo = TestData.geo
        let copiedGeo = try XCTUnwrap(geo.copy() as? Geo)
        
        // Modifying the original does not change the copy
        geo.city = ""
        geo.countryCode = ""
        geo.region = ""
        
        XCTAssertEqual(TestData.geo, copiedGeo)
    }
}
