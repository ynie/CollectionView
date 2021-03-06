//
//  CollectionViewLayout.swift
//  Lingo
//
//  Created by Wesley Byrne on 1/27/16.
//  Copyright © 2016 The Noun Project. All rights reserved.
//

import Foundation



/**
 *  The delegate for CollectionViewColumnLayout to dynamically customize the layout
 */
@objc public protocol CollectionViewDelegateColumnLayout: CollectionViewDelegate {
    
    
    // MARK: - Spacing & Insets
    /*-------------------------------------------------------------------------------*/
    /**
     Asks the delegate for the number fo columns in a section
     
     - Parameter collectionView: The collection view
     - Parameter collectionViewLayout: The layout
     - Parameter section: A section index
     
     - Returns: The desired number of columns in the section
     
     */
    @objc optional func collectionView (_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout,
                                        numberOfColumnsInSection section: Int) -> Int
    
    
    /**
     Asks the delegate for insets to be applied to content of a given section
     
     - Parameter collectionView: The collection view
     - Parameter collectionViewLayout: The layout
     - Parameter section: A section index
     
     - Returns: <#EdgeInsets return description#>
     
     */
    @objc optional func collectionView (_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout,
                                        insetForSectionAt section: NSInteger) -> NSEdgeInsets
    
    
    // Between to items in the same column
    
    /**
     Asks the delegate for the item spacing to be applied to items of the same column of a section
     
     - Parameter collectionView: The collection view
     - Parameter collectionViewLayout: The layout
     - Parameter section: A section index
     
     - Returns: <#CGFloat return description#>
     
     */
    @objc optional func collectionView (_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout,
                                        interitemSpacingForSectionAt section: Int) -> CGFloat
    
    
    /**
     Asks the delegate for the column spacing to applied to items in a given section
     
     - Parameter collectionView: The collection view
     - Parameter collectionViewLayout: The layout
     - Parameter section: A section index
     
     - Returns: <#CGFloat return description#>
     
     */
    @objc optional func collectionview(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout,
                                       columnSpacingForSectionAt section: Int) -> CGFloat
    

    
    
    // MARK: - Item Size
    /*-------------------------------------------------------------------------------*/
    /**
     The height for the item at the given indexPath (Priority 2)
     
     - parameter collectionView:       The collection view the item is in
     - parameter collectionViewLayout: The CollectionViewLayout
     - parameter indexPath:            The indexPath for the item
     
     - returns: The height for the item
     */
    @objc optional func collectionView (_ collectionView: CollectionView,layout collectionViewLayout: CollectionViewLayout,
        heightForItemAt indexPath: IndexPath) -> CGFloat
    
    /**
     The aspect ration for the item at the given indexPath (Priority 1). Width and height must be greater than 0.
     
     - parameter collectionView:       The collection view the item is in
     - parameter collectionViewLayout: The CollectionViewLayout
     - parameter indexPath:            The indexPath for the item
     
     - returns: The aspect ration for the item
     */
    @objc optional func collectionView (_ collectionView: CollectionView,layout collectionViewLayout: CollectionViewLayout,
        aspectRatioForItemAt indexPath: IndexPath) -> CGSize
    
    // MARK: - Header & Footer Size
    /*-------------------------------------------------------------------------------*/
    
    /**
     Asks the delegate for the height of the header in the given section

     - Parameter collectionView: The collection view
     - Parameter collectionViewLayout: The layout
     - Parameter section: A section index
     
     - Returns: The desired header height or 0 for no header

    */
    @objc optional func collectionView (_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout,
        heightForHeaderInSection section: Int) -> CGFloat
    
    
    /**
     Asks the delegate for the height of the footer in the given section
     
     - Parameter collectionView: The collection view
     - Parameter collectionViewLayout: The layout
     - Parameter section: A section index
     
     - Returns: The desired footer height or 0 for no footer

    */
    @objc optional func collectionView (_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout,
        heightForFooterInSection section: Int) -> CGFloat
    

    }



