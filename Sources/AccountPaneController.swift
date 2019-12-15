/**
 *  AccountPaneController.swift
 *  NowPlayingTweet
 *
 *  © 2018 kPherox.
**/

import Cocoa

class AccountPaneController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {

    @IBOutlet weak var avater: NSImageView!
    @IBOutlet weak var name: NSTextField!
    @IBOutlet weak var screenName: NSTextField!
    @IBOutlet weak var currentButton: NSButton!
    @IBOutlet weak var currentLabel: NSTextField!
    @IBOutlet weak var accountControl: NSSegmentedControl!
    @IBOutlet weak var accountList: NSTableView!

    private let appDelegate: AppDelegate = NSApplication.shared.delegate as! AppDelegate

    static let shared: AccountPaneController = {
        let windowController = NSStoryboard.main!.instantiateController(withIdentifier: .accountPaneController)
        return windowController as! AccountPaneController
    }()

    var selected: Account?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do view setup here.
        guard let current = Accounts.shared.current else {
            self.set(name: nil)
            self.set(screenName: nil)
            self.set(avaterUrl: nil)
            return
        }

        self.selected = current
        self.accountControl.setEnabled(true, forSegment: 1)

        let index = IndexSet(integer: Accounts.shared.sortedAccounts.firstIndex { current.isEqual($0) } ?? 0)
        self.accountList.selectRowIndexes(index, byExtendingSelection: false)

        self.currentLabel.isHidden = false
        self.currentButton.isHidden = false
        self.currentButton.isEnabled = false

        self.set(name: current.name)
        self.set(screenName: current.username)
        self.set(avaterUrl: current.avaterUrl)
    }

    @IBAction private func setToCurrent(_ sender: NSButton) {
        let selected = self.selected!
        Accounts.shared.current = selected
        self.appDelegate.updateSocialAccount()
        self.currentLabel.isHidden = false
        self.currentButton.isEnabled = false
    }

    @IBAction func manageAccount(_ sender: NSSegmentedControl) {
        switch sender.selectedSegment {
          case 0:
            self.addAccount()
          case 1:
            self.removeAccount()
          default: // 2
            break
        }
    }

    private func addAccount() {
        guard let provider = Provider(rawValue: "Twitter") else {
            return
        }

        let notificationCenter: NotificationCenter = NotificationCenter.default
        var observer: NSObjectProtocol!
        observer = notificationCenter.addObserver(forName: .login, object: nil, queue: nil, using: { notification in
            notificationCenter.removeObserver(observer!)

            guard let selected = notification.userInfo!["account"] as? Account else {
                return
            }

            self.selected = selected

            self.accountList.reloadData()

            let index = IndexSet(integer: Accounts.shared.sortedAccounts.firstIndex { selected.isEqual($0) } ?? 0)
            self.accountList.selectRowIndexes(index, byExtendingSelection: false)

            self.appDelegate.updateSocialAccount()

            let isCurrent = selected.isEqual(Accounts.shared.current)
            if isCurrent {
                self.accountControl.setEnabled(true, forSegment: 1)
                self.currentButton.isHidden = false
            }

            self.currentLabel.isHidden = !isCurrent
            self.currentButton.isEnabled = !isCurrent

            self.set(name: selected.name)
            self.set(screenName: selected.username)
            self.set(avaterUrl: selected.avaterUrl)
        })

        Accounts.shared.login(provider: provider)
    }

    private func removeAccount() {
        Accounts.shared.logout(account: self.selected!)

        self.accountList.reloadData()
        self.appDelegate.updateSocialAccount()

        guard let selected = Accounts.shared.current else {
            self.accountControl.setEnabled(false, forSegment: 1)
            self.selected = nil
            self.set(name: nil)
            self.set(avaterUrl: nil)
            self.set(screenName: nil)

            self.currentLabel.isHidden = true
            self.currentButton.isHidden = true

            return
        }

        self.selected = selected

        let index = IndexSet(integer: Accounts.shared.sortedAccounts.firstIndex { selected.isEqual($0) } ?? 0)
        self.accountList.selectRowIndexes(index, byExtendingSelection: false)

        let isCurrent = selected.isEqual(Accounts.shared.current)
        self.currentLabel.isHidden = !isCurrent
        self.currentButton.isEnabled = !isCurrent

        self.set(name: selected.name)
        self.set(screenName: selected.username)
        self.set(avaterUrl: selected.avaterUrl)
    }

    @IBAction private func selectAccount(_ sender: NSTableView) {
        let row = sender.selectedRow

        let selected = Accounts.shared.sortedAccounts[row]
        self.selected = selected

        let isCurrent = selected.isEqual(Accounts.shared.current)
        self.currentLabel.isHidden = !isCurrent
        self.currentButton.isEnabled = !isCurrent
        self.set(name: selected.name)
        self.set(screenName: selected.username)
        self.set(avaterUrl: selected.avaterUrl)
    }

    private func set(name: String?) {
        self.name.stringValue = name ?? "Not logged in..."
        self.name.textColor = name != nil ? .labelColor : .disabledControlTextColor
    }

    private func set(screenName id: String?) {
        self.screenName.stringValue = "@" + (id ?? "null")
        self.screenName.textColor = id != nil ? .secondaryLabelColor : .disabledControlTextColor
    }

    private func set(avaterUrl url: URL?) {
        if let url = url {
            self.avater.fetchImage(url: url, rounded: true)
            self.avater.enable()
        } else {
            self.avater.image = NSImage(named: "NSUserGuest", templated: true)
            self.avater.disable()
        }
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        if !Accounts.shared.existsAccounts {
            return 0
        }
        let accountCount = Accounts.shared.sortedAccounts.count
        return accountCount
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cellView = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as! AccountCellView

        let account = Accounts.shared.sortedAccounts[row]

        cellView.textField?.stringValue = account.name
        cellView.screenName?.stringValue = "@\(account.username)"
        cellView.imageView?.fetchImage(url: account.avaterUrl, rounded: true)

        return cellView
    }

}
