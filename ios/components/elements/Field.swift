//
//  Field.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 18.11.2023.
//

import Foundation
import SwiftUI
import Combine

extension CustomField{
    enum FieldType{
        case text
        case number
        case textarea
        case date
        case select
        case password
        case price
        case phone
        case email
        case search
    }
    
    enum FieldState{
        case focused
        case normal
        case disabled
    }
    
    enum FieldDimensionPosition{
        case leading
        case trailing
    }
}

protocol CustomFieldConstructor{
}

extension CustomField{
    struct FormattedError{
        public var id: UUID = UUID()
        public var message: String
    }
}

struct ValidationRule{
    public var id: String;
    public var message: String = ""
    public var validate: (String)->Bool = { _ in true }
}

extension CustomFieldResponder{
    private var hasValue : Binding<Bool>{
        Binding(
            get:{
                return self.value.isEmpty == false
            },
            set:{ value in
                
            }
        )
    }
    private var fieldKeyboardType: UIKeyboardType{
        if self.keyboardType == nil{
            switch self.type{
            case .phone:
                return .phonePad
            case .price:
                return .decimalPad
            case .number:
                return .numberPad
            default:
                return .default
            }
        }
        return .default
    }
    var backgroundColor: Color{
        if (!self.isEnabled){
            return Color.get(.Disabled)
        }
        if (self.errors.count > 0){
            return Color.get(.Danger).opacity(0.1)
        }
        if self.hasValue.wrappedValue && self.state == .normal{
            return Color("LightGray").opacity(0.08)
        }
        return Color.clear
    }
    var outlineColor: Color{
        if (!self.isEnabled){
            return Color.get(.Disabled)
        }
        if (self.errors.count > 0){
            return Color.get(.Danger).opacity(0.1)
        }
        if self.hasValue.wrappedValue && self.state == .normal{
            return Color("LightGray").opacity(0.08)
        }
        switch self.state{
            case .normal:
                return Color("BorderInactive")
            case .disabled:
                return Color.get(.DisabledText)
            case .focused:
                return Whitelabel.Color(.Primary)
        }
    }
    var placeholderColor: Color{
        if (!self.isEnabled){
            return Color.get(.DisabledText)
        }
        if (self.errors.count > 0){
            return Color.get(.Danger)
        }
        switch self.state{
            case .normal:
                return Color("Placeholder")
            case .disabled:
                return Color.get(.DisabledText)
            case .focused:
                return Whitelabel.Color(.Primary)
        }
    }
}

struct CustomFieldResponder: View{
    @Binding var value: String
    @Binding var responder: Bool
    public var placeholder: String = ""
    public var type: CustomField.FieldType = .text
    
    public var showCancelButton: Bool = false
    public var options: [Option] = []
    public var searchable: Bool = false
    public var keyboardType: UIKeyboardType?
    
    public var preDimension: String?
    public var dimension: String?
    public var maxLength: Int = 0
    public var onQueryChanged: (String)->Void = { _ in }
    public var buildItem: (Option, String) -> any View = { (option, selected) in
        return Text(option.label)
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
            .padding(.horizontal,15)
            .padding(.vertical,20)
    }
    public var onItemSelect: (Option)->Void = { _ in }
    public var overrideSelect: Bool = false
    public var onEditingChanged: (Bool)->Void = { _ in }
    
    @State private var state: CustomField.FieldState = .normal
    @State private var displayModalForm: Bool = false
    @Environment(\.isEnabled) private var isEnabled
    @State private var errors: Array<String> = []
    @State public var dateRangeFrom: PartialRangeFrom<Date>? = nil
    @State public var dateRangeThrough: PartialRangeThrough<Date>? = ...Date.now
    @State public var validationRules: Array<ValidationRule> = []
    @State public var paddings: Array<Double> = [0,0,0,0]
    @State public var focused: Bool = false
    
    var label: some View{
        Text(self.placeholder)
            .font(self.hasValue.wrappedValue ? .caption : .subheadline)
            .padding(.horizontal,self.hasValue.wrappedValue ? 4 : 10)
            .offset(
                x: self.hasValue.wrappedValue ? 6 + (self.dimensionLeading != nil ? 30 : 0) : 0 + (self.dimensionLeading != nil ? 30 : 0),
                y: self.hasValue.wrappedValue ? 5 : 16
            )
            .zIndex(self.hasValue.wrappedValue ? 2 : 2)
            .animation(.easeInOut(duration:0.15), value: self.hasValue.wrappedValue)
            .frame(alignment:.topLeading)
            .foregroundColor(self.placeholderColor)
    }
    
    var fieldPaddingLeading: CGFloat{
        return 10 + (self.dimensionLeading != nil ? 40 : 0)
    }
    
    var dimensionLeading: String?{
        return self.preDimension
    }
    
    var fieldPaddingTrailing: CGFloat{
        return 5 + (self.dimension != nil ? 50 : 0) + (self.paddings[3] ?? 0)
    }
    
    var dimensionTrailing: String?{
        return self.dimension
    }
    
    var formattedErrors: Array<CustomField.FormattedError>{
        if (self.errors.count > 0){
            return self.errors.map({error in
                return CustomField.FormattedError(
                    id: UUID(),
                    message: error
                )
            })
        }
        return []
    }
    
