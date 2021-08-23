//
//  ViewController.swift
//  SearchableTable
//
//  Created by Thomas Harrison on 08/23/2021.
//  Copyright (c) 2021 Thomas Harrison. All rights reserved.
//

import AlertFactory
import SearchableTable
import UIKit

class Item {
    var name: String
    var date: Date

    init(
        name: String, date: Date
    ) {
        self.name = name
        self.date = date
    }
}

extension Item: CustomStringConvertible {
    var description: String {
        name
    }
}

class ItemViewController: UIViewController {
    var item: Item!

    let nameLabel = UILabel()
    let dateLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        title = item.name

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.text = item.name
        nameLabel.textColor = .label
        view.addSubview(nameLabel)

        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.text = item.date.description
        dateLabel.textColor = .label
        view.addSubview(dateLabel)

        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            nameLabel.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor),

            dateLabel.topAnchor.constraint(equalTo: nameLabel.layoutMarginsGuide.bottomAnchor, constant: 20.0),
            dateLabel.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor),
        ])
    }
}

class ViewController: SearchableTableViewController {
    var items: [Item] = (0..<10).map { i in
        Item(name: "Item \(i)", date: Date(timeIntervalSinceNow: Double(i * -10)))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Searchable Table View Demo"
        delegate = self
    }
}

extension ViewController: SearchableTableDelegate {
    func numberOfRows() -> Int {
        items.count
    }

    func name(for row: Int) -> String {
        items[row].name
    }

    func date(for row: Int) -> Date {
        items[row].date
    }

    func searchTable(add name: String) {
        print("Add item \(name)")
        items.append(Item(name: name, date: Date()))
    }

    func searchTable(select row: Int) {
        let view = ItemViewController()
        view.item = items[row]
        show(view, sender: nil)
    }

    func searchTable(delete row: Int) {
        items.remove(at: row)
    }

    func searchTable(rename row: Int, to name: String) {
        items[row].name = name
    }
}
