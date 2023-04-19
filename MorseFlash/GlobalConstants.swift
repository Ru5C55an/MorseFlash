//
//  GlobalConstants.swift
//  MorseFlash
//
//  Created by Руслан Садыков on 02.04.2023.
//

import UIKit.UIFont
import FittedSheets

enum GlobalConstants {
    static let sheetOptions = SheetOptions(
        // The full height of the pull bar. The presented view controller will treat this area as a safearea inset on the top
        pullBarHeight: 0,

        // The corner radius of the shrunken presenting view controller
        presentingViewCornerRadius: 30,

        // Extends the background behind the pull bar or not
        shouldExtendBackground: false,

        // Attempts to use intrinsic heights on navigation controllers. This does not work well in combination with keyboards without your code handling it.
        setIntrinsicHeightOnNavigationControllers: false,

        // Pulls the view controller behind the safe area top, especially useful when embedding navigation controllers
        useFullScreenMode: false,

        // Shrinks the presenting view controller, similar to the native modal
        shrinkPresentingViewController: false,

        // Determines if using inline mode or not
        useInlineMode: false,

        // Adds a padding on the left and right of the sheet with this amount. Defaults to zero (no padding)
        horizontalPadding: 0,

        // Sets the maximum width allowed for the sheet. This defaults to nil and doesn't limit the width.
        maxWidth: nil
    )

    static let morseTextViewFont = UIFont.systemFont(ofSize: 24)
    static let unsupportedLocale = "unsupportedLocale".localized
    static let padding: CGFloat = 16.0
}
