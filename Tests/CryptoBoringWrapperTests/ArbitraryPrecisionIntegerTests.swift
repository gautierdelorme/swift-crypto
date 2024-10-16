//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftCrypto open source project
//
// Copyright (c) 2019 Apple Inc. and the SwiftCrypto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.md for the list of SwiftCrypto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
#if CRYPTO_IN_SWIFTPM && !CRYPTO_IN_SWIFTPM_FORCE_BUILD_API
#else
@testable import CryptoBoringWrapper
import XCTest

final class ArbitraryPrecisionIntegerTests: XCTestCase {
    func testSimpleArithmetic() {
        let six = ArbitraryPrecisionInteger(6)
        let twelve = ArbitraryPrecisionInteger(12)
        let result = six * twelve

        XCTAssertEqual(result, 72)
    }

    func testPositivity() {
        let six = ArbitraryPrecisionInteger(6)
        let negativeOne = ArbitraryPrecisionInteger(-1)
        XCTAssertFalse(negativeOne._positive)

        XCTAssertFalse((six * negativeOne)._positive)
        XCTAssertTrue((six * negativeOne * negativeOne)._positive)
    }

    func testSquaring() {
        let six = ArbitraryPrecisionInteger(6)
        XCTAssertEqual(six.squared(), 36)
        XCTAssertEqual(six, 6)
    }

    func testPositiveSquareRoot() {
        XCTAssertNoThrow(XCTAssertEqual(try ArbitraryPrecisionInteger(144).positiveSquareRoot(), 12))
        XCTAssertThrowsError(try ArbitraryPrecisionInteger(101).positiveSquareRoot()) { error in
            guard case .some(.underlyingCoreCryptoError) = error as? CryptoBoringWrapperError else {
                XCTFail("Unexpected error: \(error)")
                return
            }
        }
    }

    func testSimpleRepresentation() {
        let six = ArbitraryPrecisionInteger(60)
        XCTAssertEqual(six.debugDescription, "3c")
    }

    func testMoreArithmetic() {
        let fifteen = ArbitraryPrecisionInteger(15) + .zero
        let sixteen = fifteen + 1

        var sixteenTwo = sixteen
        sixteenTwo += 4
        let ten = sixteenTwo - 10
        sixteenTwo -= 4

        XCTAssertEqual(fifteen, 15)
        XCTAssertEqual(sixteen, 16)
        XCTAssertEqual(sixteenTwo, 16)
        XCTAssertEqual(ten, 10)
    }

    func testNegationAndAbsoluteValues() {
        let oneOhFour = ArbitraryPrecisionInteger(104)
        var copy = oneOhFour
        copy.negate()

        XCTAssertEqual(copy, ArbitraryPrecisionInteger(-104))
        XCTAssertEqual(copy.magnitude, oneOhFour.magnitude)
        XCTAssertEqual(copy.magnitude, oneOhFour)
    }

    func testAllInPlaceArithmeticCoWs() {
        let base = ArbitraryPrecisionInteger(5)
        var adder = base
        var subber = base
        var timeser = base

        adder += base
        subber -= base
        timeser *= base

        XCTAssertEqual(base, 5)
        XCTAssertEqual(adder, 10)
        XCTAssertEqual(subber, 0)
        XCTAssertEqual(timeser, 25)
    }

    func testComparable() {
        let one = ArbitraryPrecisionInteger(1)
        let two = ArbitraryPrecisionInteger(2)

        // Not using XCTAssertLessThan and friends
        // because we want to test these operators specifically.
        XCTAssertTrue(one < two)
        XCTAssertTrue(one <= two)
        XCTAssertFalse(one < one)
        XCTAssertTrue(one <= one)
        XCTAssertTrue(two > one)
        XCTAssertTrue(two >= one)
        XCTAssertFalse(two > two)
        XCTAssertTrue(two >= two)
    }

    func testGCD() {
        XCTAssertEqual(try ArbitraryPrecisionInteger.gcd(+9, +13), 1)
        XCTAssertEqual(try ArbitraryPrecisionInteger.gcd(+9, -13), 1)
        XCTAssertEqual(try ArbitraryPrecisionInteger.gcd(-9, +13), 1)
        XCTAssertEqual(try ArbitraryPrecisionInteger.gcd(-9, -13), 1)

        XCTAssertEqual(try ArbitraryPrecisionInteger.gcd(+13, +9), 1)
        XCTAssertEqual(try ArbitraryPrecisionInteger.gcd(+13, -9), 1)
        XCTAssertEqual(try ArbitraryPrecisionInteger.gcd(-13, +9), 1)
        XCTAssertEqual(try ArbitraryPrecisionInteger.gcd(-13, -9), 1)

        XCTAssertEqual(try ArbitraryPrecisionInteger.gcd(+9, +12), 3)
        XCTAssertEqual(try ArbitraryPrecisionInteger.gcd(+9, -12), 3)
        XCTAssertEqual(try ArbitraryPrecisionInteger.gcd(-9, +12), 3)
        XCTAssertEqual(try ArbitraryPrecisionInteger.gcd(-9, -12), 3)

        XCTAssertEqual(try ArbitraryPrecisionInteger.gcd(+12, +9), 3)
        XCTAssertEqual(try ArbitraryPrecisionInteger.gcd(+12, -9), 3)
        XCTAssertEqual(try ArbitraryPrecisionInteger.gcd(-12, +9), 3)
        XCTAssertEqual(try ArbitraryPrecisionInteger.gcd(-12, -9), 3)
    }

    func testIsCoprime() {
        XCTAssert(try ArbitraryPrecisionInteger(+9).isCoprime(with: +13))
        XCTAssert(try ArbitraryPrecisionInteger(+9).isCoprime(with: -13))
        XCTAssert(try ArbitraryPrecisionInteger(-9).isCoprime(with: +13))
        XCTAssert(try ArbitraryPrecisionInteger(-9).isCoprime(with: -13))

        XCTAssertFalse(try ArbitraryPrecisionInteger(+9).isCoprime(with: +27))
        XCTAssertFalse(try ArbitraryPrecisionInteger(+9).isCoprime(with: -27))
        XCTAssertFalse(try ArbitraryPrecisionInteger(-9).isCoprime(with: +27))
        XCTAssertFalse(try ArbitraryPrecisionInteger(-9).isCoprime(with: -27))
    }

    func testRandom() throws {
        XCTAssertEqual(try ArbitraryPrecisionInteger.random(inclusiveMin: 4, exclusiveMax: 5), 4)

        var previousRandom = ArbitraryPrecisionInteger()
        for _ in 1 ... 1000 {
            let exclusiveMax = try ArbitraryPrecisionInteger(bytes: Data(repeating: UInt8.max, count: 2048 / 8))
            let random = try ArbitraryPrecisionInteger.random(inclusiveMin: 42, exclusiveMax: exclusiveMax)
            XCTAssert(random >= ArbitraryPrecisionInteger(42))
            XCTAssert(random < exclusiveMax)
            XCTAssert(random != previousRandom)
            previousRandom = random
        }
    }

    func testDataRoundtrip() throws {
        for value: Int64 in [0, 1, 42, 256, 1024, .max] {
            let integer = ArbitraryPrecisionInteger(integerLiteral: value)
            let bytes = try Data(bytesOf: integer, paddedToSize: (value.bitWidth + 7) / 8)
            XCTAssertEqual(try ArbitraryPrecisionInteger(bytes: bytes), integer)
        }
    }
}
#endif // CRYPTO_IN_SWIFTPM && !CRYPTO_IN_SWIFTPM_FORCE_BUILD_API
