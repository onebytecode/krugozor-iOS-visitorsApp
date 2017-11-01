//
//  ApiManager.swift
//  krugozor-visitorsApp
//
//  Created by Alexander Danilin on 21/10/2017.
//  Copyright © 2017 oneByteCode. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

protocol APIManaging {
 
    func isVisitorRegisteredBy(email: String, completion: @escaping ((_ result: String?, _ error: String?) -> Void))
    func visitorRegistrationWith(data: VisitorAuthorizationData, completion: @escaping ((_ sessionToken: String?, _ error: String?) -> Void))
    func visitorLogInWith(data: VisitorAuthorizationData, completion: @escaping ((_ sessionToken: String?, _ error: String?) -> Void))
}

/// Default Layer Class For Server Interaction
class APIManager {
    
    public func fetchCurrentVisitorBy(sessionToken: String, completion: @escaping ((_ visitorModel: Visitor?, _ error: String?) -> Void)) {
    
        var gql = String()
        let gqlParams = [GQLParam.init(key: "sessionToken", value: sessionToken)]
        var gqlArgs = [GQLArgument]()
        for i in Visitor.arrayOfSelfFields() { gqlArgs.append(GQLArgument.init(key: i))}
    
        do {
            gql = try GQLBuilder.build(query: Query.visitor, mutation: nil, params: gqlParams, arguments: gqlArgs)
        } catch let error {
            log.error(error)
        }
        
        let parameters: Parameters = ["query" : gql]
        
        Alamofire.request(URLBuilder.gqlHost, method: .get, parameters: parameters).responseJSON { response in
            switch response.result {
            case .success(let value): let json = JSON(value)
            guard json["data"]["getVisitor"]["id"].string != nil else { return completion(nil, json["errors"][0]["message"].string)}
                completion(self.parseVisitorToModelFrom(json: json["data"]["getVisitor"]), nil)
            case .failure(let error): log.error(error); break
            }
        }
    }
    
    /// Function Checks if Visitor in backend's base
    ///
    /// - Parameters:
    ///   - email: Visitor email
    ///   - completion: Bool: true -> Visitor in a base; false -> Visitor needs for registation
    public func isVisitorRegisteredBy(email: String, completion: @escaping (_ result: Bool) -> Void) {
        
        let gqlParams = [GQLParam.init(key: GQLVisitor.email.rawValue, value: email)]
        let gqlArgumant = [GQLArgument.init(key: "id")]
        var gql = String()
        
        do {
         gql = try GQLBuilder.build(query: Query.visitor, mutation: nil, params: gqlParams, arguments: gqlArgumant)
        } catch let error { log.error(error) }
        let parameters: Parameters = ["query" : gql]
        
        Alamofire.request(URLBuilder.gqlHost, method: .get, parameters: parameters).responseJSON { response in
            switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    if json["data"]["getVisitor"]["id"].string != nil {
                        completion(true)
                    } else {
                        completion(false) }
                case .failure(let error):
                    log.error(error)
            }
        }
    }
    
    public func visitorRegistrationWith(data: VisitorAuthorizationData, completion: @escaping ((_ sessionToken: String?, _ error: String?) -> Void)) {
        
        // FIXME: Implement through GQLVisitor ENUM
        let visitorAuthDataArray = data.arrayOfSelfParams()
        var gqlParams = [GQLParam]()
        for i in visitorAuthDataArray {
            gqlParams.append(GQLParam.init(key: i.key, value: i.value))
        }
        
        var gql = String()
        
        do {
            gql =  try GQLBuilder.build(query: nil, mutation: Mutation.registerNewVisitor, params: gqlParams, arguments: [GQLArgument.init(key: "id")])
        } catch let error { log.error(error) }
        
        let parameters: Parameters = ["query" : gql]
        
        
        Alamofire.request(URLBuilder.gqlHost, method: .post, parameters: parameters).responseJSON { response in
            
            switch response.result {
                
            case .success (let value):
                let json = JSON(value)
                if json["data"]["registerNewVisitor"]["id"].string != nil {
                    
                    // FIXME: RETURN JUST A sessionToken afte backend fixes
                    self.visitorLogInWith(data: data, completion: { (sessionID, error) in
                        completion(sessionID, error)
                    })
                    
                } else { log.error("Error"); completion(nil, json["errors"][0]["message"].string) }
                
            case .failure(let error): log.error(error); completion(nil, String(describing: error))
                
            }
        }
    }
    

    /// Main Visiot Log In Function
    ///
    /// - Parameters:
    ///   - data: Type VisitorAuthorizationData
    ///   - completion: Tuple(sessionToke: String?, error: String?)
    public func visitorLogInWith(data: VisitorAuthorizationData, completion: @escaping ((_ sessionToken: String?, _ error: String?) -> Void)) {
        
        let gqlParams = [GQLParam.init(key:GQLVisitor.email.rawValue, value: data.email),
                         GQLParam.init(key: GQLVisitor.password.rawValue, value: data.password)]
        
        var gql = String()
        
        do {
            gql = try GQLBuilder.build(query: nil, mutation: Mutation.visitorLogIn, params: gqlParams, arguments: [GQLArgument.init(key: "sessionToken")])
        } catch let error {
            log.error (error) }
        
        let parameters: Parameters = ["query" : gql]
        
        Alamofire.request(URLBuilder.gqlHost, method: .post, parameters: parameters).responseJSON { response in
            
            switch response.result {
                
                case .success (let value): let json = JSON(value)
                guard let sessionToken = json["data"]["visitorLogIn"]["sessionToken"].string else { log.debug("");return completion(nil, json["errors"][0]["message"].string)}
                    return completion(sessionToken, nil)
                
                case .failure(let error): log.error(error); completion(nil, String(describing: error))
            }
        }
    }
    
    private func parseVisitorToModelFrom(json:JSON) -> Visitor {
        
        let visitor = Visitor()
        
        visitor.email = json["email"].string!
        visitor.fname = json["fname"].string!
        visitor.serverID = json["id"].string!
        visitor.phoneNumber = json["phoneNumber"].string!
        visitor.sessionToken = json["sessionToken"].string!
        
        return visitor
    }
}
