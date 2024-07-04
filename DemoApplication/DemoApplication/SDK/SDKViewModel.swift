//
//  MainViewModel.swift
//  StarterKit
//
//  Created by Dmitry Eryshov on 31.05.2024.
//

import Foundation
import kameleoonClient
import os
import SwiftUI

class SDKViewModel: ObservableObject {
    
    private struct Const {
        static let siteCode = "sitecode" // <<---- You should change it to your own siteCode
        static let refreshInterval = 15
        static let timeoutInit = 2000
    }
    
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: SDKViewModel.self)
    )
            
    var kameleoonClient: KameleoonClient!
    
    @Published var status: Bool = false
    @Published var initialization: Bool = true
    @Published var result: Result<(ResultState,String), Error> = .success((.calculate, ""))
    @Published var success: Bool = false
    @Published var params: Params! {
        didSet {
            params.save()
        }
    }

    
    init() {
        initKameleoonClient()
        params = Params()
    }
    
    // Initialize Kameleoon SDK
    private func initKameleoonClient() {
        do {
            // If no visitor code provided, it will be generated by SDK itself and will be used for all future requests
            // Usually you should set visitor code as real user ID
            let visitorCode: String? = nil
            // KameleoonClientConfig is used to set KameleoonClient settings
            let config = KameleoonClientConfig(refreshIntervalMinute: Const.refreshInterval)
            // KameleoonClient is the instance you should use for all SDK activities.
            // You should properly handle the errors.
            kameleoonClient = try KameleoonClientFactory.create(
                siteCode: Const.siteCode,
                visitorCode: visitorCode,
                config: config
            )
            SDKViewModel.logger.info("SDK is initializing...")
            // runWhenReady is a method that will be called after the SDK initialization process has completed
            // if the SDK is already initialized, the method immediately calls the callback
            kameleoonClient.runWhenReady(timeoutMilliseconds: Const.timeoutInit) { [weak self] ready in
                guard let self else { return }
                self.status = ready
                self.initialization = false
                SDKViewModel.logger.info("SDK is \(ready ? "ready" : "not ready") to use")
            }
        } catch KameleoonError.siteCodeIsEmpty {
            // Provided siteCode is empty
            SDKViewModel.logger.error("Sitecode is empty")
        } catch KameleoonError.visitorCodeInvalid(let visitorCode) {
            // Provided visitorCode is not valid
            SDKViewModel.logger.error("Visitor code '\(visitorCode)' is not valid")
        } catch {
            // Base error, usually it should never happen. You can ignore all errors above and catch only base
            // if you're not interested in specific reason of error
            SDKViewModel.logger.error("Unexpected Error: \(error.localizedDescription)")
        }
    }
    
    enum ResultState {
        case calculate, ready
    }
    
    struct KError: LocalizedError {
        let error: String
        
        public var errorDescription: String? {
            return error
        }
    }
    
    func log(_ result: Result<(ResultState,String), Error>) {
        switch result {
            case .success(let success):
                SDKViewModel.logger.info("\(success.1)")
            case .failure(let failure):
                SDKViewModel.logger.error("\(failure.localizedDescription)")
        }
    }
}