/**
 CollectionViewLayoutElementKind
*/
public struct CollectionViewLayoutElementKind {
    public static let SectionHeader: String = "CollectionElementKindSectionHeader"
    public static let SectionFooter: String = "CollectionElementKindSectionFooter"
}


/**
 This layout is column based which means you provide the number of columns and cells are placed in the appropriate one. It can be display items all the same size or as a "Pinterest" style layout.
 
 The number of columns can be set dynamically by the delegate or you can provide a default value using `layout.columnCount`.
 
 You can also set the `sectionInsets` and `minimumColumnSpacing` which will affect the width of each column.
 
 With the itemWidth set by the column, you have 3 options to set the height of each item. They are used in the order here. So if aspectRatioForItemAtIndexPath is implemented it is used, otherwise, it checks the next one.
 
 1. aspectRatioForItemAtIndexPath (delegate)
 2. heightForItemAtIndexPath (delegate)
 3. layout.defaultItemHeight
 
 The delegate method aspectRatioForItemAtIndexPath scales the size of the cell to maintain that ratio while fitting within the caclulated column width.
 
 Mixed use of ratios and heights is also supported. Returning CGSize.zero for a ratio will fall back to the hight. If a valid ratio and height are provided, the height will be appended to the height to respect the ratio. For example, if the column width comes out to 100, a ratio of 2 will determine a height of 200. If a height is also provided by the delegate for the same item, say 20 it will be added, totalling 220.
 
*/
open class CollectionViewColumnLayout : CollectionViewLayout {
    
    
    /// The method to use when directing items into columns
    ///
    /// - shortestFirst: Use the current column
    /// - leftToRight: Always insert left to right
    /// - rightToLeft: Always insert right to left
    public enum ItemRenderDirection {
        case shortestFirst
        case leftToRight
        case rightToLeft
    }
    
    //MARK: - Default layout values
    
    /// The default column count
    open var columnCount : NSInteger = 2 { didSet{ invalidate() }}

    /// The spacing between each column
    open var columnSpacing : CGFloat = 8 { didSet{ invalidate() }}
    
    /// The vertical spacing between items in the same column
    open var interitemSpacing : CGFloat = 8 { didSet{ invalidate() }}

    /// The height of section header views
    open var headerHeight : CGFloat = 0.0 { didSet{ invalidate() }}

    /// The height of section footer views
    open var footerHeight : CGFloat = 0.0 { didSet{ invalidate() }}

    /// The default height to apply to all items
    open var itemHeight : CGFloat = 50 { didSet{ invalidate() }}

    /// If supplementary views should respect section insets or fill the CollectionView width
    open var insetSupplementaryViews : Bool = false { didSet{ invalidate() }}
    
    /// If set to true, the layout will invalidate on all bounds changes, if false only on width changes
    open var invalidateOnBoundsChange : Bool = false { didSet{ invalidate() }}

    /// Default insets for all sections
    open var sectionInset : NSEdgeInsets = NSEdgeInsets(top: 8, left: 8, bottom: 8, right: 8) { didSet{ invalidate() }}
    
    // MARK: - Render Options
    /// A hint as to how to render items when deciding which column to place them in
    open var itemRenderDirection : ItemRenderDirection = .leftToRight { didSet{ invalidate() }}
    
    open func numberOfColumnsInSection(_ section: Int) -> Int {
        if columnHeights.count > 0 && section >= 0 && section < columnHeights.count {
            return columnHeights[section].count
        }
        return 0
    }
    
    // Internal caching
    private var _itemWidth : CGFloat = 0
    /// the calculated width of items based on the total width and number of columns (read only)
    public var itemWidth : CGFloat { get { return _itemWidth }}
    
    
    private var numSections : Int { get { return self.collectionView!.numberOfSections }}
    private func columnsInSection(_ section : Int) -> Int {
        // Use the cache if available else ask the delegate
        var cols = sectionColumnAttributes[section]?.count
            ?? self.delegate?.collectionView?(self.collectionView!, layout: self, numberOfColumnsInSection: section) ?? self.columnCount
        if cols <= 0 { cols = 1 }
        return cols
    }
    
