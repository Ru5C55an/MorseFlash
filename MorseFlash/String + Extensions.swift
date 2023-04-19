//
//  String + Extensions.swift
//  MorseFlash
//
//  Created by Руслан Садыков on 03.04.2023.
//

import Foundation

extension String {
    var localized: String {
        NSLocalizedString(self, tableName: nil, bundle: .main, value: self, comment: "")
    }

    func localized(_ arguments: String...) -> String {
        String(format: self.localized, locale: Locale.current, arguments: arguments)
    }
}
