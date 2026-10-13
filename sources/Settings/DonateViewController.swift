//
//  DonateViewController.swift
//  iTerm2SharedARC
//
//  Created by George Nachman on 2/27/22.
//

import Foundation

@objc
private class DonateView: NSView {
}

@objc(iTermDonateViewController)
class DonateViewController: NSTitlebarAccessoryViewController {
    private static func textString() -> String {
        return [NSLocalizedString("Donate", tableName: "Settings", bundle: Bundle(for: DonateViewController.self), comment: ""),
                NSLocalizedString("Support iTerm2", tableName: "Settings", bundle: Bundle(for: DonateViewController.self), comment: ""),
                NSLocalizedString("iTerm2 is one person’s project. Donate now!", tableName: "Settings", bundle: Bundle(for: DonateViewController.self), comment: ""),
                NSLocalizedString("Keep iTerm2 alive — Donate today!", tableName: "Settings", bundle: Bundle(for: DonateViewController.self), comment: ""),
                NSLocalizedString("Love using iTerm2? Help keep it thriving!", tableName: "Settings", bundle: Bundle(for: DonateViewController.self), comment: ""),
                NSLocalizedString("iTerm2 needs your support – Donate here.", tableName: "Settings", bundle: Bundle(for: DonateViewController.self), comment: ""),
                NSLocalizedString("Help iTerm2 grow – Consider donating.", tableName: "Settings", bundle: Bundle(for: DonateViewController.self), comment: ""),
                NSLocalizedString("Keep the iTerm2 dream alive – Donate!", tableName: "Settings", bundle: Bundle(for: DonateViewController.self), comment: ""),
                NSLocalizedString("Support the creator of iTerm2 – Donate now!", tableName: "Settings", bundle: Bundle(for: DonateViewController.self), comment: ""),
        ].randomElement()!
    }

    let innerVC = DismissableLinkViewController(userDefaultsKey: "NoSyncHideDonateLabel",
                                                text: DonateViewController.textString(),
                                                url: URL(string: "https://iterm2.com/donate.html")!,
                                                clickToHide: true)
    init() {
        super.init(nibName: nil, bundle: nil)
        layoutAttribute = .right
    }

    required init?(coder: NSCoder) {
        it_fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = DonateView()

        let subview = innerVC.view
        subview.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subview)

        view.frame = subview.frame

        view.addConstraint(NSLayoutConstraint(item: view,
                                              attribute: .width,
                                              relatedBy: .equal,
                                              toItem: subview,
                                              attribute: .width,
                                              multiplier: 1,
                                              constant: 0))
        view.addConstraint(NSLayoutConstraint(item: view,
                                              attribute: .height,
                                              relatedBy: .greaterThanOrEqual,
                                              toItem: subview,
                                              attribute: .height,
                                              multiplier: 1,
                                              constant: 7.5))
        view.addConstraint(NSLayoutConstraint(item: view,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: subview,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 0))
        view.addConstraint(NSLayoutConstraint(item: view,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: subview,
                                              attribute: .top,
                                              multiplier: 1,
                                              constant: -4
                                             ))
    }
}
