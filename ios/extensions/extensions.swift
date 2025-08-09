//
//  extensions.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 27.09.2023.
//

import Foundation
import SwiftUI
import Combine

extension Date {
    static func -(recent: Date, previous: Date) -> (month: Int?, day: Int?, hour: Int?, minute: Int?, second: Int?) {
        let day = Calendar.current.dateComponents([.day], from: previous, to: recent).day
        let month = Calendar.current.dateComponents([.month], from: previous, to: recent).month
        let hour = Calendar.current.dateComponents([.hour], from: previous, to: recent).hour
        let minute = Calendar.current.dateComponents([.minute], from: previous, to: recent).minute
        let second = Calendar.current.dateComponents([.second], from: previous, to: recent).second

        return (month: month, day: day, hour: hour, minute: minute, second: second)
    }
    
    func add(_ component:Calendar.Component,value:Int, using calendar: Calendar = .current) -> Date{
        return calendar.date(byAdding: component,value:value, to: self)!
    }
    func startOfMonth(calendar: Calendar = .current) -> Date{
        let components = calendar.dateComponents([.year,.month],from:self)
        return calendar.date(from:components)!
    }
    func endOfMonth(calendar:Calendar = .current) -> Date{
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return calendar.date(byAdding: components, to: self.startOfMonth())!
    }
    func asStringDate(calendar:Calendar = .current) -> String{
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
    func asStringDateTime(calendar:Calendar = .current) -> String{
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: self)
    }
    
    func asString(_ format: String = "yyyy-MM-dd") -> String{        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = format
        
        return formatter.string(from: self)
    }
    
    func asBackendString() -> String{
        return self.asString(defaultBackendDateFormat)
    }
}

extension String {
    var capitalizedSentence: String {
        let firstLetter = self.prefix(1).capitalized
        let remainingLetters = self.dropFirst().lowercased()
        return firstLetter + remainingLetters
    }
    var isBackspace: Bool {
        let char = self.cString(using: String.Encoding.utf8)!
        return strcmp(char, "\\b") == -92
    }
    
    func stringAt(index: Int) -> String {
        let stringIndex = self.index(self.startIndex, offsetBy: index)
        return String(self[stringIndex])
    }
    
    func base64Decode() -> String? {
        var st = self.replacingOccurrences(of: "_", with: "/").replacingOccurrences(of: "-", with: "+")
        let remainder = self.count % 4
        if remainder > 0 {
            st = self.padding(toLength: self.count + 4 - remainder,withPad: "=",startingAt: 0)
        }
        guard let d = Data(base64Encoded: st, options: .ignoreUnknownCharacters) else{
            return nil
        }
        return String(data: d, encoding: .utf8)
    }
    
    func formatAsPrice(_ currency:String) -> String{
        var formatted = self
        let components = formatted.components(separatedBy: ".")
        
        var integer = components.count > 0 ? components[0] : "0"
        var coins = components.count == 2 ? components[1] : "0"
        
        if (coins.count == 1){
            coins = "\(coins)0"
        }
        coins = String(coins.prefix(2))
        
        var amount = Double(String((formatted as NSString).doubleValue)) ?? 0
        let isNegative = amount < 0
        
        let main = Swift.abs(Double(String((integer as NSString).doubleValue)) ?? 0)
        var price = "\(main.formattedWithSeparator).\(coins)"
        return "\(isNegative ? "-" : "")\(currency) \(price)"
         
    }
    
    func mask(_ mask: String) -> String{
        return self
    }
    
    func asInitials() -> String{
        var formatted = self.trimmingCharacters(in: .whitespacesAndNewlines)
        var components = formatted.components(separatedBy: " ").map({
            return $0.prefix(1)
        }).prefix(2)
        return components.joined(separator: "")
    }
    
    func asDate(_ format: String = defaultDateFormat) -> Date?{
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = format
        var date = formatter.date(from: self)
        if (date == nil){
            //Try to loop possible formats to decode date
            var i = 0;
            while(i < possibleDateFormatDecoders.count){
                formatter.dateFormat = possibleDateFormatDecoders[i]
                date = formatter.date(from: self)
                if (date != nil){
                    i = possibleDateFormatDecoders.count
                    break;
                }
                i+=1;
            }
        }
        return date
    }
    
