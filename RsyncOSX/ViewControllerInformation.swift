//
//  ViewControllerInformation.swift
//  RsyncOSXver30
//
//  Created by Thomas Evensen on 24/08/2016.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//
//  swiftlint:disable line_length

import Cocoa
import Foundation

class ViewControllerInformation: NSViewController, SetDismisser, OutPut {
    @IBOutlet var detailsTable: NSTableView!

    var output: [String]?
    @IBOutlet var errormessagesbutton: NSButton!
    weak var geterrormessagesDelegate: Allerrors?

    @IBAction func showerrormessages(_: NSButton) {
        if self.errormessagesbutton.state == .on {
            self.geterrormessagesDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vctabmain) as? ViewControllerMain
            self.output = self.geterrormessagesDelegate?.getoutputerrors()?.getOutput()
        } else {
            self.output = self.getinfo()
        }
        globalMainQueue.async { () -> Void in
            self.detailsTable.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.detailsTable.delegate = self
        self.detailsTable.dataSource = self
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.output = self.getinfo()
        globalMainQueue.async { () -> Void in
            self.detailsTable.reloadData()
        }
    }

    @IBAction func close(_: NSButton) {
        self.dismissview(viewcontroller: self, vcontroller: .vctabmain)
    }
}

extension ViewControllerInformation: NSTableViewDataSource {
    func numberOfRows(in _: NSTableView) -> Int {
        return self.output?.count ?? 0
    }
}

extension ViewControllerInformation: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor _: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "outputID"), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = self.output?[row] ?? ""
            return cell
        } else {
            return nil
        }
    }
}
