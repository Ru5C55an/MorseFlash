//
//  TabBarController.swift
//  MorseFlash
//
//  Created by Руслан Садыков on 18.04.2023.
//

import UIKit

final class TabBarController: UITabBarController, UITabBarControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setTabBarMenuControllers()
    }

    private func setTabBarMenuControllers() {
        var tabBarList = [UIViewController]()

        let textToMorseVC = UINavigationController(rootViewController: TextToMorseViewController())
        textToMorseVC.title = "textInMorseCode".localized
        textToMorseVC.tabBarItem.image = UIImage(systemName: "text.bubble")
        textToMorseVC.tabBarItem.selectedImage = UIImage(systemName: "text.bubble.fill")
        textToMorseVC.tabBarItem.tag = 0
        tabBarList.insert(textToMorseVC, at: 0)

        let morseToTextVC = UINavigationController(rootViewController: MorseToTextViewController())
        morseToTextVC.title = "morseCodeToText".localized
        morseToTextVC.tabBarItem.image = UIImage(systemName: "ellipsis.bubble")
        morseToTextVC.tabBarItem.selectedImage = UIImage(systemName: "ellipsis.bubble.fill")
        morseToTextVC.tabBarItem.tag = 1
        tabBarList.insert(morseToTextVC, at: 1)
        viewControllers = tabBarList
    }

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        return true
    }

    deinit {
        print("Deinit: ", TabBarController.self)
    }
}