    var body: some View {
        VStack{
            ZStack(alignment: .leading){
                HStack{
                    CustomFieldContainer(
                        type: self.type,
                        value: self.$value,
                        responder: self.$responder,
                        onEditingChanged: {editingChanged in
                            if editingChanged{
                                self.state = .focused
                            }else{
                                self.state = .normal
                            }
                            self.onEditingChanged(editingChanged)
                        },
                        options: self.options,
                        searchable: self.searchable,
                        keyboardType: self.fieldKeyboardType,
                        onQueryChanged: self.onQueryChanged,
                        buildItem: self.buildItem,
                        onItemSelect: self.onItemSelect,
                        overrideSelect: self.overrideSelect,
                        padding: [
                            self.placeholder.isEmpty ? 15 : 15,
                            self.fieldPaddingTrailing,
                            self.placeholder.isEmpty ? 20 : 15,
                            self.fieldPaddingLeading
                        ],
                        errors: self.$errors,
                        dateRangeFrom: self.$dateRangeFrom,
                        dateRangeThrough: self.$dateRangeThrough,
                        validationRules: self.$validationRules
                    )
                        .onReceive(Just(value), perform: { _ in
                            if (self.maxLength != nil && self.maxLength > 0){
                                value = String(value.prefix(self.maxLength))
                            }
                            if (self.type == .email){
                                value = value.trimmingCharacters(in: .whitespacesAndNewlines)
                            }else if(self.type == .phone){
                                value = value.trimmingCharacters(in: .whitespacesAndNewlines)
                            }else if(self.type == .price){
                                let input = value
                                //Check if dot in value exists and after dot only one symbol
                                //First, remove all non digit chars
                                var modified = value.filter("01234567890".contains)
                                //Check if value contains only 0, that case replace to empty string
                                //Second, depending on value length apply different masks
                                if (modified.count < 3){
                                    if (modified.count == 0){
                                        modified = ""
                                    }else if(modified.count == 1){
                                        modified = "0.0\(modified)"
                                    }else{
                                        modified = "0.\(modified)"
                                    }
                                }else{
                                    //Last 2 digits - coins, extract them
                                    let end = String(modified.suffix(2))
                                    //Get rest of value
                                    modified = String(modified.dropLast(2))
                                    //Add delimiters
                                    modified = Double(String((modified as NSString).doubleValue))!.formattedWithSeparator
                                    modified = "\(modified).\(end)"
                                }
                                if (modified != input){
                                    self.value = modified
                                }
                                /*
                                 value = String(value.replacingOccurrences(of: ",", with: "."))
                                value = value.filter("01234567890.".contains)
                                if let index = value.firstIndex(of: "."){
                                    let pos = value.distance(from: value.startIndex, to: index)
                                    value = String(value.prefix(pos+3))
                                }
                                 */
                            }
                        })
                        .disabled(!self.isEnabled)
                        .multilineTextAlignment(.leading)
                    /*
                     padding: [self.placeholder.isEmpty ? 20 : 25, self.fieldPaddingTrailing,self.placeholder.isEmpty ? 20 : 15,self.fieldPaddingLeading]
                     */
                        .background(
                            RoundedRectangle(cornerRadius: 9)
                                .foregroundColor(self.backgroundColor)
                                .zIndex(0)
                        )
                        .overlay(
                            ZStack{
                                if (self.dimension != nil){
                                    ZStack{
                                        Text(self.dimension!)
                                            .font(.callout)
                                            .foregroundColor(self.isEnabled ? Color.get(.LightGray) : Color.get(.DisabledText))
                                            .padding(.leading, 5)
                                            .padding(.trailing, 5)
                                    }
                                    .frame(maxWidth: 50)
                                }
                            }
                            , alignment: .trailing
                        )
                }
                if (self.dimensionLeading != nil){
                    ZStack{
                        Text(self.dimensionLeading!)
                            .font(.callout)
                            .foregroundColor(self.isEnabled ? Color.get(.LightGray) : Color.get(.DisabledText))
                            .padding(.leading, 5)
                    }.frame(maxWidth: 40)
                }
            }
            .overlay(
                self.label
                .zIndex(12)
                .onTapGesture{
                    self.responder = true
                }
                ,alignment: .topLeading
            )
            .overlay(
                ZStack{
                    RoundedRectangle(cornerRadius:Styles.cornerRadius)
                        .stroke(self.outlineColor)
                        .padding(0)
                        .background(.clear)
                }
            )
            .overlay(
                ZStack{
                    if self.showCancelButton == true && self.hasValue.wrappedValue{
                        Button{
                            self.value = ""
                        } label: {
                            ZStack{
                                Image("cancel")
                            }
                            .frame(maxWidth: 40, maxHeight: 14)
                            .foregroundColor(Color("LightGray"))
                        }
                    }
                }
                ,alignment: .trailing
            )
            /*
            if (self.formattedErrors.count > 0){
                VStack(spacing:10){
                    ForEach(self.formattedErrors, id: \.id){ error in
                        Text(error.message)
                            .foregroundColor(Color.get(.Danger))
                    }
                }
            }*/
        }
        .frame(maxWidth:.infinity)
        .onAppear{
            self.validate()
        }
        .onChange(of: self.value){ _ in
            self.validate()
        }
    }
    
    func validate(){
        self.errors = []
        if (self.validationRules.count > 0){
            self.validationRules.forEach{ rule in
                if (rule.validate(self.value)==false){
                    self.errors.append(rule.message)
                }
            }
            /*
            if (!self.selectedOptionValid){
                //Check if error exists
                if (self.errors.first(where: {
                    if case .valueNotFound(let message) = $0{
                        return true
                    }
                    return false
                }) == nil){
                    self.errors.append(.valueNotFound(message: ""))
                }
            }else{
                self.errors.removeAll(where: {
                    if case .valueNotFound(let message) = $0{
                        return true
                    }
                    return false
                })
            }
             */
        }
    }
}

