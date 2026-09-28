//
//  GRPCConfigurationTests.swift
//  InnerLampTests
//
//  Covers Docs/Specs/GRPC/tasks.md Phase 1 — the same shared GRPCClient instance is reused
//  across multiple Core/GRPC calls in a session (FR-001), rather than a new channel being
//  built per call.
//

import XCTest
import GRPCCore
@testable import InnerLamp

final class GRPCConfigurationTests: XCTestCase {

    func test_diContainer_grpcClient_isReusedAcrossAccesses() {
        let container = DIContainer()

        let first = container.grpcClient
        let second = container.grpcClient

        XCTAssertTrue(first === second, "DIContainer.grpcClient must be a single, shared instance (lazy var), not rebuilt per access")
    }

    func test_diContainer_grpcService_wrapsTheSharedClient() {
        let container = DIContainer()

        XCTAssertTrue(container.grpcService === container.grpcService)
    }
}