    func isEmail() -> Bool{
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: self)
    }
        
    func isPhone() -> Bool{
        let value = self.filter("01234567890".contains)
        if value.count < 8{
            return false
        }
        return true
    }
    
    func preparePrice() -> String{
        //Check if dot exists
        var value = self
        if let index = value.lastIndex(of: "."){
            let pos = value.distance(from: value.startIndex, to: index)
            if (value.count - pos < 3){
                value = "\(value)0"
            }
        }else{
            value = "\(value).00"
        }
        return value
    }
    
    /**
        Format input (Seconds) as hours:mins:seconds (hide hours if hours == 0)
     */
    func toTime() -> String{
        //MARK: Get minutes & seconds from input
        let initial = Int(self) ?? 0
        
        //Extract hours
        var hours = initial / 3600
        //Extract minutes
        var mins = (initial % 3600) / 60
        //Extract seconds
        var seconds = (initial % 3600) % 60
        
        var output: Array<Int> = [mins,seconds]
        if (hours > 0){
            output.insert(hours, at: 0)
        }
        return output.map({ component in
            if(component < 10){
                return "0\(component)"
            }
            return String(component)
        }).joined(separator: ":")
    }
}

extension Formatter {
    static let withSeparator: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter
    }()
}

extension Numeric {
    var formattedWithSeparator: String { Formatter.withSeparator.string(for: self) ?? ""}
}

extension Encodable{
    func toJSON() -> Data?{
        return try? JSONEncoder().encode(self)
    }
}

extension Data {
    func pkce_base64EncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
    
    mutating func append(
        _ string: String,
        encoding: String.Encoding = .utf8
    ) {
        guard let data = string.data(using: encoding) else {
            return
        }
        append(data)
    }
}

struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

extension View{
    func pageView() -> some View{
        self.frame(width: getScreenBounds().width, alignment: .center)
    }
    
    func getScreenBounds()->CGRect{
        return UIScreen.main.bounds
    }
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

protocol ApplicationView{
    var Store: ApplicationStore { get }
    var Error: ErrorHandlingService { get }
}

protocol AuthentificationView: ApplicationView, View{
    var logout: Bool { get set }
}

extension AuthentificationView{
    func addAuthentificationStubs() -> some View{
        return ZStack{
            self.onChange(of: self.Store.user.user_id, perform: { _ in
                //Logout called
                if (self.Store.user.user_id == nil){
                    
                }
            })
        }
    }
}

extension Color{
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    enum CustomColorScheme{
        case auto
        case light
        case dark
    }
    
    enum Colors: String{
        /// Green color - for active elements
        case Active
        /// Blue color - for pending status
        case Pending
        ///Red color - for danger elements
        case Danger
        ///Text default
        case Text
        ///Application background
        case Background
        ///Secondary text
        case LightGray
        case MiddleGray
        ///Disabled text
        case DisabledText
        ///Disabled element fill background
        case Disabled
        case Section
        case BackgroundInput
        ///Application primary color
        case Primary
        case Divider
        case PaleBlack
        case Ocean
        case PopupOverlay
        case CardSecondary
        case Gray
        case TextOnPrimary
    }
    
    static func get(_ color: Colors, scheme: CustomColorScheme = .auto) -> Color{
        var name = color.rawValue
        if (scheme == .light){
            name = "Light\(name)Appearance"
        }
        if (scheme == .dark){
            name = "Dark\(name)Appearance"
        }
        return Color(name)
    }
}

extension Collection {
    func unfoldSubSequences(limitedTo maxLength: Int) -> UnfoldSequence<SubSequence,Index> {
        sequence(state: startIndex) { start in
            guard start < endIndex else { return nil }
            let end = index(start, offsetBy: maxLength, limitedBy: endIndex) ?? endIndex
            defer { start = end }
            return self[start..<end]
        }
    }

    func every(n: Int) -> UnfoldSequence<Element,Index> {
        sequence(state: startIndex) { index in
            guard index < endIndex else { return nil }
            defer { let _ = formIndex(&index, offsetBy: n, limitedBy: endIndex) }
            return self[index]
        }
    }

    var pairs: [SubSequence] { .init(unfoldSubSequences(limitedTo: 2)) }
}

extension StringProtocol where Self: RangeReplaceableCollection {

    mutating func insert<S: StringProtocol>(separator: S, every n: Int) {
        for index in indices.every(n: n).dropFirst().reversed() {
            insert(contentsOf: separator, at: index)
        }
    }

