//
//  GameScene.swift
//  wordsearch
//
//  Created by Overtime on 11/27/24.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    private let gridSize = 10
    private let cellSize: CGFloat = 40.0
    private var gridNode: SKNode?
    
    override func didMove(to view: SKView) {
        setupGrid()
    }
    
    private func setupGrid() {
        // Remove any existing grid
        gridNode?.removeFromParent()
        
        // Create a new container node for the grid
        gridNode = SKNode()
        
        // Calculate total grid size
        let gridWidth = CGFloat(gridSize) * cellSize
        let gridHeight = CGFloat(gridSize) * cellSize
        
        // Calculate starting position to center the grid
        let startX = (size.width - gridWidth) / 2
        let startY = (size.height - gridHeight) / 2
        
        // Create grid cells
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let cellNode = SKShapeNode(rectOf: CGSize(width: cellSize, height: cellSize))
                cellNode.position = CGPoint(
                    x: startX + CGFloat(col) * cellSize + cellSize/2,
                    y: startY + CGFloat(row) * cellSize + cellSize/2
                )
                cellNode.strokeColor = .white
                cellNode.lineWidth = 1.0
                gridNode?.addChild(cellNode)
            }
        }
        
        if let gridNode = gridNode {
            addChild(gridNode)
        }
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Handle touches if needed
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
