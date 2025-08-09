//
//  ToolTip.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 15.01.2024.
//

import Foundation
import SwiftUI

public enum ToolTipSide: Int {
    case center = -1
    
    case left = 2
    case right = 6
    case top = 4
    case bottom = 0

    case topLeft = 3
    case topRight = 12
    case bottomLeft = 1
    case bottomRight = 7
    
    func getArrowAngleRadians() -> Optional<Double> {
        if self == .center { return nil }
        return Double(self.rawValue) * .pi / 4
    }
    
    func shouldShowArrow() -> Bool {
        if self == .center { return false }
        return true
    }
}

public enum ArrowType {
    case `default`, curveIn
}

public protocol ToolTipConfig{
    var side: ToolTipSide { get set }
    var index: Double {get set}
    
    var width: CGFloat? { get set }
    var height: CGFloat? { get set }
    
    var contentPaddingLeft: CGFloat {get set}
    var contentPaddingRight: CGFloat { get set }
    var contentPaddingTop: CGFloat { get set }
    var contentPaddingBottom: CGFloat { get set }
    
    var contentPadding: EdgeInsets { get }
    
    var arrowWidth: CGFloat { get set }
    var arrowHeight: CGFloat { get set }
    var arrowType: ArrowType { get set }
    
    var transition: AnyTransition { get set }
}

public struct DefaultToolTipConfig: ToolTipConfig{
    static var shared = DefaultToolTipConfig()
    
    public var side: ToolTipSide = .top
    public var index: Double = 10000
    
    public var width: CGFloat?
    public var height: CGFloat?
    
    public var contentPaddingLeft: CGFloat = 8
    public var contentPaddingRight: CGFloat = 8
    public var contentPaddingTop: CGFloat = 4
    public var contentPaddingBottom: CGFloat = 4

    public var contentPadding: EdgeInsets {
        EdgeInsets(
            top: contentPaddingTop,
            leading: contentPaddingLeft,
            bottom: contentPaddingBottom,
            trailing: contentPaddingRight
        )
    }
    
    public var arrowWidth: CGFloat = 12
    public var arrowHeight: CGFloat = 6
    public var arrowType: ArrowType = .default
    
    public var transition: AnyTransition = .opacity
    
    public init() {}

    public init(side: ToolTipSide) {
        self.side = side
    }
}

public struct CurveInArrowShape: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addQuadCurve(
            to: CGPoint(x: rect.width / 2, y: 0),
            control: CGPoint(x: rect.width * 0.4, y: rect.height)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: rect.height),
            control: CGPoint(x: rect.width * 0.6, y: rect.height)
        )
        return path
    }
}

public struct ArrowShape: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addLines([
            CGPoint(x: 0, y: rect.height),
            CGPoint(x: rect.width / 2, y: 0),
            CGPoint(x: rect.width, y: rect.height),
        ])
        return path
    }
}

public extension View{
    func tooltip<ToolTipContent: View>(
        @ViewBuilder content: @escaping () -> ToolTipContent
    ) -> some View{
        let config = DefaultToolTipConfig.shared
        return modifier(ToolTipModifier(config: config, content: content))
    }
    
    func tooltip<ToolTipContent: View>(
        config: ToolTipConfig,
        @ViewBuilder content: @escaping () -> ToolTipContent
    ) -> some View{
        let config = config
        return modifier(ToolTipModifier(config: config, content: content))
    }
    
    func tooltip<ToolTipContent: View>(
        side: ToolTipSide,
        @ViewBuilder content: @escaping () -> ToolTipContent
    ) -> some View{
        let config = DefaultToolTipConfig(side: side)
        return modifier(ToolTipModifier(config: config, content: content))
    }
}

struct ToolTipModifier<ToolTipContent: View>: ViewModifier{
    var config: ToolTipConfig
    var content: ToolTipContent
    
    @State private var contentWidth: CGFloat = 10
    @State private var contentHeight: CGFloat = 10
    @State private var origin: CGPoint = .zero
    
    var actualArrowHeight: CGFloat { config.arrowHeight }
    
    @State private var shown: Bool = false
    
    init(config: ToolTipConfig, @ViewBuilder content: @escaping () -> ToolTipContent) {
        self.config = config
        self.content = content()
    }
    
    private var sizeMeasurer: some View {
        GeometryReader { geometry in
            Text("")
                .onAppear {
                    var width = config.width ?? geometry.size.width
                    var height = config.height ?? geometry.size.height
                    
                    var maxWidth = UIScreen.main.bounds.width
                    var maxHeight = UIScreen.main.bounds.height
                    
                    self.contentWidth = width
                    self.contentHeight = height
                }
        }
    }
    
    private func offsetHorizontal(_ geometry: GeometryProxy) -> CGFloat {
        switch config.side {
        case .left, .topLeft, .bottomLeft:
            return -(contentWidth + actualArrowHeight + 0 + 0)
        case .right, .topRight, .bottomRight:
            return actualArrowHeight - 10
        case .top, .center, .bottom:
            return (geometry.size.width - contentWidth) / 2
        }
    }

