//
//  ShaderListCollectionView.swift
//  DisplacementRippleMetal
//
//  Created by Dayo Banjo on 10/14/23.
//
import UIKit

class ShaderListCollectionView: UIViewController {
    
    var collectionView: UICollectionView!
    var dataSource: UICollectionViewDiffableDataSource<ShaderItemSection, ShaderItem>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavItem()
        configureHierarchy()
        configureDataSource()
        applyInitialSnapshots()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let indexPath = self.collectionView.indexPathsForSelectedItems?.first {
            if let coordinator = self.transitionCoordinator {
                coordinator.animate(alongsideTransition: { context in
                    self.collectionView.deselectItem(at: indexPath, animated: true)
                }) { (context) in
                    if context.isCancelled {
                        self.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                    }
                }
            } else {
                self.collectionView.deselectItem(at: indexPath, animated: animated)
            }
        }
    }
}

extension ShaderListCollectionView {
    
    func configureNavItem() {
        navigationItem.title = "Shader Collections"
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    func configureHierarchy() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.delegate = self
        collectionView.contentInset = UIEdgeInsets(top: 32, left: 0, bottom: 0, right: 0)
        view.addSubview(collectionView)
    }
    
    func createLayout() -> UICollectionViewLayout {
        let configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        return UICollectionViewCompositionalLayout.list(using: configuration)
    }
    
    func configureDataSource() {
        
        // list cell
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, ShaderItem> { (cell, indexPath, shaderItem) in
            var contentConfiguration = UIListContentConfiguration.valueCell()
            contentConfiguration.text = shaderItem.title
            contentConfiguration.secondaryText = "Basic"
            cell.contentConfiguration = contentConfiguration
            
            cell.accessories = [.disclosureIndicator()]
        }
        
        // data source
        dataSource = UICollectionViewDiffableDataSource<ShaderItemSection, ShaderItem>(collectionView: collectionView) {
            (collectionView, indexPath, item) -> UICollectionViewCell? in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
    }
    
    func applyInitialSnapshots() {
        
        for section in ShaderItemDataSource.sections {
            var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<ShaderItem>()
            let items = section.shaderItems
            sectionSnapshot.append(items)
            dataSource.apply(sectionSnapshot, to: section, animatingDifferences: false)
        }
    }
}

extension ShaderListCollectionView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let shaderItem = self.dataSource.itemIdentifier(for: indexPath) else {
            collectionView.deselectItem(at: indexPath, animated: true)
            return
        }
        let detailViewController = ShaderViewController(shaderItem: shaderItem)
        self.navigationController?.pushViewController(detailViewController, animated: true)
    }
}