struct CustomField: View {
    @Binding var value: String
    @State var responder: Bool = false
    public var placeholder: String = ""
    public var type: CustomField.FieldType = .text
    
    public var showCancelButton: Bool = false
    public var options: [Option] = []
    public var searchable: Bool = false
    public var keyboardType: UIKeyboardType?
    
    public var preDimension: String?
    public var dimension: String?
    public var maxLength: Int = 0
    public var onQueryChanged: (String)->Void = { _ in }
    public var buildItem: (Option, String) -> any View = { (option, selected) in
        return Text(option.label)
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
            .padding(.horizontal,15)
            .padding(.vertical,20)
    }
    public var onItemSelect: (Option)->Void = { _ in }
    public var overrideSelect: Bool = false
    public var onEditingChanged: (Bool)->Void = { _ in }
    
    @State private var state: CustomField.FieldState = .normal
    @State private var displayModalForm: Bool = false
    @Environment(\.isEnabled) private var isEnabled
    @State private var errors: Array<String> = []
    @State public var dateRangeFrom: PartialRangeFrom<Date>? = nil
    @State public var dateRangeThrough: PartialRangeThrough<Date>? = ...Date.now
    @State public var validationRules: Array<ValidationRule> = []
    @State public var paddings: Array<Double> = [0,0,0,0]
    @State public var focused: Bool = false
    
    var label: some View{
        Text(self.placeholder)
            .font(self.hasValue.wrappedValue ? .caption : .subheadline)
            .padding(.horizontal,self.hasValue.wrappedValue ? 4 : 10)
            .offset(
                x: self.hasValue.wrappedValue ? 6 + (self.dimensionLeading != nil ? 30 : 0) : 0 + (self.dimensionLeading != nil ? 30 : 0),
                y: self.hasValue.wrappedValue ? 5 : 16
            )
            .zIndex(self.hasValue.wrappedValue ? 2 : 2)
            .animation(.easeInOut(duration:0.15), value: self.hasValue.wrappedValue)
            .frame(alignment:.topLeading)
            .foregroundColor(self.placeholderColor)
    }
    
    var fieldPaddingLeading: CGFloat{
        return 10 + (self.dimensionLeading != nil ? 40 : 0)
    }
    
    var dimensionLeading: String?{
        return self.preDimension
    }
    
    var fieldPaddingTrailing: CGFloat{
        return 5 + (self.dimension != nil ? 50 : 0) + (self.paddings[3] ?? 0)
    }
    
    var dimensionTrailing: String?{
        return self.dimension
    }
    
    var formattedErrors: Array<CustomField.FormattedError>{
        if (self.errors.count > 0){
            return self.errors.map({error in
                return FormattedError(
                    id: UUID(),
                    message: error
                )
            })
        }
        return []
    }
    
