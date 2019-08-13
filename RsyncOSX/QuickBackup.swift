//
//  QuickBackup.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 22.12.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import Foundation

enum Sort {
    case localCatalog
    case offsiteCatalog
    case offsiteServer
    case backupId
}

class QuickBackup: SetConfigurations {
    var sortedlist: [NSMutableDictionary]?
    var estimatedlist: [NSDictionary]?
    typealias Row = (Int, Int)
    var stackoftasktobeexecuted: [Row]?
    var index: Int?
    var hiddenID: Int?
    var maxcount: Int?
    weak var reloadtableDelegate: Reloadandrefresh?

    func sortbydays() {
        guard self.sortedlist != nil else { return }
        let sorted = self.sortedlist!.sorted {(di1, di2) -> Bool in
            let di1 = (di1.value(forKey: "daysID") as? NSString)!.doubleValue
            let di2 = (di2.value(forKey: "daysID") as? NSString)!.doubleValue
            if di1 > di2 {
                return false
            } else {
                return true
            }
        }
        self.sortedlist = sorted
        self.reloadtableDelegate?.reloadtabledata()
    }

    private func executetask(hiddenID: Int) {
        let now: Date = Date()
        let dateformatter = Dateandtime().setDateformat()
        let task: NSDictionary = [
            "start": now,
            "hiddenID": hiddenID,
            "dateStart": dateformatter.date(from: "01 Jan 1900 00:00")!,
            "schedule": "manuel"]
        ViewControllerReference.shared.quickbackuptask = task
        _ = OperationFactory(updateprogress: self)
    }

    func prepareandstartexecutetasks() {
        if let list = self.sortedlist {
            self.stackoftasktobeexecuted = [Row]()
            for i in 0 ..< list.count {
                self.sortedlist![i].setObject(false, forKey: "completeCellID" as NSCopying)
                self.sortedlist![i].setObject(false, forKey: "inprogressCellID" as NSCopying)
                if list[i].value(forKey: "selectCellID") as? Int == 1 {
                    self.stackoftasktobeexecuted?.append(((list[i].value(forKey: "hiddenID") as? Int)!, i))
                }
                let hiddenID = list[i].value(forKey: "hiddenID") as? Int
                if self.estimatedlist != nil {
                    let estimated = self.estimatedlist!.filter({($0.value(forKey: "hiddenID") as? Int) == hiddenID!})
                    if estimated.count > 0 {
                        let transferredNumber = estimated[0].value(forKey: "transferredNumber") as? String ?? ""
                        self.sortedlist![i].setObject(transferredNumber, forKey: "transferredNumber" as NSCopying)
                    }
                }
            }
            guard self.stackoftasktobeexecuted!.count > 0 else { return }
            // Kick off first task
            self.hiddenID = self.stackoftasktobeexecuted![0].0
            self.index = self.stackoftasktobeexecuted![0].1
            self.sortedlist![self.index!].setValue(true, forKey: "inprogressCellID")
            self.maxcount = Int(self.sortedlist![self.index!].value(forKey: "transferredNumber") as? String ?? "0")
            self.stackoftasktobeexecuted?.remove(at: 0)
            self.executetask(hiddenID: self.hiddenID!)
        }
    }

    func setcompleted() {
        let dict = self.sortedlist!.filter({($0.value(forKey: "hiddenID") as? Int) == self.hiddenID!})
        guard dict.count == 1 else { return }
        self.index = self.sortedlist!.firstIndex(of: dict[0])
        self.sortedlist![self.index!].setValue(true, forKey: "completeCellID")
        self.sortedlist![self.index!].setValue(false, forKey: "inprogressCellID")
    }

    init() {
        self.estimatedlist = self.configurations?.estimatedlist
        if self.estimatedlist != nil {
            self.sortedlist = self.configurations?.getConfigurationsDataSourceSynchronize()?.filter({($0.value(forKey: "selectCellID") as? Int) == 1})
            guard self.sortedlist!.count > 0 else { return }
        } else {
            self.sortedlist = self.configurations?.getConfigurationsDataSourceSynchronize()
        }
        self.sortbydays()
        self.hiddenID = nil
        self.reloadtableDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcquickbackup) as? ViewControllerQuickBackup
    }
}

extension QuickBackup: UpdateProgress {

    func processTermination() {
        self.setcompleted()
        guard self.stackoftasktobeexecuted != nil else {
            // self.completed.isHidden = false
            // self.completed.textColor = setcolor(nsviewcontroller: self, color: .green)
            // self.working.stopAnimation(nil)
            // self.executing = false
            return
        }

        guard ViewControllerReference.shared.completeoperation != nil else { return }
        // ViewControllerReference.shared.completeoperation!.finalizeScheduledJob(outputprocess: self.outputprocess)
        // After logging is done set reference to object = nil
        ViewControllerReference.shared.completeoperation = nil

        guard self.stackoftasktobeexecuted != nil else { return }
        guard self.stackoftasktobeexecuted!.count > 0  else {
            self.stackoftasktobeexecuted = nil
            self.hiddenID = nil
            self.reloadtableDelegate?.reloadtabledata()
            return
        }
        self.hiddenID = self.stackoftasktobeexecuted![0].0
        self.index = self.stackoftasktobeexecuted![0].1
        self.stackoftasktobeexecuted?.remove(at: 0)
        self.sortedlist![self.index!].setValue(true, forKey: "inprogressCellID")
        self.maxcount = Int(self.sortedlist![self.index!].value(forKey: "transferredNumber") as? String ?? "0")
        self.executetask(hiddenID: self.hiddenID!)
        self.reloadtableDelegate?.reloadtabledata()
    }

    func fileHandler() {
        weak var localprocessupdateDelegate: Reloadandrefresh?
        localprocessupdateDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcquickbackup) as? ViewControllerQuickBackup
        localprocessupdateDelegate?.reloadtabledata()
    }
}
