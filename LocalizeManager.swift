import UIKit

class LocalizeManager {
    static let shared = LocalizeManager()
    private(set) var language: Language = .english
    
    var selectedLanguageIndex: Int {
        Language.allCases.firstIndex(of: language) ?? 0
    }
    
    var semantic: UISemanticContentAttribute {
        language == .english ? .forceLeftToRight : .forceRightToLeft
    }
    
    func fetch() {
        let string = UserDefaults.standard.string(forKey: "ud_language") ?? ""
        setLanguage(Language(rawValue: string) ?? .english)
    }
    
    func save() {
        UserDefaults.standard.set(language.rawValue, forKey: "ud_language")
    }
    
    func setLanguage(_ language: Language) {
        self.language = language
        save()
        UserDefaults.standard.set([language.rawValue], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        UIView.appearance().semanticContentAttribute = LocalizeManager.shared.semantic
        if let homeVc = AppViewControllers.shared.getHomeVC(),
           homeVc.bookingInfo != nil {
            AppManager.shared.bookingInfo = nil
            AppManager.shared.bookingInfo = homeVc.bookingInfo
        }
        AppDelegate.current.setRootViewController()
        //NotificationCenter.default.post(name: .languageChanged, object: nil)
    }
    
    var socketMessageKey: String {
        language == .arabic ? "arabic_message" : "message"
    }
    
}

enum Language: String, CaseIterable {
    case english = "en"
    case arabic = "ar"
}

extension String {
    func localized() -> String {
        let path = Bundle.main.path(forResource: LocalizeManager.shared.language.rawValue, ofType: "lproj")
        let bundle = Bundle(path: path!)
        return NSLocalizedString(self, tableName: nil, bundle: bundle!, value: "", comment: "")
    }
}

extension Notification.Name {
    static let languageChanged = NSNotification.Name("languageChanged")
}
