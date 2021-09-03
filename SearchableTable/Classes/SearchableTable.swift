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

/// Methods for `SearchableTableViewController` to access data.
public protocol SearchableTableDelegate {

    /// Get the number of rows in the table.
    func numberOfRows() -> Int

    /// Get the name for an item at index `row`.
    func name(for row: Int) -> String

    /// Get the date for an item at index `row`.
    func date(for row: Int) -> Date

    /// Action for adding an item with `name`.
    func searchTable(add name: String)

    /// Action for selecting an item at index `row`. This is typically used to navigate to the item.
    func searchTable(select row: Int)

    /// Action for deleting an item at index `row`.
    func searchTable(delete row: Int)

    /// Action for renaming an item at index `row` to `name`.
    func searchTable(rename row: Int, to name: String)
}

/// `UITableViewController` with a `UISearchBar` that manages filtering and editing items.
open class SearchableTableViewController: UITableViewController, UISearchBarDelegate {

    private var filterData: [Int] = []

    private var searchBar: UISearchBar = UISearchBar()

    /// The search text. Call `SearchableTableViewController.reload() `after changing to show the new search results.
    public var searchText: String = ""

    /// Delegate provides data to the `SearchableTableViewController`.
    public var delegate: SearchableTableDelegate!

    /// Should the table exit edit mode after a rename is complete.
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

    /// Reload, sort and filter all table rows with search text as the filter.
    open func reload() {
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
    
    /// Handles the navigation bar add button action.
    @objc open func newItemAction(_ sender: Any) {
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

    // MARK: Table Override

    public override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .delete
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