    var body: some View {
        VStack{
            ZStack(alignment: .leading){
                HStack{
                    CustomFieldContainer(
                        type: self.type,
                        value: self.$value,
                        responder: self.$responder,
                        onEditingChanged: {editingChanged in
                            if editingChanged{
                                self.state = .focused
                            }else{
                                self.state = .normal
                            }
                            self.onEditingChanged(editingChanged)
                        },
                        options: self.options,
                        searchable: self.searchable,
                        keyboardType: self.fieldKeyboardType,
                        onQueryChanged: self.onQueryChanged,
                        buildItem: self.buildItem,
                        onItemSelect: self.onItemSelect,
                        overrideSelect: self.overrideSelect,
                        padding: [
                            self.placeholder.isEmpty ? 15 : 15,
                            self.fieldPaddingTrailing,
                            self.placeholder.isEmpty ? 20 : 15, 
                            self.fieldPaddingLeading
                        ],
                        errors: self.$errors,
                        dateRangeFrom: self.$dateRangeFrom,
                        dateRangeThrough: self.$dateRangeThrough,
                        validationRules: self.$validationRules
                    )
                        .onReceive(Just(value), perform: { _ in
                            if (self.maxLength != nil && self.maxLength > 0){
                                value = String(value.prefix(self.maxLength))
                            }
                            if (self.type == .email){
                                value = value.trimmingCharacters(in: .whitespacesAndNewlines)
                            }else if(self.type == .phone){
                                value = value.trimmingCharacters(in: .whitespacesAndNewlines)
                            }else if(self.type == .price){
                                let input = value
                                //Check if dot in value exists and after dot only one symbol
                                //First, remove all non digit chars
                                var modified = value.filter("01234567890".contains)
                                //Check if value contains only 0, that case replace to empty string
                                //Second, depending on value length apply different masks
                                if (modified.count < 3){
                                    if (modified.count == 0){
                                        modified = ""
                                    }else if(modified.count == 1){
                                        modified = "0.0\(modified)"
                                    }else{
                                        modified = "0.\(modified)"
                                    }
                                }else{
                                    //Last 2 digits - coins, extract them
                                    let end = String(modified.suffix(2))
                                    //Get rest of value
                                    modified = String(modified.dropLast(2))
                                    //Add delimiters
                                    modified = Double(String((modified as NSString).doubleValue))!.formattedWithSeparator
                                    modified = "\(modified).\(end)"
                                }
                                if (modified != input){
                                    self.value = modified
                                }
                                /*
                                 value = String(value.replacingOccurrences(of: ",", with: "."))
                                value = value.filter("01234567890.".contains)
                                if let index = value.firstIndex(of: "."){
                                    let pos = value.distance(from: value.startIndex, to: index)
                                    value = String(value.prefix(pos+3))
                                }
                                 */
                            }
                        })
                        .disabled(!self.isEnabled)
                        .multilineTextAlignment(.leading)
                    /*
                     padding: [self.placeholder.isEmpty ? 20 : 25, self.fieldPaddingTrailing,self.placeholder.isEmpty ? 20 : 15,self.fieldPaddingLeading]
                     */
                        .background(
                            RoundedRectangle(cornerRadius: 9)
                                .foregroundColor(self.backgroundColor)
                                .zIndex(0)
                        )
                        .overlay(
                            ZStack{
                                if (self.dimension != nil){
                                    ZStack{
                                        Text(self.dimension!)
                                            .font(.callout)
                                            .foregroundColor(self.isEnabled ? Color.get(.LightGray) : Color.get(.DisabledText))
                                            .padding(.leading, 5)
                                            .padding(.trailing, 5)
                                    }
                                    .frame(maxWidth: 50)
                                }
                            }
                            , alignment: .trailing
                        )
                }
                if (self.dimensionLeading != nil){
                    ZStack{
                        Text(self.dimensionLeading!)
                            .font(.callout)
                            .foregroundColor(self.isEnabled ? Color.get(.LightGray) : Color.get(.DisabledText))
                            .padding(.leading, 5)
                    }.frame(maxWidth: 40)
                }
            }
            .overlay(
                self.label
                .zIndex(12)
                .onTapGesture{
                    self.responder = true
                }
                ,alignment: .topLeading
            )
            .overlay(
                ZStack{
                    RoundedRectangle(cornerRadius:Styles.cornerRadius)
                        .stroke(self.outlineColor)
                        .padding(0)
                        .background(.clear)
                }
            )
            .overlay(
                ZStack{
                    if self.showCancelButton == true && self.hasValue.wrappedValue{
                        Button{
                            self.value = ""
                        } label: {
                            ZStack{
                                Image("cancel")
                            }
                            .frame(maxWidth: 40, maxHeight: 14)
                            .foregroundColor(Color("LightGray"))
                        }
                    }
                }
                ,alignment: .trailing
            )
            /*
            if (self.formattedErrors.count > 0){
                VStack(spacing:10){
                    ForEach(self.formattedErrors, id: \.id){ error in
                        Text(error.message)
                            .foregroundColor(Color.get(.Danger))
                    }
                }
            }*/
        }
        .frame(maxWidth:.infinity)
        .onAppear{
            self.validate()
        }
        .onChange(of: self.value){ _ in
            self.validate()
        }
    }
    
    func validate(){
        self.errors = []
        if (self.validationRules.count > 0){
            self.validationRules.forEach{ rule in
                if (rule.validate(self.value)==false){
                    self.errors.append(rule.message)
                }
            }
            /*
            if (!self.selectedOptionValid){
                //Check if error exists
                if (self.errors.first(where: {
                    if case .valueNotFound(let message) = $0{
                        return true
                    }
                    return false
                }) == nil){
                    self.errors.append(.valueNotFound(message: ""))
                }
            }else{
                self.errors.removeAll(where: {
                    if case .valueNotFound(let message) = $0{
                        return true
                    }
                    return false
                })
            }
             */
        }
    }
}

fileprivate extension CustomField{
    private var hasValue : Binding<Bool>{
        Binding(
            get:{
                return self.value.isEmpty == false
            },
            set:{ value in
                
            }
        )
    }
}

fileprivate extension CustomField{
    var backgroundColor: Color{
        if (!self.isEnabled){
            return Color.get(.Disabled)
        }
        if (self.errors.count > 0){
            return Color.get(.Danger).opacity(0.1)
        }
        if self.hasValue.wrappedValue && self.state == .normal{
            return Color("LightGray").opacity(0.08)
        }
        return Color.clear
    }
    
    var outlineColor: Color{
        if (!self.isEnabled){
            return Color.get(.Disabled)
        }
        if (self.errors.count > 0){
            return Color.get(.Danger).opacity(0.1)
        }
        if self.hasValue.wrappedValue && self.state == .normal{
            return Color("LightGray").opacity(0.08)
        }
        switch self.state{
            case .normal:
                return Color("BorderInactive")
            case .disabled:
                return Color.get(.DisabledText)
            case .focused:
                return Whitelabel.Color(.Primary)
        }
    }
    
    var placeholderColor: Color{
        if (!self.isEnabled){
            return Color.get(.DisabledText)
        }
        if (self.errors.count > 0){
            return Color.get(.Danger)
        }
        switch self.state{
            case .normal:
                return Color("Placeholder")
            case .disabled:
                return Color.get(.DisabledText)
            case .focused:
                return Whitelabel.Color(.Primary)
        }
    }
}

fileprivate extension CustomField{
    private var fieldKeyboardType: UIKeyboardType{
        if self.keyboardType == nil{
            switch self.type{
            case .phone:
                return .phonePad
            case .price:
                return .decimalPad
            case .number:
                return .numberPad
            default:
                return .default
            }
        }
        return .default
    }
}

struct CustomFieldContainer: View{
    @State var type: CustomField.FieldType
    @Binding var value: String
    @Binding var responder: Bool
    var onEditingChanged: (Bool)->Void = { editingChanged in }
    public var options: [Option] = []
    public var searchable: Bool = false
    public var keyboardType: UIKeyboardType = .default
    public var onQueryChanged: (String)->Void = { _ in }
    public var buildItem: (Option, String) -> any View = { _,_  in
        return EmptyView()
    }
    public var onItemSelect: (Option)->Void = { _ in }
    public var overrideSelect: Bool = false
    public var padding: Array<CGFloat> = []
    