    //  private property and method above.
    private weak var delegate : CollectionViewDelegateColumnLayout? { return self.collectionView!.delegate as? CollectionViewDelegateColumnLayout }
    
    private var columnHeights : [[CGFloat]] = []
    private var sectionItemAttributes : [[CollectionViewLayoutAttributes]] = []
    private var sectionColumnAttributes : [Int : [[CollectionViewLayoutAttributes]]] = [:]
    private var allItemAttributes : [CollectionViewLayoutAttributes] = []
    private var headersAttributes : [Int:CollectionViewLayoutAttributes] = [:]
    private var footersAttributes : [Int:CollectionViewLayoutAttributes] = [:]
    private var sectionIndexPaths : [Int : Set<IndexPath>] = [:]
    private var sectionFrames   : [Int : CGRect] = [:]

//    private var unionRects : [CGRect] = []
    private let unionSize = 20
    
    override public init() {
        super.init()
    }
    
    
    func itemWidthInSectionAtIndex (_ section : NSInteger) -> CGFloat {
        let colCount = self.delegate?.collectionView?(self.collectionView!, layout: self, numberOfColumnsInSection: section) ?? self.columnCount
        var insets : NSEdgeInsets
        if let sectionInsets = self.delegate?.collectionView?(self.collectionView!, layout: self, insetForSectionAt: section){
            insets = sectionInsets
        }else{
            insets = self.sectionInset
        }
        let width:CGFloat = self.collectionView!.contentVisibleRect.size.width - insets.left - insets.right
        let spaceColumCount:CGFloat = CGFloat(colCount-1)
        return floor((width - (spaceColumCount*self.columnSpacing)) / CGFloat(colCount))
    }
    
    
    private var _lastSize = CGSize.zero
    override open func shouldInvalidateLayout(forBoundsChange newBounds : CGRect) -> Bool {
        defer { self._lastSize = newBounds.size }
//        if invalidateOnBoundsChange {
        return _lastSize != newBounds.size
//        }
//        return _lastSize.width != newBounds.size.width
    }
    