    private func offsetVertical(_ geometry: GeometryProxy) -> CGFloat {
        switch config.side {
        case .top, .topRight, .topLeft:
            return -(contentHeight + actualArrowHeight + 0 + 0)
        case .bottom, .bottomLeft, .bottomRight:
            return geometry.size.height + actualArrowHeight + 0 + 0
        case .left, .center, .right:
            return (geometry.size.height - contentHeight) / 2
        }
    }
    
    var arrowOffsetX: CGFloat {
        switch config.side {
        case .bottom, .center, .top:
            return 0
        case .left:
            return (contentWidth / 2 + config.arrowHeight / 2)
        case .topLeft, .bottomLeft:
            return (contentWidth / 2
                + config.arrowHeight / 2
                - 0 / 2
                - 0 / 2)
        case .right:
            return -(contentWidth / 2 + config.arrowHeight / 2)
        case .topRight, .bottomRight:
            return -contentWidth / 2 + actualArrowHeight * 2 + 6
        }
    }

    var arrowOffsetY: CGFloat {
        switch config.side {
        case .left, .center, .right:
            return 0
        case .top:
            return (contentHeight / 2 + config.arrowHeight / 2)
        case .topRight, .topLeft:
            return (contentHeight / 2
                + config.arrowHeight / 2
                - 0 / 2
                - 0 / 2)
        case .bottom:
            return -(contentHeight / 2 + config.arrowHeight / 2)
        case .bottomLeft, .bottomRight:
            return -(contentHeight / 2
                + config.arrowHeight / 2
                - 0 / 2
                - 0 / 2)
        }
    }
    
    private var arrowView: some View {
        guard let arrowAngle = config.side.getArrowAngleRadians() else {
            return AnyView(EmptyView())
        }

        return AnyView(arrowShape(angle: arrowAngle)
            .background(arrowShape(angle: arrowAngle)
                .frame(width: config.arrowWidth, height: config.arrowHeight)
                .foregroundColor(Color("ToolTip"))
                .accentColor(Color("ToolTip"))
            ).frame(width: config.arrowWidth, height: config.arrowHeight)
            .offset(x: CGFloat(Int(self.arrowOffsetX)), y: CGFloat(Int(self.arrowOffsetY))))
    }
    
    private func arrowShape(angle: Double) -> AnyView {
        switch config.arrowType {
        case .default:
            let shape = ArrowShape()
                .rotation(Angle(radians: angle))
                .foregroundColor(Color("ToolTip"))
            return AnyView(shape)
        case .curveIn:
            let shape = CurveInArrowShape()
                .rotation(Angle(radians: angle))
            return AnyView(shape)
        }
    }
    
    var body: some View{
        GeometryReader{ geometry in
            Button{
                self.shown = false
            } label: {
                ZStack{
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: contentWidth, height: contentHeight)
                        .foregroundColor(Color("ToolTip"))
                    ZStack{}.background(
                        GeometryReader{ g in
                            Color("ToolTip")
                                .anchorPreference(key: ToolTipAnchorPreferenceKey.self,
                                    value: .bounds,
                                    transform: {ToolTipAnchorData(anchor: $0) })
                                .onPreferenceChange(ToolTipAnchorPreferenceKey.self) { data in
                                    self.origin = geometry[data.anchor!].origin
                                }
                        }
                    )
                    ZStack{
                        content
                            .multilineTextAlignment(.leading)
                            .padding(config.contentPadding)
                            .frame(
                                width: config.width,
                                height: config.height
                            )
                            .fixedSize(horizontal: config.width == nil, vertical: true)
                    }
                    .foregroundColor(Color("ToolTipColor"))
                    .background(self.sizeMeasurer)
                    .overlay(self.arrowView)
                }
            }
            .frame(width: contentWidth, height: contentHeight)
            .offset(x: self.offsetHorizontal(geometry), y: self.offsetVertical(geometry))
            .zIndex(config.index)
        }
    }
    
    func body(content: Content) -> some View{
        Button{
            self.shown = true
        } label: {
            content
        }.overlay(self.shown ? body.transition(config.transition).frame(maxWidth: .infinity): nil)
    }
}

struct ToolTip_Previews: PreviewProvider{
    static var previews: some View{
        var geometry = ScreenGeometry()
        let config = DefaultToolTipConfig(side: .topRight)
        
        return VStack{
            GeometryReader{ g in
                VStack{
                    Text("Bla").tooltip(config: config){
                        Text("SEPA Normal is Standard Bank Transfer processed within 2 business days.")
                    }.environmentObject(geometry)
                }.onAppear{
                    geometry.proxy = g
                }
            }
        }
    }
}

struct ToolTipAnchorData: Equatable {
    var anchor: Anchor<CGRect>? = nil
    static func == (lhs: ToolTipAnchorData, rhs: ToolTipAnchorData) -> Bool {
        return false
    }
}


struct ToolTipAnchorPreferenceKey: PreferenceKey {
    static let defaultValue = ToolTipAnchorData()
    static func reduce(value: inout ToolTipAnchorData, nextValue: () -> ToolTipAnchorData) {
        value.anchor = nextValue().anchor ?? value.anchor
    }
}


class ScreenGeometry: ObservableObject{
    @Published var proxy: GeometryProxy?
}