    @Binding var errors: Array<String>
    @Binding public var dateRangeFrom: PartialRangeFrom<Date>?
    @Binding public var dateRangeThrough: PartialRangeThrough<Date>?
    @Binding var validationRules: Array<ValidationRule>
    @Environment(\.isEnabled) private var isEnabled
    
    var body: some View{
        switch self.type{
        case .date:
            DateCustomField(
                value: self.$value,
                onEditingChanged: self.onEditingChanged,
                dateRangeFrom: self.$dateRangeFrom,
                dateRangeThrough: self.$dateRangeThrough,
                errors: self.$errors
            )
                .disabled(!self.isEnabled)
                .frame(height: 52)
                .padding(.leading, 10)
        case .select:
            SelectCustomField(
                value: self.$value,
                onEditingChanged: self.onEditingChanged,
                options: self.options,
                searchable: self.searchable,
                overrideSelect: self.overrideSelect,
                errors: self.$errors
            )
                .disabled(!self.isEnabled)
                .frame(height: 52)
                .padding(.leading, 10)
        case .password:
            PasswordCustomField(value: self.$value, onEditingChanged: self.onEditingChanged).disabled(!self.isEnabled)
        case .textarea:
            TextAreaField(
                value: self.$value,
                responder: self.$responder,
                onEditingChanged: self.onEditingChanged,
                keyboardType: self.keyboardType
            )
                .disabled(!self.isEnabled)
                //.frame(minHeight: 52)
                //.padding(.top, self.padding[0])
                .padding(.leading, self.padding[3]-5)
                .padding(.trailing, self.padding[1])
                .padding(.vertical, 8)
        case .search:
            SearchCustomField(value: self.$value, onEditingChanged: self.onEditingChanged, options: self.options, onQueryChanged: self.onQueryChanged, buildItem: self.buildItem, onItemSelect: self.onItemSelect)
                .disabled(!self.isEnabled)
                .frame(height: 52)
                .padding(.leading, 10)
        default:
            DefaultCustomField(
                value: self.$value,
                responder: self.$responder,
                onEditingChanged: self.onEditingChanged,
                keyboardType: self.keyboardType
            )
                .disabled(!self.isEnabled)
                .frame(height: 52)
                .padding(.leading, self.padding[3])
                .padding(.trailing, self.padding[1])
        }
    }
}

struct PasswordCustomField: View, CustomFieldConstructor{
    @Binding var value: String
    var onEditingChanged: (Bool)->Void = { editingChanged in }
    @Environment(\.isEnabled) private var isEnabled
    
    var password: Binding<String>{
        Binding(
            get: {
                return self.value.map{ _ in
                    return "*"
                }.joined(separator: "")
            },
            set: { value in
                self.value = value
            }
        )
    }
    
    var body: some View{
        ZStack{
            SecureField(" ", text: self.$value)
                .foregroundColor(self.isEnabled ? Color.get(.Text) : Color.get(.DisabledText))
        }
    }
}

struct DefaultCustomField: View, CustomFieldConstructor{
    @Binding var value: String
    @Binding var responder: Bool
    var onEditingChanged: (Bool)->Void = { editingChanged in }
    var keyboardType: UIKeyboardType  = .default
    @Environment(\.isEnabled) private var isEnabled
    
    var body: some View{
        CustomTextField(
            text: self.$value,
            isFirstResponder: self.$responder,
            onEditingChanged: self.onEditingChanged,
            keyboardType: self.keyboardType
        )
        /*
         TextField(" ", text: self.$value, onEditingChanged: self.onEditingChanged)
            .keyboardType(self.keyboardType)
            .foregroundColor(self.isEnabled ? Color.get(.Text) : Color.get(.DisabledText))
         */
    }
}

struct TextAreaField: View, CustomFieldConstructor{
    @Binding var value: String
    @Binding var responder: Bool
    var onEditingChanged: (Bool)->Void = { editingChanged in }
    var keyboardType: UIKeyboardType  = .default
    @Environment(\.isEnabled) private var isEnabled
    
    @State private var height: CGFloat = 0
    var body: some View{
        CustomTextArea(
            text: self.$value,
            calculatedHeight: self.$height,
            isFirstResponder: self.$responder,
            onEditingChanged: self.onEditingChanged,
            keyboardType: self.keyboardType
        )
            .frame(minHeight: self.height, maxHeight: self.height)
        /*
        TextEditor(text: self.$value)
            .background(Color.clear)
            .foregroundColor(self.isEnabled ? Color.get(.Text) : Color.get(.DisabledText))
            .padding(.leading, 10)
            .padding(.trailing, 10)
         */
    }
}

struct DateCustomField: View, CustomFieldConstructor{
    @Binding var value: String
    var onEditingChanged: (Bool)->Void = { editingChanged in }
    @Binding public var dateRangeFrom: PartialRangeFrom<Date>?
    @Binding public var dateRangeThrough: PartialRangeThrough<Date>?
    @Binding var errors: Array<String>
    
    @State private var sheetIsPresented: Bool = false
    @Environment(\.isEnabled) private var isEnabled
    
