//
//  SearchableTable.swift
//  AlertFactory
//
//  Created by Thomas Harrison on 8/23/21.
//

import AlertFactory
import UIKit
import os

extension DateFormatter {
    static let appPrettyFormat = "MMM dd, yyyy h:mm a"
}

public protocol SearchableTableDelegate {

    func numberOfRows() -> Int

    func name(for row: Int) -> String

    func date(for row: Int) -> Date

    func searchTable(add name: String)

    func searchTable(select row: Int)

    func searchTable(delete row: Int)

    func searchTable(rename row: Int, to name: String)
}

open class SearchableTableViewController: UITableViewController, UISearchBarDelegate {

    private var filterData: [Int] = []

    private var searchBar: UISearchBar = UISearchBar()

    public var searchText: String = ""

    public var delegate: SearchableTableDelegate!

    public var stopEditAfterRename: Bool = false

    open override func viewDidLoad() {
        super.viewDidLoad()

        tableView = UITableView(frame: tableView.frame, style: .grouped)
        tableView.accessibilityIdentifier = "SearchableTable"

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self

        searchBar.searchBarStyle = UISearchBar.Style.default
        searchBar.placeholder = "Search"
        searchBar.sizeToFit()
        searchBar.isTranslucent = false
        searchBar.delegate = self
        tableView.tableHeaderView = searchBar

        tableView.allowsSelectionDuringEditing = true

        let newButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newItemAction))

        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItems = [editButtonItem, newButtonItem]
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    public func reload() {
        let items = (0..<delegate.numberOfRows()).sorted { a, b in
            delegate.date(for: a) > delegate.date(for: b)
        }

        if searchText.isEmpty {
            filterData = items
        } else {
            let lowerSearchTerm = searchText.lowercased()

            filterData = filterData.filter { calibration in
                calibration.description.lowercased().contains(lowerSearchTerm)
            }
        }

        tableView.reloadData()
    }

    // MARK: Table Override

    public override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .delete
    }

    @objc private func newItemAction(_ sender: Any) {
        let alertFactory = AlertFactory(title: "Enter a name", message: "Please enter a name", confirmLabel: "Create")
        let alert = alertFactory.prompt(
            confirmAction: { name in
                guard let name = name, !name.isEmpty else {
                    self.alert(title: "Empty Name", message: "The name was empty")
                    return
                }

                self.delegate.searchTable(add: name)
                self.reload()
            })

        present(alert, animated: true, completion: nil)
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filterData.count
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        cell.accessoryType = .disclosureIndicator
        let item = filterData[indexPath.row]
        cell.textLabel?.text = delegate.name(for: item)
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = DateFormatter.appPrettyFormat
        cell.detailTextLabel?.text = dateFormatterPrint.string(from: delegate.date(for: item))
        return cell
    }

    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            self.prompt(
                title: "Enter a name",
                message: "Please enter a new name",
                placeholder: "Name",
                defaultValue: delegate.name(for: filterData[indexPath.row]),
                confirmAction: { name in
                    guard let name = name else {
                        self.alert(title: "Error", message: "An error occurred while trying to handle the name.")
                        return
                    }

                    guard !name.isEmpty else {
                        self.alert(title: "Empty Name", message: "The name must not be empty")
                        return
                    }

                    self.delegate.searchTable(rename: self.filterData[indexPath.row], to: name)
                    self.reload()

                    if self.stopEditAfterRename {
                        self.tableView.isEditing = false
                    }
                })
        } else {
            delegate.searchTable(select: filterData[indexPath.row])
        }
    }

    public override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            delegate.searchTable(delete: filterData[indexPath.row])
            reload()
        }
    }

    // MARK: SearchBar Override

    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText
        reload()
    }

    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    }

    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    }
}
