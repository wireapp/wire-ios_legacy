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
  internal static let amber100 = ColorAsset(name: "Amber100")
  internal static let amber200 = ColorAsset(name: "Amber200")
  internal static let amber300 = ColorAsset(name: "Amber300")
  internal static let amber400 = ColorAsset(name: "Amber400")
  internal static let amber50 = ColorAsset(name: "Amber50")
  internal static let amber500 = ColorAsset(name: "Amber500")
  internal static let amber600 = ColorAsset(name: "Amber600")
  internal static let amber700 = ColorAsset(name: "Amber700")
  internal static let amber800 = ColorAsset(name: "Amber800")
  internal static let amber900 = ColorAsset(name: "Amber900")
  internal static let blue100 = ColorAsset(name: "Blue100")
  internal static let blue200 = ColorAsset(name: "Blue200")
  internal static let blue300 = ColorAsset(name: "Blue300")
  internal static let blue400 = ColorAsset(name: "Blue400")
  internal static let blue50 = ColorAsset(name: "Blue50")
  internal static let blue500 = ColorAsset(name: "Blue500")
  internal static let blue600 = ColorAsset(name: "Blue600")
  internal static let blue700 = ColorAsset(name: "Blue700")
  internal static let blue800 = ColorAsset(name: "Blue800")
  internal static let blue900 = ColorAsset(name: "Blue900")
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
  internal static let green100 = ColorAsset(name: "Green100")
  internal static let green200 = ColorAsset(name: "Green200")
  internal static let green300 = ColorAsset(name: "Green300")
  internal static let green400 = ColorAsset(name: "Green400")
  internal static let green50 = ColorAsset(name: "Green50")
  internal static let green500 = ColorAsset(name: "Green500")
  internal static let green600 = ColorAsset(name: "Green600")
  internal static let green700 = ColorAsset(name: "Green700")
  internal static let green800 = ColorAsset(name: "Green800")
  internal static let green900 = ColorAsset(name: "Green900")
  internal static let petrol100 = ColorAsset(name: "Petrol100")
  internal static let petrol200 = ColorAsset(name: "Petrol200")
  internal static let petrol300 = ColorAsset(name: "Petrol300")
  internal static let petrol400 = ColorAsset(name: "Petrol400")
  internal static let petrol50 = ColorAsset(name: "Petrol50")
  internal static let petrol500 = ColorAsset(name: "Petrol500")
  internal static let petrol600 = ColorAsset(name: "Petrol600")
  internal static let petrol700 = ColorAsset(name: "Petrol700")
  internal static let petrol800 = ColorAsset(name: "Petrol800")
  internal static let petrol900 = ColorAsset(name: "Petrol900")
  internal static let purple100 = ColorAsset(name: "Purple100")
  internal static let purple200 = ColorAsset(name: "Purple200")
  internal static let purple300 = ColorAsset(name: "Purple300")
  internal static let purple400 = ColorAsset(name: "Purple400")
  internal static let purple50 = ColorAsset(name: "Purple50")
  internal static let purple500 = ColorAsset(name: "Purple500")
  internal static let purple600 = ColorAsset(name: "Purple600")
  internal static let purple700 = ColorAsset(name: "Purple700")
  internal static let purple800 = ColorAsset(name: "Purple800")
  internal static let purple900 = ColorAsset(name: "Purple900")
  internal static let red100 = ColorAsset(name: "Red100")
  internal static let red200 = ColorAsset(name: "Red200")
  internal static let red300 = ColorAsset(name: "Red300")
  internal static let red400 = ColorAsset(name: "Red400")
  internal static let red50 = ColorAsset(name: "Red50")
  internal static let red500 = ColorAsset(name: "Red500")
  internal static let red600 = ColorAsset(name: "Red600")
  internal static let red700 = ColorAsset(name: "Red700")
  internal static let red800 = ColorAsset(name: "Red800")
  internal static let red900 = ColorAsset(name: "Red900")
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