    var date: Binding<Date>{
        Binding(
            get: {
                if self.value.isEmpty{
                    return Date.now
                }
                
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withFullDate]
                let date = formatter.date(from: self.value) ?? .now
                
                return date
            },
            set: { value in
                var formatter = DateFormatter();
                formatter.dateFormat = "yyyy-MM-dd";
                var date = formatter.string(from: value)
                
                formatter.locale = NSLocale.current
                formatter.timeZone = TimeZone(abbreviation: "GMT+0:00")
                formatter.dateFormat = "yyyy-MM-dd"
                
                let stringFormatter = ISO8601DateFormatter()
                stringFormatter.formatOptions = [.withFullDate]
                self.value = stringFormatter.string(from: formatter.date(from: date)!)
            }
        )
    }
    
    var valid: Bool {
        return self.errors.isEmpty
    }
    
    var body: some View{
        Button{
            //Unfocus fields
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
            self.sheetIsPresented = true
        } label:{
            ZStack{
                Text(self.value)
                    .frame(maxWidth:.infinity, alignment:.leading)
                    .foregroundColor(self.isEnabled ? (self.valid ? Color.get(.Text) : Color.get(.Danger)) : Color.get(.DisabledText))
                BottomSheetContainer(isPresented:self.$sheetIsPresented){
                    VStack(spacing:10){
                        HStack(alignment:.center){
                            if (self.dateRangeFrom != nil){
                                DatePicker(selection: self.date, in: self.dateRangeFrom!, displayedComponents: .date){
                                    EmptyView()
                                }
                                //.preferredColorScheme(.dark)
                                .colorScheme(.light)
                                .labelsHidden()
                                .datePickerStyle(.wheel)
                                .padding(0)
                            }else if (self.dateRangeThrough != nil){
                                DatePicker(selection: self.date, in: self.dateRangeThrough!, displayedComponents: .date){
                                    EmptyView()
                                }
                                //.preferredColorScheme(.dark)
                                .colorScheme(.light)
                                .labelsHidden()
                                .datePickerStyle(.wheel)
                                .padding(0)
                            }else{
                                DatePicker(selection: self.date, displayedComponents: .date){
                                    EmptyView()
                                }
                                //.preferredColorScheme(.dark)
                                .colorScheme(.light)
                                .labelsHidden()
                                .datePickerStyle(.wheel)
                                .padding(0)
                            }
                        }
                        Button("OK"){
                            self.sheetIsPresented = false
                        }
                            .buttonStyle(.primary())
                            .padding(.horizontal, 20)
                    }
                }
            }
            .frame(maxWidth:.infinity, maxHeight: .infinity)
        }
        .onAppear{
            if (self.value.isEmpty == false){
                self.date.wrappedValue = self.date.wrappedValue
            }
        }
    }
}

struct SelectCustomField: View, CustomFieldConstructor{
    @Binding var value: String
    var onEditingChanged: (Bool)->Void = { editingChanged in }
    public var options: [Option] = []
    public var searchable: Bool = false
    
    @State private var sheetIsPresented: Bool = false
    @State private var query: String = ""
    public var overrideSelect: Bool = false
    @Binding var errors: Array<String>
    
    @Environment(\.isEnabled) private var isEnabled
    
    var queriedOptions: [Option] {
        if self.query.isEmpty{
            return self.options
        }
        let query = self.query.lowercased()
        return self.options.filter({$0.label.lowercased().contains(query)})
    }
    
    var list: some View{
        ForEach(self.queriedOptions, id: \.id){ option in
            Button{
                self.value = option.id
                self.sheetIsPresented = false
            } label:{
                Text(option.label)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal,15)
                    .padding(.vertical,20)
            }
            .background(option.id == self.value ? Whitelabel.Color(.Primary).opacity(0.3) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 9))
            .padding(.horizontal,20)
            .foregroundColor(Color("Text"))
        }
    }
    
    var selectedOption: Option?{
        if self.selectedOptionValid{
            let index = self.options.firstIndex(where: {$0.id == self.value})
            if index != nil{
                return self.options[index!]
            }
        }
        
        return .init(
            id: "",
            label: self.value
        )
    }
    
    var selectedOptionValid: Bool{
        if self.value.isEmpty == false{
            let index = self.options.firstIndex(where: {$0.id == self.value})
            if index != nil{
                return true
            }
        }
        
        return false
    }
    
    /*
    func validate(){
        if (self.validationRules.count > 0){
            if (!self.selectedOptionValid){
                //Check if error exists
                if (self.errors.first(where: {
                    if case .valueNotFound(let message) = $0{
                        return true
                    }
                    return false
                }) == nil){
                    self.errors.append(.valueNotFound(message: ""))
                }
            }else{
                self.errors.removeAll(where: {
                    if case .valueNotFound(let message) = $0{
                        return true
                    }
                    return false
                })
            }
        }
    }
     */
    
    var body: some View{
        Group{
            if (self.overrideSelect){
                ZStack{
                    Text(self.selectedOption?.label ?? "")
                        .foregroundColor(self.isEnabled ? Color.get(.Text) : Color.get(.DisabledText))
                        .frame(maxWidth:.infinity, alignment:.leading)
                        .font(.subheadline)
                        .lineLimit(1)
                        .padding(.trailing, 48)
                }
                .frame(maxWidth:.infinity, maxHeight: .infinity)
            }else{
                Button{
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
                    self.sheetIsPresented = true
                } label:{
                    ZStack{
                        Text(self.selectedOption?.label ?? "")
                            .foregroundColor(self.isEnabled ? (self.selectedOptionValid ? Color.get(.Text) : Color.get(.Danger)) : Color.get(.DisabledText))
                            .frame(maxWidth:.infinity, alignment:.leading)
                            .font(.subheadline)
                            .multilineTextAlignment(.leading)
                            .lineLimit(1)
                            .padding(.trailing, 48)
                    }
                    .frame(maxWidth:.infinity, maxHeight: .infinity)
                }
            }
        }.sheet(isPresented: self.$sheetIsPresented){
            VStack{
                if self.searchable{
                    SearchField(query: self.$query)
                    .padding()
                }
                ScrollView{
                    self.list
                        .padding(.vertical, 12)
                }
                Spacer()
            }
        }.overlay(
            ZStack{
                Image("arrow-d")
                    .resizable()
                    .scaledToFit()
                    .offset(y: -4)
            }
                .frame(maxWidth: 16)
                .padding(.trailing,20)
            , alignment: .trailingFirstTextBaseline
        )
    }
}