    override open func prepare(){
        
        self.headersAttributes.removeAll()
        self.footersAttributes.removeAll()
        self.sectionIndexPaths.removeAll()
        self.sectionFrames.removeAll()
        self.columnHeights.removeAll(keepingCapacity: false)
        self.allItemAttributes.removeAll()
        self.sectionItemAttributes.removeAll()
        self.sectionColumnAttributes.removeAll()
        self.allIndexPaths.removeAll()
        
        guard let cv = self.collectionView, cv.numberOfSections > 0 else {
            return
        }
        let numberOfSections = cv.numberOfSections
        let contentInsets = cv.contentInsets
        
        var top : CGFloat = self.collectionView?.leadingView?.bounds.size.height ?? 0
        for section in 0..<numberOfSections {
            let colCount = self.columnsInSection(section)
            
            /*
            * 1. Get section-specific metrics (minimumInteritemSpacing, sectionInset)
            */
//            let colCount = self.columnsInSection(section)
            let sectionInsets :  NSEdgeInsets =  self.delegate?.collectionView?(cv, layout: self, insetForSectionAt: section) ?? self.sectionInset
            let itemSpacing : CGFloat = self.delegate?.collectionView?(cv, layout: self, interitemSpacingForSectionAt: section) ?? self.interitemSpacing
            let colSpacing = self.delegate?.collectionview?(cv, layout: self, columnSpacingForSectionAt: section) ?? self.columnSpacing
            
            let contentWidth = cv.contentVisibleRect.size.width - (sectionInsets.left + sectionInsets.right + contentInsets.left + contentInsets.right)
            let spaceColumCount = CGFloat(colCount-1)
            let itemWidth = round((contentWidth - (spaceColumCount*colSpacing)) / CGFloat(colCount))
            _itemWidth = itemWidth
            
            var sectionRect: CGRect = CGRect(x: sectionInsets.left, y: top, width: contentWidth, height: 0)
            /*
            * 2. Section header
            */
            let heightHeader : CGFloat = self.delegate?.collectionView?(cv, layout: self, heightForHeaderInSection: section) ?? self.headerHeight
            if heightHeader > 0 {
                let attributes = CollectionViewLayoutAttributes(forSupplementaryViewOfKind: CollectionViewLayoutElementKind.SectionHeader, with: IndexPath.for(section:section))
                attributes.alpha = 1
                attributes.frame = insetSupplementaryViews ?
                     CGRect(x: sectionInsets.left, y: top, width: cv.contentVisibleRect.size.width - sectionInsets.left - sectionInsets.right, height: heightHeader)
                    : CGRect(x: 0, y: top, width: cv.contentVisibleRect.size.width, height: heightHeader)
                self.headersAttributes[section] = attributes
                self.allItemAttributes.append(attributes)
                top = attributes.frame.maxY
            }
            
            top += sectionInsets.top
            columnHeights.append([CGFloat](repeating: top, count: colCount))
            
            var sIndexPaths = Set<IndexPath>()
            /*
            * 3. Section items
            */
            let itemCount = cv.numberOfItems(in: section)
            var itemAttributes :[CollectionViewLayoutAttributes] = []
            sectionColumnAttributes[section] = [Array](repeating: [], count: colCount)
            
            // Item will be put into shortest column.
            for idx in 0..<itemCount {
                let indexPath = IndexPath.for(item:idx, section: section)
                sIndexPaths.insert(indexPath)
                allIndexPaths.append(indexPath)
                
                let columnIndex = self.nextColumnIndexForItem(indexPath)
                let xOffset = sectionInsets.left + round((itemWidth + colSpacing) * CGFloat(columnIndex))
                let yOffset = self.columnHeights[section][columnIndex]
                var itemHeight : CGFloat = 0
                let aSize = self.delegate?.collectionView?(cv, layout: self, aspectRatioForItemAt: indexPath)
                if aSize != nil && aSize!.width != 0 && aSize!.height != 0 {
                    let h = aSize!.height * (itemWidth/aSize!.width)
                    itemHeight = floor(h)
                    
                    if let addHeight = self.delegate?.collectionView?(cv, layout: self, heightForItemAt: indexPath) {
                        itemHeight += addHeight
                    }
                }
                else {
                    itemHeight = self.delegate?.collectionView?(cv, layout: self, heightForItemAt: indexPath) ?? self.itemHeight
                }
                
                let attributes = CollectionViewLayoutAttributes(forCellWith: indexPath)
                attributes.alpha = 1
                attributes.frame = CGRect(x: xOffset, y: CGFloat(yOffset), width: itemWidth, height: itemHeight)
                itemAttributes.append(attributes)
                self.allItemAttributes.append(attributes)
                self.columnHeights[section][columnIndex] = attributes.frame.maxY + itemSpacing;
                self.sectionColumnAttributes[section]?[columnIndex].append(attributes)
            }
            self.sectionItemAttributes.append(itemAttributes)
            self.sectionIndexPaths[section] = sIndexPaths
            
            /*
            * 4. Section footer
            */
            let columnIndex  = self.longestColumnIndexInSection(section)
            top = self.columnHeights[section][columnIndex] - itemSpacing
            
            let footerHeight = self.delegate?.collectionView?(cv, layout: self, heightForFooterInSection: section) ?? self.footerHeight
            if footerHeight > 0 {
                let attributes = CollectionViewLayoutAttributes(forSupplementaryViewOfKind: CollectionViewLayoutElementKind.SectionFooter, with: IndexPath.for(item:0, section: section))
                attributes.alpha = 1
                attributes.frame = insetSupplementaryViews ?
                    CGRect(x: sectionInsets.left, y: top, width: cv.contentVisibleRect.size.width - sectionInsets.left - sectionInsets.right, height: footerHeight)
                    : CGRect(x: 0, y: top, width: self.collectionView!.contentVisibleRect.size.width, height: footerHeight)
                self.footersAttributes[section] = attributes
                self.allItemAttributes.append(attributes)
                top = attributes.frame.maxY
            }
            top += sectionInsets.bottom
            
            sectionRect.size.height = top - sectionRect.origin.y
            sectionFrames[section] = sectionRect

        }
    }
    
