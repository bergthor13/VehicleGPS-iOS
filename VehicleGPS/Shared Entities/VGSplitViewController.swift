//
//  SplitViewController.swift
//  iPadSidebar
//
//  Created by James Rochabrun on 6/28/20.
//

import UIKit

class VGSplitViewController: UIViewController {
    
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>! = nil
    private var collectionView: UICollectionView! = nil
    private var secondaryViewControllers = [
        VGLogsTableViewController(style: .plain),
        VGHistoryTableViewController(style: .grouped),
        VGJourneyTableViewController(style: .grouped),
        VGVehiclesTableViewController(style: .grouped),
        VGSettingsTableViewController(style: .grouped)
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = false
        title = nil
        configureHierarchy()
        configureDataSource()
        setInitialSecondaryView()
    }

    private func setInitialSecondaryView() {
        collectionView.selectItem(at: IndexPath(row: 0, section: 0),
                                  animated: false,
                                  scrollPosition: UICollectionView.ScrollPosition.centeredVertically)
        //splitViewController?.setViewController(secondaryViewControllers[0], for: .secondary)
    }
}

// MARK: - Layout

extension VGSplitViewController {

    private func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { section, layoutEnvironment in
            var config = UICollectionLayoutListConfiguration(appearance: .grouped)
            config.headerMode = section == 0 ? .none : .firstItemInSection
            return NSCollectionLayoutSection.list(using: config, layoutEnvironment: layoutEnvironment)
        }
    }

}

// MARK: - Data

extension VGSplitViewController {

    private func configureHierarchy() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.delegate = self

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func configureDataSource() {
        // Configuring cells

        let headerRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { (cell, indexPath, item) in
            var content = cell.defaultContentConfiguration()
            content.text = item.title
            cell.contentConfiguration = content
            cell.accessories = [.outlineDisclosure()]
        }
        
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { (cell, indexPath, item) in
            var content = cell.defaultContentConfiguration()
            content.text = item.title
            content.image = item.image
            cell.contentConfiguration = content
            cell.accessories = []
        }

        // Creating the datasource

        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, item: Item) -> UICollectionViewCell? in
            if indexPath.item == 0 && indexPath.section != 0 {
                return collectionView.dequeueConfiguredReusableCell(using: headerRegistration, for: indexPath, item: item)
            } else {
                return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
            }
        }

        // Creating and applying snapshots

        let sections: [Section] = [.tabs, .library, .playlists]
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections(sections)
        dataSource.apply(snapshot, animatingDifferences: false)

        for section in sections {
            switch section {
            case .tabs:
                var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<Item>()
                sectionSnapshot.append(tabsItems)
                dataSource.apply(sectionSnapshot, to: section)
            case .library:
                break
//                let headerItem = Item(title: section.rawValue, image: nil)
//                var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<Item>()
//                sectionSnapshot.append([headerItem])
//                sectionSnapshot.append(libraryItems, to: headerItem)
//                sectionSnapshot.expand([headerItem])
//                dataSource.apply(sectionSnapshot, to: section)
            case .playlists:
                break
//                let headerItem = Item(title: section.rawValue, image: nil)
//                var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<Item>()
//                sectionSnapshot.append([headerItem])
//                sectionSnapshot.append(playlistItems, to: headerItem)
//                sectionSnapshot.expand([headerItem])
//                dataSource.apply(sectionSnapshot, to: section)
            }
        }
    }

}

// MARK: - UICollectionViewDelegate

extension VGSplitViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.section == 0 else { return }
        splitViewController?.setViewController(secondaryViewControllers[indexPath.row], for: .supplementary)
    }

}

// MARK: - Structs and sample data

struct Item: Hashable {
    let title: String?
    let image: UIImage?
    private let identifier = UUID()
}

let tabsItems = [Item(title: Strings.titles.logs, image: Icons.log),
                 Item(title: Strings.titles.logs, image: Icons.history),
                 Item(title: Strings.titles.journeys, image: Icons.journeys),
                 Item(title: Strings.titles.vehicles, image: Icons.vehicle),
                 Item(title: Strings.titles.settings, image: Icons.settings)]

let libraryItems = [Item]()

let playlistItems = [Item]()

enum Section: String {
    case tabs
    case library = "Library"
    case playlists = "Playlists"
}
