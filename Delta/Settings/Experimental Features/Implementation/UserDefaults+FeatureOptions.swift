//
//  UserDefaults+FeatureOptions.swift
//  Delta
//
//  Created by Riley Testut on 4/7/23.
//  Copyright © 2023 Riley Testut. All rights reserved.
//

import Foundation

private func wrap<RawType, WrapperType: RawRepresentable>(rawValue: RawType, in type: WrapperType.Type) -> WrapperType?
{
    // Ensure rawValue is correct type.
    guard let rawValue = rawValue as? WrapperType.RawValue else { return nil }

    let representingValue = WrapperType.init(rawValue: rawValue)
    return representingValue
}

extension UserDefaults
{
    func setOptionValue<T>(_ newValue: T?, forKey key: String) throws
    {
        switch newValue
        {
        case let rawRepresentable as any RawRepresentable: self.set(rawRepresentable.rawValue, forKey: key)
//        case let nsDictionary as NSDictionary:
//            var sanitizedDictionary = nsDictionary.copy() as! [AnyHashable: Any]
//            // Remove userInfo values that don't conform to NSSecureEncoding.
//            sanitizedDictionary = sanitizedDictionary.filter { (key, value) in
//                return (value as AnyObject) is NSSecureCoding
//            }
//
        case let secureCoding as any NSSecureCoding:
            if secureCoding is NSNull
            {
                let nullDictionary = ["isNull": true] as NSDictionary
                self.set(nullDictionary, forKey: key)
            }
            else
            {
                self.set(secureCoding, forKey: key)
            }
            
        case let codable as any Codable:
            let data = try PropertyListEncoder().encode(codable)
            self.set(data, forKey: key)
            
        default:
            // Try anyway.
            self.set(newValue, forKey: key)
        }
    }
    
    func optionValue<Value>(forKey key: String, type: Value.Type) throws -> Value?
    {
        guard let rawValue = UserDefaults.standard.object(forKey: key) else { return nil }
        
        if let nullDictionary = rawValue as? [String: Bool], let isNull = nullDictionary["isNull"], let optionalType = Value.self as? any OptionalProtocol.Type, isNull
        {
            return optionalType.none as? Value
        }

        if let value = rawValue as? Value
        {
            return value
        }
        else if let optionalType = Value.self as? any OptionalProtocol.Type, let rawRepresentableType = optionalType.wrappedType as? any RawRepresentable.Type
        {
            // Open `rawRepresentableType` existential as concrete type so we can initialize RawRepresentable.
            let rawRepresentable = wrap(rawValue: rawValue, in: rawRepresentableType) as? Value
            return rawRepresentable
        }
        else if let rawRepresentableType = Value.self as? any RawRepresentable.Type
        {
            // Open `rawRepresentableType` existential as concrete type so we can initialize RawRepresentable.
            let rawRepresentable = wrap(rawValue: rawValue, in: rawRepresentableType) as? Value
            return rawRepresentable
        }
        else if let codableType = Value.self as? any Codable.Type, let data = rawValue as? Data
        {
            let decodedValue = try PropertyListDecoder().decode(codableType, from: data) as? Value
            return decodedValue
        }
        else
        {
            print("[ALTLog] Unsupported Option Type:", Value.self)
            return nil
        }
    }
}