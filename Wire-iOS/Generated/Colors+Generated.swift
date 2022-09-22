// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

#if os(macOS)
  import AppKit
#elseif os(iOS)
  import UIKit
#elseif os(tvOS) || os(watchOS)
  import UIKit
#endif

// Deprecated typealiases
@available(*, deprecated, renamed: "ColorAsset.Color", message: "This typealias will be removed in SwiftGen 7.0")
internal typealias AssetColorTypeAlias = ColorAsset.Color

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Asset Catalogs

// swiftlint:disable identifier_name line_length nesting type_body_length type_name
internal enum Asset {
  internal static let amber100Dark = ColorAsset(name: "Amber100Dark")
  internal static let amber100Light = ColorAsset(name: "Amber100Light")
  internal static let amber200Dark = ColorAsset(name: "Amber200Dark")
  internal static let amber200Light = ColorAsset(name: "Amber200Light")
  internal static let amber300Dark = ColorAsset(name: "Amber300Dark")
  internal static let amber300Light = ColorAsset(name: "Amber300Light")
  internal static let amber400Dark = ColorAsset(name: "Amber400Dark")
  internal static let amber400Light = ColorAsset(name: "Amber400Light")
  internal static let amber500Dark = ColorAsset(name: "Amber500Dark")
  internal static let amber500Light = ColorAsset(name: "Amber500Light")
  internal static let amber50Dark = ColorAsset(name: "Amber50Dark")
  internal static let amber50Light = ColorAsset(name: "Amber50Light")
  internal static let amber600Dark = ColorAsset(name: "Amber600Dark")
  internal static let amber600Light = ColorAsset(name: "Amber600Light")
  internal static let amber700Dark = ColorAsset(name: "Amber700Dark")
  internal static let amber700Light = ColorAsset(name: "Amber700Light")
  internal static let amber800Dark = ColorAsset(name: "Amber800Dark")
  internal static let amber800Light = ColorAsset(name: "Amber800Light")
  internal static let amber900Dark = ColorAsset(name: "Amber900Dark")
  internal static let amber900Light = ColorAsset(name: "Amber900Light")
  internal static let black = ColorAsset(name: "Black")
  internal static let blue100Dark = ColorAsset(name: "Blue100Dark")
  internal static let blue100Light = ColorAsset(name: "Blue100Light")
  internal static let blue200Dark = ColorAsset(name: "Blue200Dark")
  internal static let blue200Light = ColorAsset(name: "Blue200Light")
  internal static let blue300Dark = ColorAsset(name: "Blue300Dark")
  internal static let blue300Light = ColorAsset(name: "Blue300Light")
  internal static let blue400Dark = ColorAsset(name: "Blue400Dark")
  internal static let blue400Light = ColorAsset(name: "Blue400Light")
  internal static let blue500Dark = ColorAsset(name: "Blue500Dark")
  internal static let blue500Light = ColorAsset(name: "Blue500Light")
  internal static let blue50Dark = ColorAsset(name: "Blue50Dark")
  internal static let blue50Light = ColorAsset(name: "Blue50Light")
  internal static let blue600Dark = ColorAsset(name: "Blue600Dark")
  internal static let blue600Light = ColorAsset(name: "Blue600Light")
  internal static let blue700Dark = ColorAsset(name: "Blue700Dark")
  internal static let blue700Light = ColorAsset(name: "Blue700Light")
  internal static let blue800Dark = ColorAsset(name: "Blue800Dark")
  internal static let blue800Light = ColorAsset(name: "Blue800Light")
  internal static let blue900Dark = ColorAsset(name: "Blue900Dark")
  internal static let blue900Light = ColorAsset(name: "Blue900Light")
  internal static let gray10 = ColorAsset(name: "Gray10")
  internal static let gray100 = ColorAsset(name: "Gray100")
  internal static let gray20 = ColorAsset(name: "Gray20")
  internal static let gray30 = ColorAsset(name: "Gray30")
  internal static let gray40 = ColorAsset(name: "Gray40")
  internal static let gray50 = ColorAsset(name: "Gray50")
  internal static let gray60 = ColorAsset(name: "Gray60")
  internal static let gray70 = ColorAsset(name: "Gray70")
  internal static let gray80 = ColorAsset(name: "Gray80")
  internal static let gray90 = ColorAsset(name: "Gray90")
  internal static let gray95 = ColorAsset(name: "Gray95")
  internal static let green100Dark = ColorAsset(name: "Green100Dark")
  internal static let green100Light = ColorAsset(name: "Green100Light")
  internal static let green200Dark = ColorAsset(name: "Green200Dark")
  internal static let green200Light = ColorAsset(name: "Green200Light")
  internal static let green300Dark = ColorAsset(name: "Green300Dark")
  internal static let green300Light = ColorAsset(name: "Green300Light")
  internal static let green400Dark = ColorAsset(name: "Green400Dark")
  internal static let green400Light = ColorAsset(name: "Green400Light")
  internal static let green500Dark = ColorAsset(name: "Green500Dark")
  internal static let green500Light = ColorAsset(name: "Green500Light")
  internal static let green50Dark = ColorAsset(name: "Green50Dark")
  internal static let green50Light = ColorAsset(name: "Green50Light")
  internal static let green600Dark = ColorAsset(name: "Green600Dark")
  internal static let green600Light = ColorAsset(name: "Green600Light")
  internal static let green700Dark = ColorAsset(name: "Green700Dark")
  internal static let green700Light = ColorAsset(name: "Green700Light")
  internal static let green800Dark = ColorAsset(name: "Green800Dark")
  internal static let green800Light = ColorAsset(name: "Green800Light")
  internal static let green900Dark = ColorAsset(name: "Green900Dark")
  internal static let green900Light = ColorAsset(name: "Green900Light")
  internal static let purple100Dark = ColorAsset(name: "Purple100Dark")
  internal static let purple100Light = ColorAsset(name: "Purple100Light")
  internal static let purple200Dark = ColorAsset(name: "Purple200Dark")
  internal static let purple200Light = ColorAsset(name: "Purple200Light")
  internal static let purple300Dark = ColorAsset(name: "Purple300Dark")
  internal static let purple300Light = ColorAsset(name: "Purple300Light")
  internal static let purple400Dark = ColorAsset(name: "Purple400Dark")
  internal static let purple400Light = ColorAsset(name: "Purple400Light")
  internal static let purple500Dark = ColorAsset(name: "Purple500Dark")
  internal static let purple500Light = ColorAsset(name: "Purple500Light")
  internal static let purple50Dark = ColorAsset(name: "Purple50Dark")
  internal static let purple50Light = ColorAsset(name: "Purple50Light")
  internal static let purple600Dark = ColorAsset(name: "Purple600Dark")
  internal static let purple600Light = ColorAsset(name: "Purple600Light")
  internal static let purple700Dark = ColorAsset(name: "Purple700Dark")
  internal static let purple700Light = ColorAsset(name: "Purple700Light")
  internal static let purple800Dark = ColorAsset(name: "Purple800Dark")
  internal static let purple800Light = ColorAsset(name: "Purple800Light")
  internal static let purple900Dark = ColorAsset(name: "Purple900Dark")
  internal static let purple900Light = ColorAsset(name: "Purple900Light")
  internal static let red100Dark = ColorAsset(name: "Red100Dark")
  internal static let red100Light = ColorAsset(name: "Red100Light")
  internal static let red200Dark = ColorAsset(name: "Red200Dark")
  internal static let red200Light = ColorAsset(name: "Red200Light")
  internal static let red300Dark = ColorAsset(name: "Red300Dark")
  internal static let red300Light = ColorAsset(name: "Red300Light")
  internal static let red400Dark = ColorAsset(name: "Red400Dark")
  internal static let red400Light = ColorAsset(name: "Red400Light")
  internal static let red500Dark = ColorAsset(name: "Red500Dark")
  internal static let red500Light = ColorAsset(name: "Red500Light")
  internal static let red50Dark = ColorAsset(name: "Red50Dark")
  internal static let red50Light = ColorAsset(name: "Red50Light")
  internal static let red600Dark = ColorAsset(name: "Red600Dark")
  internal static let red600Light = ColorAsset(name: "Red600Light")
  internal static let red700Dark = ColorAsset(name: "Red700Dark")
  internal static let red700Light = ColorAsset(name: "Red700Light")
  internal static let red800Dark = ColorAsset(name: "Red800Dark")
  internal static let red800Light = ColorAsset(name: "Red800Light")
  internal static let red900Dark = ColorAsset(name: "Red900Dark")
  internal static let red900Light = ColorAsset(name: "Red900Light")
  internal static let turquoise100Dark = ColorAsset(name: "Turquoise100Dark")
  internal static let turquoise100Light = ColorAsset(name: "Turquoise100Light")
  internal static let turquoise200Dark = ColorAsset(name: "Turquoise200Dark")
  internal static let turquoise200Light = ColorAsset(name: "Turquoise200Light")
  internal static let turquoise300Dark = ColorAsset(name: "Turquoise300Dark")
  internal static let turquoise300Light = ColorAsset(name: "Turquoise300Light")
  internal static let turquoise400Dark = ColorAsset(name: "Turquoise400Dark")
  internal static let turquoise400Light = ColorAsset(name: "Turquoise400Light")
  internal static let turquoise500Dark = ColorAsset(name: "Turquoise500Dark")
  internal static let turquoise500Light = ColorAsset(name: "Turquoise500Light")
  internal static let turquoise50Dark = ColorAsset(name: "Turquoise50Dark")
  internal static let turquoise50Light = ColorAsset(name: "Turquoise50Light")
  internal static let turquoise600Dark = ColorAsset(name: "Turquoise600Dark")
  internal static let turquoise600Light = ColorAsset(name: "Turquoise600Light")
  internal static let turquoise700Dark = ColorAsset(name: "Turquoise700Dark")
  internal static let turquoise700Light = ColorAsset(name: "Turquoise700Light")
  internal static let turquoise800Dark = ColorAsset(name: "Turquoise800Dark")
  internal static let turquoise800Light = ColorAsset(name: "Turquoise800Light")
  internal static let turquoise900Dark = ColorAsset(name: "Turquoise900Dark")
  internal static let turquoise900Light = ColorAsset(name: "Turquoise900Light")
  internal static let white = ColorAsset(name: "White")
}
// swiftlint:enable identifier_name line_length nesting type_body_length type_name

// MARK: - Implementation Details

internal final class ColorAsset {
  internal fileprivate(set) var name: String

  #if os(macOS)
  internal typealias Color = NSColor
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  internal typealias Color = UIColor
  #endif

  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  internal private(set) lazy var color: Color = {
    guard let color = Color(asset: self) else {
      fatalError("Unable to load color asset named \(name).")
    }
    return color
  }()

  #if os(iOS) || os(tvOS)
  @available(iOS 11.0, tvOS 11.0, *)
  internal func color(compatibleWith traitCollection: UITraitCollection) -> Color {
    let bundle = BundleToken.bundle
    guard let color = Color(named: name, in: bundle, compatibleWith: traitCollection) else {
      fatalError("Unable to load color asset named \(name).")
    }
    return color
  }
  #endif

  fileprivate init(name: String) {
    self.name = name
  }
}

internal extension ColorAsset.Color {
  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  convenience init?(asset: ColorAsset) {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSColor.Name(asset.name), bundle: bundle)
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
