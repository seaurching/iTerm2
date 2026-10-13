//
//  iTermHistogram.swift
//  iTerm2
//
//  Created by George Nachman on 8/26/25.
//

extension iTermHistogram {
    @objc
    static var tabularFormatterTime: TabularFormatter {
        let formatter = TabularFormatter()
        formatter.defineColumn(label: NSLocalizedString("Min Time", tableName: "Metrology", comment: "Metrology: min time column"), leftAligned: false)
        formatter.defineColumn(label: NSLocalizedString("Distribution", tableName: "Metrology", comment: "Metrology: distribution column"), leftAligned: true)
        formatter.defineColumn(label: NSLocalizedString("Max Time", tableName: "Metrology", comment: "Metrology: max time column"), leftAligned: false)
        formatter.defineColumn(label: NSLocalizedString("# Samples", tableName: "Metrology", comment: "Metrology: samples column"), leftAligned: false)
        formatter.defineColumn(label: NSLocalizedString("Mean Time", tableName: "Metrology", comment: "Metrology: mean time column"), leftAligned: false)
        formatter.defineColumn(label: "P50", leftAligned: false)
        formatter.defineColumn(label: "P95", leftAligned: false)
        formatter.defineColumn(label: NSLocalizedString("Total Time", tableName: "Metrology", comment: "Metrology: total time column"), leftAligned: false)
        formatter.defineColumn(label: "", leftAligned: true)
        return formatter
    }

    @objc
    func add(to formatter: TabularFormatter, precision: Int, units: String, label: String) {
        if (count == 0) {
            return
        }

        let format = "%0.\(precision)f"

        formatter.add(row: [
            String(format: format, percentile(0.0)) + " " + units,
            graphString(),
            String(format: format, percentile(1.0)) + " " + units,
            "\(count)",
            String(format: format, sum / Double(count)) + " " + units,
            String(format: format, percentile(0.5)) + " " + units,
            String(format: format, percentile(0.95)) + " " + units,
            String(format: format, sum) + " " + units,
            label
        ])
    }
}