struct SearchCustomField: View, CustomFieldConstructor{
    @Binding var value: String
    var onEditingChanged: (Bool)->Void = { editingChanged in }
    public var options: [Option] = []
    public var onQueryChanged: (String)->Void = { _ in }
    public var buildItem: (Option, String) -> any View = { _, _ in
        return EmptyView()
    }
    public var onItemSelect: (Option)->Void = { _ in }
    
    @State private var sheetIsPresented: Bool = false
    @State private var query: String = ""
    @Environment(\.isEnabled) private var isEnabled
    
    var list: some View{
        ForEach(self.options, id: \.id){ option in
            Button{
                self.value = option.id
                self.onItemSelect(option)
                self.sheetIsPresented = false
            } label:{
                AnyView(self.buildItem(option, self.value))
            }
            .background(option.id == self.value ? Whitelabel.Color(.Primary).opacity(0.3) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 9))
            .padding(.horizontal,20)
            .foregroundColor(Color("Text"))
        }
    }
    
    var selectedOption: Option?{
        if self.value.isEmpty == false{
            let index = self.options.firstIndex(where: {$0.id == self.value})
            if index != nil{
                return self.options[index!]
            }
        }
        return .init(
            id: "",
            label: self.value
        )
    }
    
    var body: some View{
        Button{
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
            self.sheetIsPresented = true
        } label:{
            ZStack{
                Text(self.selectedOption?.label ?? "")
                    .foregroundColor(self.isEnabled ? Color.get(.Text) : Color.get(.DisabledText))
                    .frame(maxWidth:.infinity, alignment:.leading)
                    .font(.subheadline)
                    .lineLimit(1)
                    .padding(.trailing, 48)
            }
            .frame(maxWidth:.infinity, maxHeight: .infinity)
        }.sheet(isPresented: self.$sheetIsPresented){
            VStack{
                SearchField(query: self.$query)
                .padding()
                if self.query.isEmpty == false{
                    ScrollView{
                        self.list
                    }
                    Spacer()
                }else{
                    Spacer()
                    Image("search-splash")
                    Text("Search  result will appear here")
                        .foregroundColor(Color("LightGray"))
                        .font(.subheadline)
                    Spacer()
                }
            }
        }.overlay(
            ZStack{
                Image("arrow-d")
                    .resizable()
                    .scaledToFit()
                    .offset(y: -4)
            }
                .frame(maxWidth: 16)
                .padding(.trailing,20)
            , alignment: .trailingFirstTextBaseline
        )
        .onChange(of: self.query, perform: self.onQueryChanged)
    }
}

struct SearchField: View , CustomFieldConstructor{
    @Binding var query: String
    @Environment(\.isEnabled) private var isEnabled
    
    var body: some View {
        HStack{
            ZStack{
                TextField("Search", text: self.$query)
                    .padding(10)
                    .padding(.leading, 25)
                    .background(RoundedRectangle(cornerRadius: 9).foregroundColor(Color("LightGray").opacity(0.08)))
                    .foregroundColor(self.isEnabled ? Color.get(.Text) : Color.get(.DisabledText))
            }.overlay(
                ZStack{
                    RoundedRectangle(cornerRadius:Styles.cornerRadius)
                        .stroke(Color("LightGray").opacity(0.1))
                        .padding(0)
                }
            )
            .overlay(
                ZStack{
                    Image("search")
                        .foregroundColor(Color("LightGray"))
                }
                    .frame(width: 20, height: 20)
                    .padding(.top,2)
                    .padding(.leading,10)
                ,alignment: .leading
            )
            if self.query.isEmpty == false{
                Button{
                    self.query = ""
                } label:{
                    Text("Cancel")
                        .padding(.horizontal,5)
                        .foregroundColor(
                            Whitelabel.Color(.Primary)
                        )
                }
            }
        }
    }
}

struct CustomFieldParent: View{
    @StateObject private var PresentationController: ApplicationPresentationController = ApplicationPresentationController()
    
    @State private var value1: String = "Ты в городе, а у меня дом в Алёшках. Пол беды что сами по себе Алёшки отшиб, дык е"
    @State private var value2: String = ""
    @State private var value3: String = ""
    @State private var value4: String = ""
    @State private var value5: String = "ua"
    @State private var value6: String = ""
    @State private var value7: String = ""
    @State private var value8: String = ""
    @State private var value9: String = "Ты в городе, а у меня дом в Алёшках. Пол беды что сами по себе Алёшки отшиб, дык е"
    @State private var value10: String = ""
    @State private var value11: String = "123123"

    @State private var qu: String = ""
    @State private var isDisabled: Bool = false
    
