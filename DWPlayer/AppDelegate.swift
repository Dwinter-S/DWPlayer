//
//  AppDelegate.swift
//  DWPlayer
//
//  Created by dwinters on 2023/4/18.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}


//let mp4URLs = ["http://ieltsbro.oss-cn-beijing.aliyuncs.com/apk/10.0.0/Emily-%E5%8F%A3%E8%AF%ADPart%201%E5%A6%82%E4%BD%95%E8%8E%B7%E5%BE%97%E8%80%83%E5%AE%98%E5%A5%BD%E6%84%9F.mp4",
//            "http://ieltsbro.oss-cn-beijing.aliyuncs.com/apk/10.0.0/Emily-%E5%8F%A3%E8%AF%ADPart%201%E9%99%A4%E4%BA%86because%E8%BF%98%E8%83%BD%E5%A6%82%E4%BD%95%E6%8B%93%E5%B1%95.mp4",
//            "https://static.ieltsbro.com/apk/10.0.0/%E5%8F%A3%E8%AF%AD%E5%BD%95%E8%AF%BE%EF%BC%9AP2%E4%B8%B2%E9%A2%98.mp4",
//            "https://static.ieltsbro.com/apk/10.0.0/%E5%8F%A3%E8%AF%AD%E5%BD%95%E8%AF%BE%EF%BC%9AP2%E7%9A%84%E2%80%9C%E5%81%A5%E8%B0%88%E2%80%9D%E6%8A%80%E5%B7%A70827.mp4",
//            "https://static.ieltsbro.com/apk/10.0.0/%E5%8F%A3%E8%AF%AD%E5%BD%95%E8%AF%BE%EF%BC%9A%E8%AF%8D%E6%B1%87%E5%A4%9A%E6%A0%B7%E6%80%A7FINALFINAL.mp4",
//            "https://static.ieltsbro.com/apk/10.0.0/%E5%8F%A3%E8%AF%AD%E5%BD%95%E8%AF%BE%EF%BC%9AP3%E8%BE%A9%E8%AE%BA%E5%9E%8B%E9%97%AE%E9%A2%98FINALFINAL.mp4",
//            "http://ieltsbro.oss-cn-beijing.aliyuncs.com/apk/10.0.0/Emily-%E5%8F%A3%E8%AF%ADPart%201%E7%AD%94%E9%A2%98%E6%80%9D%E8%B7%AF.mp4",
//            "http://ieltsbro.oss-cn-beijing.aliyuncs.com/apk/10.0.0/Emily-%E5%8F%A3%E8%AF%AD%E8%B0%9A%E8%AF%AD.mp4",
//            "http://ieltsbro.oss-cn-beijing.aliyuncs.com/apk/10.0.0/Annie-%E5%90%AC%E5%8A%9B%E5%9F%BA%E7%A1%80%E8%83%BD%E5%8A%9B%E6%8F%90%E5%8D%87%E6%96%B9%E6%B3%95.mp4",
//            "http://ieltsbro.oss-cn-beijing.aliyuncs.com/apk/10.0.0/Annie-%E5%90%AC%E5%8A%9B%E5%A4%9A%E9%80%89%E9%A2%98.mp4",
//            "http://ieltsbro.oss-cn-beijing.aliyuncs.com/apk/10.0.0/Annie-%E5%90%AC%E5%8A%9B%E6%B5%81%E7%A8%8B%E5%9B%BE.mp4",
//            "http://ieltsbro.oss-cn-beijing.aliyuncs.com/apk/10.0.0/Annie-%E5%90%AC%E5%8A%9B%E8%A1%A8%E6%A0%BC%E9%A2%98.mp4",
//            "http://ieltsbro.oss-cn-beijing.aliyuncs.com/apk/10.0.0/Annie-%E5%90%AC%E5%8A%9B%E6%84%8F%E7%BE%A4.mp4",
//            "https://video.ieltsbro.com/8cb3a1cc34fa4fca8491628c40b0f71c/4493d0dbce9c486189920f288ba4d5ea-ea46f0a493bc3ae64067a35dab78407d-ld.m3u8", "http://ieltsbro.oss-cn-beijing.aliyuncs.com/apk/10.0.0/Annie-%E5%90%AC%E5%8A%9B%E5%A4%9A%E9%80%89%E9%A2%98.mp4"]
//
//let mp3URLs = [
//    "https://static.ieltsbro.com/uploads/app_oral_practice_comment/audio_record/1681871044910.mp3",
//    "https://static.ieltsbro.com/uploads/app_oral_practice_comment/audio_record/1681870551396.mp3",
//    "https://static.ieltsbro.com/uploads/app_oral_practice_comment/audio_record/1681870441000.mp3",
//    "https://static.ieltsbro.com/uploads/app_oral_practice_comment/audio_record/1681870069547.mp3"]
