import Nimble
@testable import Sentry
import SentryTestUtils
import XCTest

final class EncodeMetricTests: XCTestCase {

    func testEncodeCounterMetricWithoutTags() {
        let counterMetric = CounterMetric(key: "app.start", unit: .none, tags: [:])
        counterMetric.add(value: 1.0)

        let data = encodeToStatsd(flushableBuckets: [12_345: [counterMetric]])

        expect(data.decodeStatsd()) == "app.start@:1.0|c|T12345\n"
    }

    func testEncodeCounterMetricWithFractionalPart() {
        let counterMetric = CounterMetric(key: "app.start", unit: MeasurementUnitDuration.second, tags: [:])
        counterMetric.add(value: 1.123456)

        let data = encodeToStatsd(flushableBuckets: [10_234: [counterMetric]])

        expect(data.decodeStatsd()) == "app.start@second:1.123456|c|T10234\n"
    }

    func testEncodeCounterMetricWithOneTag() {
        let counterMetric = CounterMetric(key: "app.start", unit: MeasurementUnitDuration.second, tags: ["key": "value"])
        counterMetric.add(value: 10.1)

        let data = encodeToStatsd(flushableBuckets: [10_234: [counterMetric]])

        expect(data.decodeStatsd()) == "app.start@second:10.1|c|#key:value|T10234\n"
    }

    func testEncodeCounterMetricWithTwoTags() {
        let counterMetric = CounterMetric(key: "app.start", unit: MeasurementUnitDuration.second, tags: ["key1": "value1", "key2": "value2"])
        counterMetric.add(value: 10.1)

        let data = encodeToStatsd(flushableBuckets: [10_234: [counterMetric]])

        expect(data.decodeStatsd()).to(beginWith("app.start@second:10.1|c|"))
        expect(data.decodeStatsd()).to(endWith("|T10234\n"))
        expect(data.decodeStatsd()).to(contain("key1:value1"))
        expect(data.decodeStatsd()).to(contain("key2:value2"))
    }

    func testEncodeCounterMetricWithKeyToSanitize() {
        let counterMetric = CounterMetric(key: "abyzABYZ09_/.-!@a#$Äa", unit: MeasurementUnitDuration.second, tags: [:])
        counterMetric.add(value: 10.1)

        let data = encodeToStatsd(flushableBuckets: [10_234: [counterMetric]])

        expect(data.decodeStatsd()) == "abyzABYZ09_/.-_a_a@second:10.1|c|T10234\n"
    }

    func testEncodeCounterMetricWithTagKeyToSanitize() {
        let counterMetric = CounterMetric(key: "app.start", unit: MeasurementUnitDuration.second, tags: ["abyzABYZ09_/.-!@a#$Äa": "value"])
        counterMetric.add(value: 10.1)

        let data = encodeToStatsd(flushableBuckets: [10_234: [counterMetric]])

        expect(data.decodeStatsd()) == "app.start@second:10.1|c|#abyzABYZ09_/.-_a_a:value|T10234\n"
    }

    func testEncodeCounterMetricWithTagValueToSanitize() {
        let counterMetric = CounterMetric(key: "app.start", unit: MeasurementUnitDuration.second, tags: ["key": #"azAZ1 _:/@.{}[]$\%^&a*"#])

        counterMetric.add(value: 10.1)

        let data = encodeToStatsd(flushableBuckets: [10_234: [counterMetric]])

        expect(data.decodeStatsd()) == "app.start@second:10.1|c|#key:azAZ1 _:/@.{}[]$a|T10234\n"
    }
}

private extension Data {
    func decodeStatsd() -> String {
        return String(data: self, encoding: .utf8) ?? ""
    }
}