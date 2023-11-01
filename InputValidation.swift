import Foundation
import UIKit

typealias ValidationResult = (isValid: Bool, error: String?)

enum InputValidation {
    case email
    case password
    case mobile
    case firstname
    case lastname
    case referralCode
    case amount
    case nationalID
}

extension InputValidation {

    var maxLimit: Int {
        switch self {
        case .mobile:       return 10
        case .firstname:    return 25
        case .lastname:     return 25
        case .password:     return 15
        case .referralCode: return 30
        case .nationalID:   return 9
        default:            return 200
        }
    }
    
    var allowedCharacters: String{
        switch self {
        case .email:
            return "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!#$%&'*+-/=?^_`{|}~;@."
        case .mobile:
            return "0123456789"
        case .amount:
            return "0123456789."
        case .nationalID:
            return "0123456789"
        default:
            return ""
        }
    }

    var pattern: String {
        switch self {
        case .email:
            return "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}$"
        case .firstname, .lastname:
            return "[A-Za-z]{2,25}"
        case .password:
            return "[a-zA-Z0-9!@#$%^&*]{8,15}"
            // [a-zA-Z0-9!@#$%^&*]
          //  return "(?=.*[a-z])(?=.*[$@$#!%*?&])[A-Za-z\\d$@$#!%*?&]{8,15}"
        case .mobile:
            return "[0-9]{9,12}"
        case .referralCode:
            return "^\\w{0,20}$"
        case .amount:
            return "^\\d+(\\.\\d{1,2})?$"
        case .nationalID:
            return "[0-9]{9}"
        }
    }

    func isValid(input: String) -> ValidationResult {
        switch self {
        case .email:
            return validateEmail(input: input)
        case .password:
            return validatePassword(input: input)
        case .mobile:
            return validateMobile(input: input)
        case .firstname:
            return validateFirstName(input: input)
        case .lastname:
            return validateLastName(input: input)
        case .referralCode:
            return validateRefferalCode(input: input)
        case .amount:
            return validateAmount(input: input)
        case .nationalID:
            return validateNationalID(input: input)
        }
    }

    func isValidForPattern(input: String) -> Bool {
        let predicate = NSPredicate(format:"SELF MATCHES %@", self.pattern)
        return predicate.evaluate(with: input)
    }

}

// MARK: - Validation Methods
extension InputValidation {

    // MARK: - Email
    func validateEmail(input: String) -> ValidationResult {
        guard input.isEmpty == false else {
            return (false, Texts.pleaseEnterEmail.localized())
        }
        guard isValidForPattern(input: input) else {
            return (false, Texts.validEmail.localized())
        }
        return (true, "")
    }

    // MARK: - Mobile
    func validateMobile(input: String) -> ValidationResult {
        guard input.isEmpty == false else {
            return (false, Texts.pleaseEnterMobile.localized())
        }
        guard isValidForPattern(input: input) else {
            return (false, Texts.validMobile.localized())
        }
        return (true, "")
    }

    // MARK: - UserName
    func validateFirstName(input: String) -> ValidationResult {
        guard input.isEmpty == false else {
            return (false, Texts.pleaseEnterFirstName.localized())
        }
        guard isValidForPattern(input: input) else {
            return (false, Texts.validFirstname.localized())
        }
        return (true, "")
    }

    func validateLastName(input: String) -> ValidationResult {
        guard input.isEmpty == false else {
            return (false, Texts.pleaseEnterLastName.localized())
        }
        guard isValidForPattern(input: input) else {
            return (false, Texts.validLastname.localized())
        }
        return (true, "")
    }
    
    // MARK: - Password
    func validatePassword(input: String) -> ValidationResult {
        guard input.isEmpty == false else {
            return (false, Texts.pleaseEnterPassword.localized())
        }
        guard input.count >= 8 && input.count <= 25 else {
            return (false, Texts.invalidPasswordRange.localized())
        }

        guard isValidForPattern(input: input) else {
            return (false, Texts.validPassword.localized())
        }
        return (true, "")
    }

    // MARK: - Refferal code
    func validateRefferalCode(input: String) -> ValidationResult {
        return (input.count <= 20, "")
    }
    
    // MARK: - Amount
    func validateAmount(input: String) -> ValidationResult {
        guard input.isEmpty == false else {
            return (false, Texts.pleaseEnterAmount.localized())
        }
        guard let doubleValue = Double(input), doubleValue > 0 else {
            return (false, Texts.validAmount.localized())
        }
        return (true, "")
    }

    // MARK: - National ID card number
    func validateNationalID(input: String) -> ValidationResult {
        guard input.isEmpty == false else {
            return (false, Texts.pleaseEnterNationalID.localized())
        }
        guard isValidForPattern(input: input) else {
            return (false, Texts.validNationalID.localized())
        }
        return (true, "")
    }
}

extension InputValidation {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentString = textField.text! as NSString
        let newString: NSString =
        currentString.replacingCharacters(in: range, with: string) as NSString
        var isValid = newString.length <= self.maxLimit
        let characters = self.allowedCharacters
        if isValid && characters.isEmpty == false {
            let allowedCharacters = CharacterSet(charactersIn:characters)
            let characterSet = CharacterSet(charactersIn: string)
            isValid = allowedCharacters.isSuperset(of: characterSet)
        }
        return isValid
    }
}
