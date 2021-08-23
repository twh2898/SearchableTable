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

protocol HasDate {
    var date: Date { get }
}

class SearchableTableViewController<T>: UITableViewController, UISearchBarDelegate where T: Comparable & CustomStringConvertible & HasDate {

    var filterData: [T] = []

    var searchText: String = ""

    var searchBar: UISearchBar = UISearchBar()

    var stopEditAfterRename: Bool = false

    override func viewDidLoad() {
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    func reload() {
        let items = searchTableItems().sorted { a, b in
            a > b
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

    // MARK: Public Override

    func searchTableItems() -> [T] {
        []
    }

    func searchTable(add name: String) {

    }

    func searchTable(select item: T) {

    }

    func searchTable(delete item: T) {

    }

    func searchTable(rename item: T, to name: String) {

    }

    // MARK: Table Override

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .delete
    }

    @objc func newItemAction(_ sender: Any) {
        let alertFactory = AlertFactory(title: "Enter a name", message: "Please enter a name", confirmLabel: "Create")
        let alert = alertFactory.prompt(
            confirmAction: { name in
                guard let name = name, !name.isEmpty else {
                    self.alert(title: "Empty Name", message: "The name was empty")
                    return
                }

                self.searchTable(add: name)
            })

        present(alert, animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filterData.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        cell.accessoryType = .disclosureIndicator
        let item = filterData[indexPath.row]
        cell.textLabel?.text = item.description
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = DateFormatter.appPrettyFormat
        cell.detailTextLabel?.text = dateFormatterPrint.string(from: item.date)
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            self.prompt(
                title: "Enter a name", message: "Please enter a new name", placeholder: "Name",
                confirmAction: { name in
                    guard let name = name else {
                        self.alert(title: "Error", message: "An error occurred while trying to handle the name.")
                        return
                    }

                    guard !name.isEmpty else {
                        self.alert(title: "Empty Name", message: "The name must not be empty")
                        return
                    }

                    self.searchTable(rename: self.filterData[indexPath.row], to: name)
                    self.reload()

                    if self.stopEditAfterRename {
                        self.tableView.isEditing = false
                    }
                })
        } else {
            searchTable(select: filterData[indexPath.row])
        }
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            searchTable(delete: filterData[indexPath.row])
            reload()
        }
    }

    // MARK: SearchBar Override

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText
        reload()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    }
}
