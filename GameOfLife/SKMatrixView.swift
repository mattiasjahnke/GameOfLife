//
//  SKMatrixView.swift
//  Shift
//
//  Created by Mattias Jähnke on 06/05/16.
//  Copyright © 2016 nearedge. All rights reserved.
//

import SpriteKit

class SKMatrixView<MatrixType: GameOfLifeMatrix>: SKScene {
    var matrix: MatrixType?
    var matrixUpdated: ((MatrixType) -> ())?
    
    var showGrid = false
    var gridColor = UIColor.lightGrayColor()
    var cellColor = UIColor.whiteColor()
    
    private var grids: [SKSpriteNode]!
    private var nodePool = [SKNode]()
    
    private var cellSize: CGFloat!
    
    override init(size: CGSize) {
        super.init(size: size)
    }
    
    override func didMoveToView(view: SKView) {
        if grids == nil {
            grids = []
            scaleMode = .ResizeFill
            
            let minSize = max(view.bounds.width, view.bounds.height)
            cellSize = round(minSize / CGFloat(min(matrix!.width, matrix!.height)))
            
            let tileSize = 50
            
            let gridTexture = SKTexture(image: UIImage(
                gridWithBlockSize: cellSize,
                columns: tileSize,
                rows: tileSize, gridColor: .grayColor()))
            
            for x in 0...Int(minSize) / tileSize {
                for y in 0...Int(minSize) / tileSize {
                    let rect = CGRect(x: CGFloat(x * tileSize) * cellSize,
                                      y: CGFloat(y * tileSize) * cellSize,
                                      width: CGFloat(tileSize) * cellSize,
                                      height: CGFloat(tileSize) * cellSize)
                    
                    let grid = SKSpriteNode(texture: gridTexture, color: /*.blackColor()*/.blueColor(), size: gridTexture.size())
                    
                    grid.blendMode = .Replace
                    grid.position = CGPoint(x: CGRectGetMidX(rect), y: CGRectGetMidY(rect))//CGPointMake(CGRectGetMidX(view.bounds),CGRectGetMidY(view.bounds))
                    grid.texture!.filteringMode = .Nearest
                    
                    addChild(grid)
                    grids.append(grid)
                }
            }
            
            if let _ = matrixUpdated {
                view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SKMatrixView.handleTapGesture(_:))))
            }
        }
    }
    
    func handleTapGesture(gesture: UITapGestureRecognizer) {
        guard matrix != nil else { return }
        
        let touchPoint = gesture.locationInView(gesture.view)
        let point = Point(x: Int((touchPoint.x - touchPoint.x % cellSize) / cellSize),
                          y: Int((touchPoint.y - touchPoint.y % cellSize) / cellSize))
        
        if matrix!.contains(point) {
            matrix![point] = !matrix![point]
            if let matrixUpdated = matrixUpdated {
                matrixUpdated(matrix!)
            }
        }
    }
    
    override func update(currentTime: NSTimeInterval) {
        super.update(currentTime)
        
        let points = matrix!.activeCells.map { point -> CGPoint in
            let offset = cellSize / 2.0
            return CGPoint(
                x: CGFloat(point.x) * cellSize + offset,
                y: CGFloat(matrix!.height - point.y - 1) * cellSize + offset - 0.25
            )
        }
        
        while nodePool.count < points.count {
            nodePool.append(SKShapeNode(cellOfSize: CGSizeMake(cellSize - 1, cellSize - 1)))
            self.addChild(nodePool.last!)
        }
        
        for (index, node) in nodePool.enumerate() {
            guard index < points.count else { node.hidden = true; continue }
            node.hidden = false
            node.position = points[index]
        }
    }
}

private extension SKShapeNode {
    convenience init(cellOfSize size: CGSize) {
        self.init(rectOfSize: size)
        antialiased = false
        strokeColor = UIColor.clearColor()
        fillColor = SKColor.whiteColor()
        blendMode = .Replace
        zPosition = 1
    }
}

private extension UIImage {
    convenience init(gridWithBlockSize blockSize: CGFloat, columns: Int, rows: Int, gridColor: UIColor = .grayColor()) {
        // Add 1 to the height and width to ensure the borders are within the sprite
        let size = CGSize(width: CGFloat(columns) * blockSize + 1.0,
                          height: CGFloat(rows) * blockSize + 1.0)
        
        UIGraphicsBeginImageContext(size)
        
        let context = UIGraphicsGetCurrentContext()
        let bezierPath = UIBezierPath()
        let offset:CGFloat = 0.5
        
        // Draw vertical lines
        for i in 0...columns {
            let x = CGFloat(i) * blockSize + offset
            bezierPath.moveToPoint(CGPoint(x: x, y: 0))
            bezierPath.addLineToPoint(CGPoint(x: x, y: size.height))
        }
        // Draw horizontal lines
        for i in 0...rows {
            let y = CGFloat(i) * blockSize + offset
            bezierPath.moveToPoint(CGPoint(x: 0, y: y))
            bezierPath.addLineToPoint(CGPoint(x: size.width, y: y))
        }
        
        gridColor.setStroke()
        bezierPath.lineWidth = 1
        bezierPath.stroke()
        CGContextAddPath(context, bezierPath.CGPath)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.init(CGImage: image.CGImage!)
    }
}