    override open var collectionViewContentSize : CGSize {
        guard let cv = collectionView else { return CGSize.zero }
        let numberOfSections = cv.numberOfSections
        if numberOfSections == 0{ return CGSize.zero }
        
        var contentSize = cv.contentVisibleRect.size as CGSize
        contentSize.width = contentSize.width - (cv.contentInsets.left + cv.contentInsets.right)
        
        let height = self.sectionFrames[cv.numberOfSections - 1]?.maxY ?? 0
        if height == 0 { return CGSize.zero }
        contentSize.height = height
        return  contentSize
    }
    
    open override func rectForSection(_ section: Int) -> CGRect {
        return sectionFrames[section] ?? CGRect.zero
    }
    open override func contentRectForSection(_ section: Int) -> CGRect {
        return sectionFrames[section] ?? CGRect.zero
    }
    
    
    
    open override func layoutAttributesForItems(in rect: CGRect) -> [CollectionViewLayoutAttributes] {
        var attrs : [CollectionViewLayoutAttributes] = []
        
        guard let cv = self.collectionView else { return attrs }
        if rect.equalTo(CGRect.zero) || cv.numberOfSections == 0 { return attrs }
        for sectionIndex in 0...cv.numberOfSections - 1 {
            
            guard let sectionFrame = cv.frameForSection(at: sectionIndex),
                let columns = self.sectionColumnAttributes[sectionIndex] else { continue }
            if sectionFrame.isEmpty || !sectionFrame.intersects(rect) { continue }
            for column in columns {
                for attr in column {
                    if attr.frame.intersects(rect) {
                        attrs.append(attr)
                    }
                    else if attr.frame.origin.y > rect.maxY { break }
                }
            }
        }
        return attrs
    }
    
    open override func layoutAttributesForItem(at indexPath: IndexPath) -> CollectionViewLayoutAttributes? {
        if indexPath._section >= self.sectionItemAttributes.count{ return nil }
        if indexPath._item >= self.sectionItemAttributes[indexPath._section].count{ return nil }
        let list = self.sectionItemAttributes[indexPath._section]
        return list[indexPath._item]
    }
    
    open override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> CollectionViewLayoutAttributes? {
        
        if elementKind == CollectionViewLayoutElementKind.SectionHeader {
            var attrs = self.headersAttributes[indexPath._section]
            if pinHeadersToTop, let currentAttrs = attrs?.copy(), let cv = self.collectionView {
                
                let contentOffset = cv.contentOffset
                let frame = currentAttrs.frame
//                if indexPath._section == 0 && contentOffset.y < -cv.contentInsets.top {
//                    currentAttrs.frame.origin.y = 0
//                    currentAttrs.floating = false
//                }
//                else {
                    var nextHeaderOrigin = CGPoint(x: CGFloat.greatestFiniteMagnitude, y: CGFloat.greatestFiniteMagnitude)
                    if let nextHeader = self.headersAttributes[indexPath._section + 1] {
                        nextHeaderOrigin = nextHeader.frame.origin
                    }
                    let topInset = cv.contentInsets.top 
                    currentAttrs.frame.origin.y =  min(max(contentOffset.y + topInset , frame.origin.y), nextHeaderOrigin.y - frame.height)
                    currentAttrs.floating = indexPath._section == 0 || currentAttrs.frame.origin.y > frame.origin.y
//                }
                attrs = currentAttrs
            }
            return attrs
        }
        else if elementKind == CollectionViewLayoutElementKind.SectionFooter {
            return self.footersAttributes[indexPath._section]
        }
        return nil
    }
    
    
    
    
    open override func scrollRectForItem(at indexPath: IndexPath, atPosition: CollectionViewScrollPosition) -> CGRect? {
        guard var frame = self.layoutAttributesForItem(at: indexPath)?.frame else { return nil }
        let inset = (self.collectionView?.contentInsets.top ?? 0)
        
//        if let fAttr = sectionItemAttributes[indexPath._section].first, let hAttr = headersAttributes[indexPath._section] {
//           inset -= (fAttr.frame.minY - hAttr.frame.maxY)
//        }
        
        if self.pinHeadersToTop, let attrs = self.layoutAttributesForSupplementaryView(ofKind: CollectionViewLayoutElementKind.SectionHeader, at: IndexPath.for(item:0, section: indexPath._section)) {
            let y = (frame.origin.y - attrs.frame.size.height) // + inset
            
            let height = frame.size.height + attrs.frame.size.height
            frame.size.height = height
            frame.origin.y = y
        }
        else {
            frame.origin.y = frame.origin.y + inset
        }
        return frame
    }
    
    
    /*!
    Find the shortest column in a particular section
    
    :param: section The section to find the shortest column for.
    :returns: The index of the shortest column in the given section
    */
    private func shortestColumnIndexInSection(_ section: Int) -> NSInteger {
        let min =  self.columnHeights[section].min()!
        return self.columnHeights[section].index(of: min)!
    }
    