    var options: [Option]{
        var list: [Option] = [
            .init(id: "0", label: "Initial")
        ]
        if (!self.qu.isEmpty){
            list = [.init(id: "1", label: self.qu)]
        }
        return list
    }
    
    func QueryChanged(_ query: String){
        self.qu = query
    }
    
    var body: some View{
        ZStack{
            ScrollView{
                VStack(alignment: .leading){
                    Button("Toogle disabled [\(self.isDisabled ? "ON" : "OFF")]"){
                        self.isDisabled = !self.isDisabled
                    }
                    VStack{
                        CustomField(value:self.$value1, placeholder: "Field 1")
                            .disabled(self.isDisabled)
                        Text("Default field").font(.caption).frame(maxWidth: .infinity,alignment: .leading)
                    }
                    VStack{
                        CustomField(value:self.$value2, placeholder: "Field 2", showCancelButton: true)
                            .disabled(self.isDisabled)
                        Text("With cancel button").font(.caption).frame(maxWidth: .infinity,alignment: .leading)
                    }
                    VStack{
                        CustomField(value:self.$value10, placeholder: "Field 9", type: .textarea)
                            .disabled(self.isDisabled)
                        Text("Text field").font(.caption).frame(maxWidth: .infinity,alignment: .leading)
                    }
                    VStack{
                        CustomField(value:self.$value9, placeholder: "Field 9", type: .textarea)
                            .disabled(self.isDisabled)
                        Text("Text field").font(.caption).frame(maxWidth: .infinity,alignment: .leading)
                    }
                    VStack{
                        CustomField(value:self.$value4, placeholder: "Field 4", type: .date)
                            .disabled(self.isDisabled)
                        Text("Date field").font(.caption).frame(maxWidth: .infinity,alignment: .leading)
                    }
                    VStack{
                        CustomField(value:self.$value7, placeholder: "Field 7", type: .search, options: self.options, onQueryChanged: self.QueryChanged)
                            .disabled(self.isDisabled)
                        Text("Search field").font(.caption).frame(maxWidth: .infinity,alignment: .leading)
                    }
                    VStack{
                        CustomField(
                            value:self.$value11,
                            placeholder: "Field 11",
                            type: .select,
                            options: [
                                .init(id: "1", label: "Option 1"),
                                .init(id: "2", label: "Option 2"),
                                .init(id: "3", label: "Option 3"),
                                .init(id: "4", label: "Option 4"),
                                .init(id: "5", label: "Option 5"),
                                .init(id: "6", label: "Option 6"),
                                .init(id: "7", label: "Option 7"),
                                .init(id: "8", label: "Option 8"),
                                .init(id: "9", label: "Option 9"),
                                .init(id: "ua", label: "Ukraine areas of Ukraine with long name and some more words"),
                                .init(id: "10", label: "Option 10"),
                                .init(id: "11", label: "Option 11"),
                                .init(id: "12", label: "Option 12"),
                                .init(id: "13", label: "Option 13"),
                                .init(id: "14", label: "Option 14"),
                                .init(id: "15", label: "Option 15"),
                                .init(id: "16", label: "Option 16"),
                                .init(id: "17", label: "Option 17"),
                                .init(id: "18", label: "Option 18"),
                                .init(id: "19", label: "Option 19"),
                            ],
                            searchable: true
                        )
                        .disabled(self.isDisabled)
                        Text("Dropdown field with error").font(.caption).frame(maxWidth: .infinity,alignment: .leading)
                    }
                    VStack{
                        CustomField(value:self.$value5, placeholder: "Field 5", type: .select, options: [
                            .init(id: "1", label: "Option 1"),
                            .init(id: "2", label: "Option 2"),
                            .init(id: "3", label: "Option 3"),
                            .init(id: "4", label: "Option 4"),
                            .init(id: "5", label: "Option 5"),
                            .init(id: "6", label: "Option 6"),
                            .init(id: "7", label: "Option 7"),
                            .init(id: "8", label: "Option 8"),
                            .init(id: "9", label: "Option 9"),
                            .init(id: "ua", label: "Ukraine areas of Ukraine with long name and some more words"),
                            .init(id: "10", label: "Option 10"),
                            .init(id: "11", label: "Option 11"),
                            .init(id: "12", label: "Option 12"),
                            .init(id: "13", label: "Option 13"),
                            .init(id: "14", label: "Option 14"),
                            .init(id: "15", label: "Option 15"),
                            .init(id: "16", label: "Option 16"),
                            .init(id: "17", label: "Option 17"),
                            .init(id: "18", label: "Option 18"),
                            .init(id: "19", label: "Option 19"),
                        ], searchable: true)
                        .disabled(self.isDisabled)
                        Text("Dropdown field").font(.caption).frame(maxWidth: .infinity,alignment: .leading)
                    }
                    VStack{
                        CustomField(value:self.$value6, placeholder: "Field 6", type: .password)
                            .disabled(self.isDisabled)
                        Text("Password: \(self.value6)").font(.caption).frame(maxWidth: .infinity,alignment: .leading)
                        Text("Password field").font(.caption).frame(maxWidth: .infinity,alignment: .leading)
                    }
                    VStack{
                        CustomField(value:self.$value8, placeholder: "Field 8", type: .price, preDimension: "$")
                            .disabled(self.isDisabled)
                        Text("Price field").font(.caption).frame(maxWidth: .infinity,alignment: .leading)
                    }
                }.padding()
            }
            
        }
    }
}

struct CustomField_Previews: PreviewProvider {
    static var previews: some View {
        CustomFieldParent()
    }
}
