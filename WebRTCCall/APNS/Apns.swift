//
//  VOIP.swift
//  pushme
//
//  Created by lynn on 2025/6/17.
//

import Foundation
import SwiftJWT
import Foundation
import CryptoKit


final class ApnsManager: NetworkManager{
    
    static let shared = ApnsManager()
    
    private override init() {  super.init() }

    
    let AppKeyId = "BNY5GUGV38"
    let AppTeamId = "FUWV6U942Q"
    let AppTopic = Bundle.main.bundleIdentifier ?? "me.uuneo.Meoworld"
    let AppApnsPrivateKey = """
        -----BEGIN PRIVATE KEY-----
        MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgvjopbchDpzJNojnc
        o7ErdZQFZM7Qxho6m61gqZuGVRigCgYIKoZIzj0DAQehRANCAAQ8ReU0fBNg+sA+
        ZdDf3w+8FRQxFBKSD/Opt7n3tmtnmnl9Vrtw/nUXX4ldasxA2gErXR4YbEL9Z+uJ
        REJP/5bp
        -----END PRIVATE KEY-----
        """
    
    func voip( deviceToken: String, params:[String:Any] = [:] ) async -> Bool {
        
        let urlString = BaseConfig.defaultApns + deviceToken
        do{
            let jwtToken = try generateJWT(teamId: AppTeamId, keyId: AppKeyId, privateKey: AppApnsPrivateKey)
            
            var params = params
            
            params["aps"] = [:]
            
            let data = try await self.fetch(url: urlString, method: .post, params: params, headers: [
                "authorization" : "bearer \(jwtToken)",
                "apns-topic" : "\(AppTopic).voip",
                "apns-push-type" : "voip",
                "apns-priority" : "10",
                "apns-expiration" : "0"
            ])
            
            print("Response:", String(data: data, encoding: .utf8) ?? "")
            return true
        }catch{
            debugPrint(error.localizedDescription)
            return false
        }
    }
    
    func alert(deviceToken: String, title: String, body:String, remoteUserId:String ) async -> Bool {
        do{
            let urlString = BaseConfig.defaultApns + deviceToken
            

            let jwtToken = try generateJWT(teamId: AppTeamId, keyId: AppKeyId, privateKey: AppApnsPrivateKey)
            let data = try await self.fetch(url: urlString,  method: .post, params: [
                "aps":[
                    "alert" : [ "title": title, "body": body ],
                    "mutable-content": 1],
                "call" : "1", "ttl": 0,"user": remoteUserId
            ], headers: [
                "authorization" : "bearer \(jwtToken)",
                "apns-topic" : AppTopic,
                "apns-push-type" : "alert",
                "apns-priority" : "10",
                "apns-expiration" : "0"
            ])
            print("Response:", String(data: data, encoding: .utf8) ?? "")
            return true
        }catch{
            debugPrint(error.localizedDescription)
            return false
        }
    }

    
    private func generateJWT(teamId: String, keyId: String, privateKey: String) throws -> String {
        
        struct MyClaims: Claims {
            let iss: String
            let iat: Date
        }
        
        let header = Header(kid: keyId)
        let claims = MyClaims(iss: teamId, iat: Date())
        
        var jwt = JWT(header: header, claims: claims)
        let jwtSigner = JWTSigner.es256(privateKey: Data(privateKey.utf8))
        
        return try jwt.sign(using: jwtSigner)
    }
    
 
}

