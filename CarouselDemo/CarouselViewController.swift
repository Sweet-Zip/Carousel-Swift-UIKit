//
//  ViewController.swift
//  CarouselDemo
//
//  Created by SimpleLogic on 25/2/25.
//

import UIKit

class CarouselViewController: UIViewController {
    private enum Const {
        static let itemSize = CGSize(width: CGRectGetWidth(UIScreen.main.bounds) * 0.80, height: 200)
        static let itemSpacing = 5.0
        
        static var insetX: CGFloat {
            (UIScreen.main.bounds.width - Self.itemSize.width) / 2.0
        }
        
        static var collectionViewContentInset: UIEdgeInsets {
            UIEdgeInsets(top: 0, left: Self.insetX, bottom: 0, right: Self.insetX)
        }
    }
    
    private let collectionViewFlowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = Const.itemSize
        layout.minimumLineSpacing = Const.itemSpacing
        layout.minimumInteritemSpacing = 0
        return layout
    }()
    
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: self.collectionViewFlowLayout)
        view.isScrollEnabled = true
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = true
        view.backgroundColor = .clear
        view.clipsToBounds = true
        view.register(CollectionViewCell.self, forCellWithReuseIdentifier: CollectionViewCell.reuseIdentifier)
        view.isPagingEnabled = false
        view.contentInsetAdjustmentBehavior = .never
        view.contentInset = Const.collectionViewContentInset
        view.decelerationRate = .fast
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.currentPageIndicatorTintColor = .black
        pageControl.pageIndicatorTintColor = .lightGray
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.addTarget(self, action: #selector(pageControlTapped(_:)), for: .valueChanged)
        return pageControl
    }()
    
    private var items = (0...10).map { _ in randomColor }
    private var currentPage = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupCollectionView()
        setupPageControl()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        applyInitialScale()
    }
    
    private func setupCollectionView() {
        self.view.addSubview(self.collectionView)
        NSLayoutConstraint.activate([
            self.collectionView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            self.collectionView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            self.collectionView.heightAnchor.constraint(equalToConstant: Const.itemSize.height),
            self.collectionView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
        ])
        
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
    }
    
    private func setupPageControl() {
        self.view.addSubview(self.pageControl)
        NSLayoutConstraint.activate([
            self.pageControl.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.pageControl.topAnchor.constraint(equalTo: self.collectionView.bottomAnchor, constant: 20),
        ])
        
        self.pageControl.numberOfPages = self.items.count
        self.pageControl.currentPage = 0
        
        if self.items.count > 10 {
            self.pageControl.hidesForSinglePage = false
            if #available(iOS 14.0, *) {
                self.pageControl.backgroundStyle = .automatic
            }
        }
    }
    
    @objc private func pageControlTapped(_ sender: UIPageControl) {
        let page = sender.currentPage
        
        let cellWidth = Const.itemSize.width + Const.itemSpacing
        let targetOffset = cellWidth * CGFloat(page) - collectionView.contentInset.left
        
        collectionView.setContentOffset(CGPoint(x: targetOffset, y: 0), animated: true)
        
        currentPage = page
    }
    
    private func applyInitialScale() {
        let visibleCells = collectionView.visibleCells
        let centerX = collectionView.contentOffset.x + collectionView.frame.size.width / 2
        
        for cell in visibleCells {
            let cellCenterX = cell.center.x
            let distanceFromCenter = abs(cellCenterX - centerX)
            let maxDistance = collectionView.frame.size.width / 2
            let scale = max(0.8, 1 - (distanceFromCenter / maxDistance) * 0.2)
            
            cell.transform = CGAffineTransform(scaleX: scale + 0.1, y: scale)
        }
    }
    
    private func updatePageControlFromScroll() {
        let cellWidth = Const.itemSize.width + Const.itemSpacing
        let scrolledOffsetX = collectionView.contentOffset.x + collectionView.contentInset.left
        let page = Int(round(scrolledOffsetX / cellWidth))
        
        if page >= 0 && page < items.count && pageControl.currentPage != page {
            pageControl.currentPage = page
            currentPage = page
        }
    }
}

extension CarouselViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionViewCell.reuseIdentifier, for: indexPath) as! CollectionViewCell
        cell.prepare(color: self.items[indexPath.item])
        return cell
    }
}

extension CarouselViewController: UICollectionViewDelegateFlowLayout {
    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        let scrolledOffsetX = targetContentOffset.pointee.x + scrollView.contentInset.left
        let cellWidth = Const.itemSize.width + Const.itemSpacing
        let index = round(scrolledOffsetX / cellWidth)
        targetContentOffset.pointee = CGPoint(x: index * cellWidth - scrollView.contentInset.left, y: scrollView.contentInset.top)
        
        let targetPage = Int(index)
        if targetPage >= 0 && targetPage < items.count {
            pageControl.currentPage = targetPage
            currentPage = targetPage
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        applyInitialScale()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updatePageControlFromScroll()
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        updatePageControlFromScroll()
    }
}

class CollectionViewCell: UICollectionViewCell {
    static var reuseIdentifier: String {
        return "\(self)"
    }
    
    private let viewContainer: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.addSubview(self.viewContainer)
        NSLayoutConstraint.activate([
            self.viewContainer.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            self.viewContainer.leftAnchor.constraint(equalTo: self.contentView.leftAnchor),
            self.viewContainer.rightAnchor.constraint(equalTo: self.contentView.rightAnchor),
            self.viewContainer.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),
        ])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.prepare(color: nil)
    }
    
    func prepare(color: UIColor?) {
        self.viewContainer.backgroundColor = color
    }
}

private var randomColor: UIColor {
    UIColor(red: CGFloat(drand48()), green: CGFloat(drand48()), blue: CGFloat(drand48()), alpha: 1.0)
}
