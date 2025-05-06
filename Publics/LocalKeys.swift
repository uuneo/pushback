//
//  LocalKeys.swift
//  pushback
//
//  Created by uuneo 2024/10/26.
//

@_exported import Defaults
import Foundation

extension Defaults.Keys {
    
    static let servers = Key<[PushServerModel]>("serverArrayStroage", [])
    static let cloudServers = Key<[PushServerModel]>("serverArrayCloudStroage", [], iCloud: true)
    static let cryptoConfig = Key<CryptoModelConfig>("CryptoSettingFields", CryptoModelConfig.data)
    static let badgeMode = Key<BadgeAutoMode>("Meowbadgemode", .auto)
    static let appIcon = Key<AppIconEnum>("setting_active_app_icon", .pushback)
    static let messageExpiration = Key<ExpirationTime>("messageExpirtionTime", .forever)
    static let defaultBrowser = Key<DefaultBrowserModel>("defaultBrowserOpen", .safari)
    static let imageSaveDays = Key<ExpirationTime>("imageSaveDays", .forever)
    static let assistantAccouns = Key<[AssistantAccount]>("AssistantAccount",[], iCloud: true)
    
}

extension ExpirationTime: Defaults.Serializable{ }
extension DefaultBrowserModel:Defaults.Serializable {}
extension AssistantAccount: Defaults.Serializable{}
extension CategoryParams: Defaults.Serializable{}
extension AppIconEnum: Defaults.Serializable{}
extension CryptoModelConfig: Defaults.Serializable{}
extension CryptoAlgorithm: Defaults.Serializable{}
extension CryptoMode: Defaults.Serializable{}
extension BadgeAutoMode: Defaults.Serializable{}
extension PushServerModel: Defaults.Serializable{}




