import Foundation
import Combine

final class AppLanguage: ObservableObject {
    static let shared = AppLanguage()
    @Published var selection: String {
        didSet { UserDefaults.standard.set(selection,forKey:"appLanguage") }
    }
    private init() { selection = UserDefaults.standard.string(forKey:"appLanguage") ?? "system" }
    var code: String {
        if selection == "ko" || selection == "en" { return selection }
        return Locale.preferredLanguages.first?.hasPrefix("ko") == true ? "ko":"en"
    }
    var locale: Locale { Locale(identifier:code) }
    func text(_ key: String) -> String {
        let suffix = " 연결을 선택했습니다"
        if key != "%@ 연결을 선택했습니다", key.hasSuffix(suffix) {
            let profile = String(key.dropLast(suffix.count))
            return String(format:text("%@ 연결을 선택했습니다"),text(profile))
        }
        guard let path = Bundle.main.path(forResource:code,ofType:"lproj"), let bundle = Bundle(path:path) else { return key }
        return bundle.localizedString(forKey:key,value:key,table:nil)
    }
}