    /*!
    Find the longest column in a particular section
    
    :param: section The section to find the longest column for.
    :returns: The index of the longest column in the given section
    */
    private func longestColumnIndexInSection(_ section: Int) -> NSInteger {
        let max =  self.columnHeights[section].max()!
        return self.columnHeights[section].index(of: max)!
    }
    
    /*!
    Find the index of the column the for the next item at the given index path
    
    :param: The indexPath of the section to look ahead of
    :returns: The index of the next column
    */
    private func nextColumnIndexForItem (_ indexPath : IndexPath) -> Int {
        let colCount = self.columnsInSection(indexPath._section)
        var index = 0
        switch (self.itemRenderDirection){
        case .shortestFirst :
            index = self.shortestColumnIndexInSection(indexPath._section)
        case .leftToRight :
            index = (indexPath._item % colCount)
        case .rightToLeft:
            index = (colCount - 1) - (indexPath._item % colCount);
        }
        return index
    }

    
    open override func indexPathsForItems(in rect: CGRect) -> [IndexPath] {
        guard let cv = self.collectionView else { return [] }
        
        var indexPaths = [IndexPath]()
        if rect.equalTo(CGRect.zero) || cv.numberOfSections == 0 { return indexPaths }
        for section in 0...cv.numberOfSections - 1 {
            
            if cv.numberOfItems(in: section) == 0 { continue }
            
            guard let sectionFrame = cv.frameForSection(at: section) else { continue }
            if sectionFrame.isEmpty || !sectionFrame.intersects(rect) { continue }
            
            // If the section is completely show, add all the attrs
            if rect.contains(sectionFrame) {
                if let ips = self.sectionIndexPaths[section] {
                    indexPaths.append(contentsOf: ips)
                }
            }
            else if let columns = self.sectionColumnAttributes[section] , columns.count > 0 {
                for column in columns {
                    for attr in column {
                        if attr.frame.intersects(rect) {
                            indexPaths.append(attr.indexPath as IndexPath)
                        }
                        else if attr.frame.origin.y > rect.maxY { break }
                    }
                }
            }
            
//                        for attr in sectionItemAttributes[sectionIndex] {
//                if attr.frame.intersects(rect) {
//                    indexPaths.insert(attr.indexPath)
//                }
//            }
            
//            guard let sColumns = sectionColumnAttributes[sectionIndex] where sColumns.count > 0 else { continue }
//            let firstColumn = columns[0]
//            
//            var start = -1
//            var end = -1
//            let itemCount = cv.numberOfItems(in: sectionIndex)
//            
//            let maxY = CGRectGetMaxY(rect)
//            for row in 0...firstColumn.count - 1 {
//                let attrs = firstColumn[row]
//                let include = CGRectIntersectsRect(attrs.frame, rect)
//                if !include { continue }
//                if CGRectGetMinY(attrs.frame) > maxY { break }
//                if start == -1 { start = row }
//                end = row
//                indexPaths.insert(NSIndexPath._indexPathForItem(columns.count * row, inSection: sectionIndex))
//            }
//            
//            if start == -1 || columns.count == 1 { continue }
//            
//            for c in 1...columns.count - 1 {
//                for r in start...end {
//                    let item = columns.count * r + c
//                    if item < itemCount {
//                        indexPaths.insert(NSIndexPath.for(item:item, section: sectionIndex))
//                    }
//                }
//            }

        }
        return indexPaths
    }
    