    func inserting<S: StringProtocol>(separator: S, every n: Int) -> Self {
        .init(unfoldSubSequences(limitedTo: n).joined(separator: separator))
    }
}

struct ViewControllerHolder {
    weak var value: UIViewController?
}

struct ViewControllerKey: EnvironmentKey {
    static var defaultValue: ViewControllerHolder {
        return ViewControllerHolder(value: UIApplication.shared.windows.first?.rootViewController)

    }
}

extension EnvironmentValues {
    var viewController: UIViewController? {
        get { return self[ViewControllerKey.self].value }
        set { self[ViewControllerKey.self].value = newValue }
    }
}

extension Binding where Value == String{
    func limit(_ length: Int) -> Self{
        if (self.wrappedValue.count > length){
            DispatchQueue.main.async{
                self.wrappedValue = String(self.wrappedValue.prefix(length))
            }
        }
        return self
    }
}

struct Extensions_Previews: PreviewProvider {
    static var previews: some View {
        let amount: Float = 1.0089663e+08
        VStack{
            Text(String(Double(amount)).formatAsPrice("$"))
        }.onAppear{
            
        }
    }
}

extension Notification.Name{
    static let AuthenticationStateChange = Notification.Name("AuthenticationStateChange")
    static let UserIdChange = Notification.Name("UserIdChange")
    static let Logout = Notification.Name("Logout")
    static let Activity = Notification.Name("Activity")
    static let Inactive = Notification.Name("Inactive")
    static let DeepLinkLogin = Notification.Name("DeepLinkLogin")
    static let Maintenance = Notification.Name("Maintenance")
    static let AppVersion = Notification.Name("AppVersion")
    static let ScheduleMaintenanceCheck = Notification.Name("ScheduleMaintenanceCheck")
    static let detectedObjectsUpdated = Notification.Name("detectedObjectsUpdated")
}

extension URL {

    func appending(_ queryItem: String, value: String?) -> URL {

        guard var urlComponents = URLComponents(string: absoluteString) else { return absoluteURL }

        // Create array of existing query items
        var queryItems: [URLQueryItem] = urlComponents.queryItems ??  []

        // Create query item
        let queryItem = URLQueryItem(name: queryItem, value: value)

        // Append the new query item in the existing query items array
        queryItems.append(queryItem)

        // Append updated query items array in the url component object
        urlComponents.queryItems = queryItems

        // Returns the url from new url components
        return urlComponents.url!
    }
}

extension CGSize {
    static func aspectFit(aspectRatio : CGSize, boundingSize: CGSize) -> (size: CGSize, xOffset: CGFloat, yOffset: CGFloat)  {
        let mW = boundingSize.width / aspectRatio.width;
        let mH = boundingSize.height / aspectRatio.height;
        var fittedWidth = boundingSize.width
        var fittedHeight = boundingSize.height
        var xOffset = CGFloat(0.0)
        var yOffset = CGFloat(0.0)

        if( mH < mW ) {
            fittedWidth = boundingSize.height / aspectRatio.height * aspectRatio.width;
            xOffset = abs(boundingSize.width - fittedWidth)/2
            
        }
        else if( mW < mH ) {
            fittedHeight = boundingSize.width / aspectRatio.width * aspectRatio.height;
            yOffset = abs(boundingSize.height - fittedHeight)/2
            
        }
        let size = CGSize(width: fittedWidth, height: fittedHeight)
        
        return (size, xOffset, yOffset)
    }
    
    static func aspectFill(aspectRatio :CGSize, minimumSize: CGSize) -> CGSize {
        let mW = minimumSize.width / aspectRatio.width;
        let mH = minimumSize.height / aspectRatio.height;
        var minWidth = minimumSize.width
        var minHeight = minimumSize.height
        if( mH > mW ) {
            minWidth = minimumSize.height / aspectRatio.height * aspectRatio.width;
        }
        else if( mW > mH ) {
            minHeight = minimumSize.width / aspectRatio.width * aspectRatio.height;
        }
        
        return CGSize(width: minWidth, height: minHeight)
    }
}

extension Dictionary {
    mutating func merge(_ with: [Key: Value]){
        for (k, v) in with {
            updateValue(v, forKey: k)
        }
    }
}
