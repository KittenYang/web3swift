//
//  Created by Alex Vlasov.
//  Copyright © 2018 Alex Vlasov. All rights reserved.
//

import Foundation
import BigInt
import Core

extension web3 {

    /// The contract instance. Initialized in runtime from ABI string (that is a JSON array). In addition an existing contract address can be supplied to provide the default "to" address in all the following requests. ABI version is 2 by default and should not be changed.
    public func contract(_ abiString: String, at: EthereumAddress? = nil, abiVersion: Int = 2) -> web3contract? {
        return web3contract(web3: self, abiString: abiString, at: at, transactionOptions: self.transactionOptions, abiVersion: abiVersion)
    }

    // FIXME: Rewrite this to EthereumTransaction
    /// Web3 instance bound contract instance.
    public class web3contract {
        public let contract: EthereumContract
        public let web3: web3
        public var transactionOptions: TransactionOptions? = nil

        // FIXME: Rewrite this to EthereumTransaction
        /// Initialize the bound contract instance by supplying the Web3 provider bound object, ABI, Ethereum address and some default
        /// options for further function calls. By default the contract inherits options from the web3 object. Additionally supplied "options"
        /// do override inherited ones.
        public init?(web3 web3Instance: web3, abiString: String, at: EthereumAddress? = nil, transactionOptions: TransactionOptions? = nil, abiVersion: Int = 2) {
            self.web3 = web3Instance
            self.transactionOptions = web3.transactionOptions
            switch abiVersion {
            case 1:
                print("ABIv1 bound contract is now deprecated")
                return nil
            case 2:
                guard let c = try? EthereumContract(abiString, at: at) else {return nil}
                contract = c
            default:
                return nil
            }
            var mergedOptions = self.transactionOptions?.merge(transactionOptions)
            if at != nil {
                contract.address = at
                mergedOptions?.to = at
            } else if let addr = mergedOptions?.to {
                contract.address = addr
            }
            self.transactionOptions = mergedOptions
        }

        // MARK: Writing Data flow
        // FIXME: Rewrite this to EthereumTransaction
        /// Deploys a constact instance using the previously provided  ABI, some bytecode, constructor parameters and options.
        /// If extraData is supplied it is appended to encoded bytecode and constructor parameters.
        ///
        /// Returns a "Transaction intermediate" object.
        public func deploy(bytecode: Data,
                           constructor: ABI.Element.Constructor? = nil,
                           parameters: [AnyObject]? = nil,
                           extraData: Data? = nil,
                           transactionOptions: TransactionOptions? = nil) -> WriteTransaction? {
            let mergedOptions = self.transactionOptions?.merge(transactionOptions)
            // MARK: Writing Data flow
            guard var tx = self.contract.deploy(bytecode: bytecode,
                                                constructor: constructor,
                                                parameters: parameters,
                                                extraData: extraData)
            else { return nil }

            tx.chainID = self.web3.provider.network?.chainID
            return WriteTransaction(transaction: tx,
                                    web3: self.web3,
                                    contract: self.contract,
                                    transactionOptions: mergedOptions)
        }

        // FIXME: Rewrite this to EthereumTransaction
        /// Creates and object responsible for calling a particular function of the contract. If method name is not found in ABI - returns nil.
        /// If extraData is supplied it is appended to encoded function parameters. Can be usefull if one wants to call
        /// the function not listed in ABI. "Parameters" should be an array corresponding to the list of parameters of the function.
        /// Elements of "parameters" can be other arrays or instances of String, Data, BigInt, BigUInt, Int or EthereumAddress.
        ///
        /// Returns a "Transaction intermediate" object.
        public func method(_ method: String = "fallback", parameters: [AnyObject] = [AnyObject](), extraData: Data = Data(), transactionOptions: TransactionOptions? = nil) -> WriteTransaction? {
            let mergedOptions = self.transactionOptions?.merge(transactionOptions)
            guard var tx = self.contract.method(method, parameters: parameters, extraData: extraData) else {return nil}
            tx.chainID = self.web3.provider.network?.chainID
            let writeTX = WriteTransaction.init(transaction: tx, web3: self.web3, contract: self.contract, method: method, transactionOptions: mergedOptions)
            return writeTX
        }

        // FIXME: Actually this is not rading contract or smth, this is about composing appropriate binary data to iterate with it later.
        // FIXME: Rewrite this to EthereumTransaction
        /// Creates and object responsible for calling a particular function of the contract. If method name is not found in ABI - returns nil.
        /// If extraData is supplied it is appended to encoded function parameters. Can be usefull if one wants to call
        /// the function not listed in ABI. "Parameters" should be an array corresponding to the list of parameters of the function.
        /// Elements of "parameters" can be other arrays or instances of String, Data, BigInt, BigUInt, Int or EthereumAddress.
        ///
        /// Returns a "Transaction intermediate" object.
        public func read(_ method: String = "fallback", parameters: [AnyObject] = [AnyObject](), extraData: Data = Data(), transactionOptions: TransactionOptions? = nil) -> ReadTransaction? {
            let mergedOptions = self.transactionOptions?.merge(transactionOptions)
            // MARK: - Encoding ABI Data flow
            guard var tx = self.contract.method(method, parameters: parameters, extraData: extraData) else {return nil}
            tx.chainID = self.web3.provider.network?.chainID
            // MARK: Read data from ABI flow
            let writeTX = ReadTransaction.init(transaction: tx, web3: self.web3, contract: self.contract, method: method, transactionOptions: mergedOptions)
            return writeTX
        }

        // FIXME: Rewrite this to EthereumTransaction
        /// Creates and object responsible for calling a particular function of the contract. If method name is not found in ABI - returns nil.
        /// If extraData is supplied it is appended to encoded function parameters. Can be usefull if one wants to call
        /// the function not listed in ABI. "Parameters" should be an array corresponding to the list of parameters of the function.
        /// Elements of "parameters" can be other arrays or instances of String, Data, BigInt, BigUInt, Int or EthereumAddress.
        ///
        /// Returns a "Transaction intermediate" object.
        public func write(_ method: String = "fallback", parameters: [AnyObject] = [AnyObject](), extraData: Data = Data(), transactionOptions: TransactionOptions? = nil) -> WriteTransaction? {
            let mergedOptions = self.transactionOptions?.merge(transactionOptions)
            guard var tx = self.contract.method(method, parameters: parameters, extraData: extraData) else {return nil}
            tx.chainID = self.web3.provider.network?.chainID
            let writeTX = WriteTransaction.init(transaction: tx, web3: self.web3, contract: self.contract, method: method, transactionOptions: mergedOptions)
            return writeTX
        }

//        /// Creates an "EventParserProtocol" compliant object to use it for parsing particular block or transaction for events.
//        public func createEventParser(_ eventName: String, filter: EventFilter?) -> EventParserProtocol? {
//            let parser = EventParser(web3: self.web3, eventName: eventName, contract: self.contract, filter: filter)
//            return parser
//        }
    }
}