    open override func indexPathForNextItem(moving direction: CollectionViewDirection, from currentIndexPath: IndexPath) -> IndexPath? {
        guard let collectionView = self.collectionView else { fatalError() }
        
        var index = currentIndexPath._item
        var section = currentIndexPath._section
        
        let numberOfSections = collectionView.numberOfSections
        let numberOfItemsInSection = collectionView.numberOfItems(in: currentIndexPath._section)
        
        guard collectionView.rectForItem(at: currentIndexPath) != nil else { return nil }
        
        switch direction {
        case .up:
            guard let cAttrs = collectionView.layoutAttributesForItem(at: currentIndexPath),
                let columns = sectionColumnAttributes[section] else { return nil }
            
            let cFlat = CGRect(x: cAttrs.frame.origin.x, y: 0, width: cAttrs.frame.size.width, height: 50)
            
            for column in columns {
                if let first = column.first {
                    // This is the first item in the column -> Check the previous section
                    if first.indexPath == currentIndexPath {
                        guard let pColumns = sectionColumnAttributes[section - 1] else { return nil }
                        for col in pColumns.reversed() {
                            if let pFirst = col.first {
                                let flat = CGRect(x: pFirst.frame.origin.x, y: 0, width: pFirst.frame.size.width, height: 50)
                                if cFlat.intersects(flat) {
                                    return col.last?.indexPath
                                }
                            }
                        }
                        return sectionItemAttributes[section - 1].last?.indexPath
                    }
                    
                    let flat = CGRect(x: first.frame.origin.x, y: 0, width: first.frame.size.width, height: 50)
                    
                    // Get the same column
                    if cFlat.intersects(flat) {
                        for idx in 0..<column.count {
                            let attr = column[idx]
                            if attr.indexPath == currentIndexPath {
                                return column[idx - 1].indexPath
                            }
                        }
                    }
                }
            }
            return nil
            
        case .down:
            
            
            guard let cAttrs = collectionView.layoutAttributesForItem(at: currentIndexPath),
                let columns = sectionColumnAttributes[section] else { return nil }
            
            let cFlat = CGRect(x: cAttrs.frame.origin.x, y: 0, width: cAttrs.frame.size.width, height: 50)
            
            for column in columns {
                if let first = column.first {
                    // This is the last item in the column -> Check the previous section
                    if column.last?.indexPath == currentIndexPath {
                        guard let pColumns = sectionColumnAttributes[section + 1] else { return nil }
                        
                        for col in pColumns {
                            if let pFirst = col.first {
                                let flat = CGRect(x: pFirst.frame.origin.x, y: 0, width: pFirst.frame.size.width, height: 50)
                                if cFlat.intersects(flat) {
                                    return col.first?.indexPath
                                }
                            }
                        }
                        return sectionItemAttributes[section + 1].last?.indexPath
                    }
                    
                    let flat = CGRect(x: first.frame.origin.x, y: 0, width: first.frame.size.width, height: 50)
                    
                    // Get the same column
                    if cFlat.intersects(flat) {
                        for idx in 0..<column.count {
                            let attr = column[idx]
                            if attr.indexPath == currentIndexPath {
                                return column[idx + 1].indexPath
                            }
                        }
                    }
                }
            }
            return nil
            
        case .left:
            if section == 0 && index == 0 {
                return currentIndexPath
            }
            if index > 0 {
                index = index - 1
            } else {
                section = section - 1
                index = collectionView.numberOfItems(in: currentIndexPath._section - 1) - 1
            }
            return IndexPath.for(item:index, section: section)
        case .right :
            if section == numberOfSections - 1 && index == numberOfItemsInSection - 1 {
                return currentIndexPath
            }
            if index < numberOfItemsInSection - 1 {
                index = index + 1
            } else {
                section = section + 1
                index = 0
            }
            return IndexPath.for(item:index, section: section)
        }
    }
    
}

