import XCTest
@testable import JsonLensCore

final class JSONDetectorTests: XCTestCase {
    func testDetectsStrictJSON() {
        let document = JSONDetector.detect(#"{"name":"Ada","skills":["swift","json"]}"#)

        XCTAssertEqual(document?.format, .strictJSON)
        XCTAssertEqual(document?.root.childCount, 2)
    }

    func testDetectsJSONC() {
        let document = JSONDetector.detect(
            """
            {
              // developer
              "name": "Ada",
              "enabled": true,
            }
            """
        )

        XCTAssertEqual(document?.format, .jsonc)
        XCTAssertEqual(document?.root.childCount, 2)
    }

    func testDetectsJSONCWithFullWidthCommaOutsideString() {
        let document = JSONDetector.detect(
            """
            {
              "decision": "BLOCK",          // final decision
              "hit_labels": [
                {
                  "label_code": "fund_out",
                  "snippet": "马上赔偿您20元",
                  "reply": ""
                },
                {
                  "label_code": "over_assurance",
                  "snippet": ""，
                  "reply": ""
                }
              ]
            }
            """
        )

        XCTAssertEqual(document?.format, .jsonc)
        XCTAssertEqual(document?.root.childCount, 2)
    }

    func testDetectsJSONLines() {
        let document = JSONDetector.detect(
            """
            {"id":1}
            {"id":2}
            """
        )

        XCTAssertEqual(document?.format, .jsonLines)
        XCTAssertEqual(document?.root.childCount, 2)
    }

    func testDetectsEmbeddedCodeFence() {
        let document = JSONDetector.detect(
            """
            response:
            ```json
            {"ok": true}
            ```
            """
        )

        XCTAssertEqual(document?.format, .embeddedJSON)
        XCTAssertEqual(document?.root.childCount, 1)
    }

    func testDetectsJSONLinesInsideCodeFence() {
        let document = JSONDetector.detect(
            """
            ```jsonl
            {"id":1}
            {"id":2}
            ```
            """
        )

        XCTAssertEqual(document?.format, .jsonLines)
        XCTAssertEqual(document?.root.childCount, 2)
    }

    func testDetectsBase64JSON() {
        let document = JSONDetector.detect("eyJvayI6dHJ1ZX0=")

        XCTAssertEqual(document?.format, .base64JSON)
        XCTAssertEqual(document?.root.childCount, 1)
    }

    func testRejectsPlainText() {
        XCTAssertNil(JSONDetector.detect("hello world"))
    }
}
