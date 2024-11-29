//
//  GameScene.swift
//  wordsearch
//
//  Created by Overtime on 11/27/24.
//

import SpriteKit
import GameplayKit
import UIKit

class GameScene: SKScene {
    
    private let gridWidth = 8
    private let gridHeight = 8
    private let cellSize: CGFloat = 70.0
    private var gridNode: SKNode?
    //private let gridOffset = CGPoint(x: -350, y: -550)
    
    private var letters: [[SKLabelNode]] = []
    private let words = ["SWIFT", "SPRITE", "GAME", "FUN", "CODE", "GAY"]
    private var grid: [[Character]] = []
    
    private var selectedLetters: [(row: Int, col: Int)] = []
    private var touchStartPosition: CGPoint?
    private var currentSelection: SKShapeNode?
    
    private var foundWords: Set<String> = []
    private var wordBankLabels: [String: SKLabelNode] = [:]
    
    override func didMove(to view: SKView) {
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        Task {
            setupGrid()
        }
    }
    
    private func setupGrid() {
        gridNode?.removeFromParent()
        gridNode = SKNode()
        letters = Array(repeating: Array(repeating: SKLabelNode(), count: gridWidth), count: gridHeight)
        grid = Array(repeating: Array(repeating: " ", count: gridWidth), count: gridHeight)
        
        let gridWidth = CGFloat(self.gridWidth) * cellSize
        let gridHeight = CGFloat(self.gridHeight) * cellSize
        
        let startX = -gridWidth / 2
        let startY = -gridHeight / 2
        
        createWordBank(above: startY + gridHeight + 100)
        placeWords()
        
        for row in 0..<self.gridHeight {
            for col in 0..<self.gridWidth {
                let cellNode = SKShapeNode(rectOf: CGSize(width: cellSize, height: cellSize))
                cellNode.position = CGPoint(
                    x: startX + CGFloat(col) * cellSize + cellSize/2,
                    y: startY + CGFloat(row) * cellSize + cellSize/2
                )
                cellNode.strokeColor = .white
                cellNode.lineWidth = 1.0
                
                let letter = SKLabelNode(fontNamed: "Arial")
                letter.text = String(grid[row][col])
                letter.fontSize = 30
                letter.fontColor = .white
                letter.verticalAlignmentMode = .center
                letter.horizontalAlignmentMode = .center
                letters[row][col] = letter
                
                cellNode.addChild(letter)
                gridNode?.addChild(cellNode)
            }
        }
        
        if let gridNode = gridNode {
            addChild(gridNode)
        }
        
        fillEmptySpaces()
    }
    
    private func createWordBank(above yPosition: CGFloat) {
        // Create background for word bank
        let padding: CGFloat = 20
        let wordHeight: CGFloat = 40
        let wordsPerRow = 3
        let wordSpacing: CGFloat = 120
        
        // Calculate rows needed
        let numRows = Int(ceil(Float(words.count) / Float(wordsPerRow)))
        
        // Create background
        let bankWidth = CGFloat(wordsPerRow) * wordSpacing
        let bankHeight = CGFloat(numRows) * wordHeight + padding * 2
        let background = SKShapeNode(rectOf: CGSize(width: bankWidth, height: bankHeight + 50))
        background.fillColor = .darkGray
        background.strokeColor = .white
        background.alpha = 0.3
        background.position = CGPoint(x: 0, y: yPosition + bankHeight/2)
        addChild(background)
        
        // Add topic label
        let topicLabel = SKLabelNode(fontNamed: "Arial")
        topicLabel.text = "stuff lol"
        topicLabel.fontSize = 36
        topicLabel.fontColor = .white
        topicLabel.position = CGPoint(x: 0, y: yPosition + bankHeight + 30)
        addChild(topicLabel)
        
        // Place words
        for (index, word) in words.enumerated() {
            let row = index / wordsPerRow
            let col = index % wordsPerRow
            
            let wordLabel = SKLabelNode(fontNamed: "Arial")
            wordLabel.text = word
            wordLabel.fontSize = 30
            wordLabel.fontColor = .white
            
            // Calculate position
            let x = -bankWidth/2 + wordSpacing * CGFloat(col) + wordSpacing/2
            let y = yPosition + bankHeight - padding - CGFloat(row) * wordHeight
            
            wordLabel.position = CGPoint(x: x, y: y)
            addChild(wordLabel)
            wordBankLabels[word] = wordLabel
        }
    }
    
    private func placeWords() {
        for word in words {
            var placed = false
            var attempts = 0
            
            while !placed && attempts < 100 {
                let row = Int.random(in: 0..<gridHeight)
                let col = Int.random(in: 0..<gridWidth)
                
                let directions = [(0,1), (1,0), (1,1), (-1,1)]
                let direction = directions.randomElement()!
                
                if canPlaceWord(word, at: (row, col), direction: direction) {
                    placeWord(word, at: (row, col), direction: direction)
                    placed = true
                }
                
                attempts += 1
            }
        }
    }
    
    private func canPlaceWord(_ word: String, at position: (row: Int, col: Int), direction: (dx: Int, dy: Int)) -> Bool {
        let length = word.count
        
        for i in 0..<length {
            let newRow = position.row + (direction.dy * i)
            let newCol = position.col + (direction.dx * i)
            
            if newRow < 0 || newRow >= gridHeight || newCol < 0 || newCol >= gridWidth {
                return false
            }
            
            if grid[newRow][newCol] != " " && grid[newRow][newCol] != Array(word)[i] {
                return false
            }
        }
        
        return true
    }
    
    private func placeWord(_ word: String, at position: (row: Int, col: Int), direction: (dx: Int, dy: Int)) {
        let characters = Array(word)
        
        for (index, char) in characters.enumerated() {
            let newRow = position.row + (direction.dy * index)
            let newCol = position.col + (direction.dx * index)
            grid[newRow][newCol] = char
        }
    }
    
    private func fillEmptySpaces() {
        for row in 0..<gridHeight {
            for col in 0..<gridWidth {
                if grid[row][col] == " " {
                    let randomChar = Character(String("ABCDEFGHIJKLMNOPQRSTUVWXYZ".randomElement()!))
                    grid[row][col] = randomChar
                    letters[row][col].text = String(randomChar)
                }
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: gridNode ?? self)
        touchStartPosition = location
        selectedLetters.removeAll()
        
        if let (row, col) = convertPointToGrid(location) {
            // Check if the touched letter is part of any found word
            let isPartOfFoundWord = foundWords.contains { word in
                let wordPositions = getPositionsForWord(word)
                return wordPositions.contains { $0 == (row, col) }
            }
            
            // Only allow selection if the letter is not part of a found word
            if !isPartOfFoundWord {
                selectedLetters.append((row, col))
                highlightCell(at: row, col)
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: gridNode ?? self)
        
        if let (row, col) = convertPointToGrid(location),
           let (startRow, startCol) = selectedLetters.first {
            // Calculate direction
            let rowDiff = row - startRow
            let colDiff = col - startCol
            
            let isHorizontal = abs(rowDiff) == 0
            let isVertical = abs(colDiff) == 0
            let isDiagonal = abs(rowDiff) == abs(colDiff)
            
            if isHorizontal || isVertical || isDiagonal {
                let firstPosition = selectedLetters[0]
                selectedLetters = [selectedLetters[0]]
                
                // Clear previous selection highlights
                gridNode?.children.forEach { node in
                    if let shapeNode = node as? SKShapeNode, shapeNode.fillColor == SKColor.blue {
                        if let (nodeRow, nodeCol) = convertPointToGrid(node.position),
                           nodeRow == firstPosition.row && nodeCol == firstPosition.col {
                            return
                        }
                        node.removeFromParent()
                    }
                }
                
                // Reset only non-found word letters
                for r in 0..<gridHeight {
                    for c in 0..<gridWidth {
                        let isPartOfFoundWord = foundWords.contains { word in
                            let wordPositions = getPositionsForWord(word)
                            return wordPositions.contains { $0 == (r, c) }
                        }
                        
                        if !isPartOfFoundWord {
                            if r == firstPosition.row && c == firstPosition.col {
                                letters[r][c].fontColor = .yellow
                                letters[r][c].setScale(1.2)
                            } else {
                                letters[r][c].fontColor = .white
                                letters[r][c].setScale(1.0)
                            }
                        }
                    }
                }
                
                let steps = max(abs(rowDiff), abs(colDiff))
                if steps > 0 {
                    let rowStep = rowDiff / steps
                    let colStep = colDiff / steps
                    
                    for i in 0...steps {
                        let newRow = startRow + (rowStep * i)
                        let newCol = startCol + (colStep * i)
                        if newRow >= 0 && newRow < gridHeight && newCol >= 0 && newCol < gridWidth {
                            // Check if new position is part of a found word
                            let isPartOfFoundWord = foundWords.contains { word in
                                let wordPositions = getPositionsForWord(word)
                                return wordPositions.contains { $0 == (newRow, newCol) }
                            }
                            
                            if !isPartOfFoundWord {
                                let position = (newRow, newCol)
                                if !selectedLetters.contains(where: { $0 == position }) {
                                    selectedLetters.append(position)
                                    highlightCell(at: newRow, newCol)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let word = getSelectedWord()
        if words.contains(word) && !foundWords.contains(word) {
            print("Found word: \(word)")
            foundWords.insert(word)
            crossOutFromWordBank(word)
            crossOutWordInGrid()
        }
        clearSelection()
    }
    
    private func convertPointToGrid(_ point: CGPoint) -> (row: Int, col: Int)? {
        let gridWidth = CGFloat(self.gridWidth) * cellSize
        let gridHeight = CGFloat(self.gridHeight) * cellSize
        let startX = -gridWidth / 2
        let startY = -gridHeight / 2
        
        let col = Int((point.x - startX) / cellSize)
        let row = Int((point.y - startY) / cellSize)
        
        if row >= 0 && row < self.gridHeight && col >= 0 && col < self.gridWidth {
            return (row, col)
        }
        return nil
    }
    
    private func highlightCell(at row: Int, _ col: Int) {
        // Check if the cell is part of a found word
        let isPartOfFoundWord = foundWords.contains { word in
            let wordPositions = getPositionsForWord(word)
            return wordPositions.contains { $0 == (row, col) }
        }
        
        // Only highlight if the cell is not part of a found word
        if !isPartOfFoundWord {
            // Highlight background
            let highlight = SKShapeNode(rectOf: CGSize(width: cellSize, height: cellSize))
            highlight.fillColor = .blue
            highlight.alpha = 0.3
            
            // Calculate grid position
            let startX = -CGFloat(gridWidth) * cellSize / 2
            let startY = -CGFloat(gridHeight) * cellSize / 2
            
            highlight.position = CGPoint(
                x: startX + CGFloat(col) * cellSize + cellSize / 2,
                y: startY + CGFloat(row) * cellSize + cellSize / 2
            )
            
            gridNode?.addChild(highlight)
            
            // Make letter glow yellow and scale up
            letters[row][col].fontColor = .yellow
            letters[row][col].setScale(1.2)
        }
    }
    
    private func clearSelection() {
        // Reset letter appearances and scale
        for (row, col) in selectedLetters {
            if !foundWords.contains(getSelectedWord()) {
                letters[row][col].fontColor = .white
                letters[row][col].setScale(1.0)
            }
        }
        
        selectedLetters.removeAll()
        gridNode?.children.forEach { node in
            if let shapeNode = node as? SKShapeNode, shapeNode.fillColor == SKColor.blue {
                node.removeFromParent()
            }
        }
    }
    
    private func getSelectedWord() -> String {
        return selectedLetters.map { grid[$0.row][$0.col] }.map(String.init).joined()
    }
    
    private func crossOutFromWordBank(_ word: String) {
        if let label = wordBankLabels[word] {
            // Create strikethrough line
            let strikethrough = SKShapeNode()
            let path = CGMutablePath()
            
            let wordWidth = CGFloat(word.count) * (label.fontSize * 0.6)
            let extensionLength: CGFloat = label.fontSize * 0.2
            let strikethroughY: CGFloat = -label.fontSize * 0.15
            
            path.move(to: CGPoint(x: -wordWidth/2 - extensionLength, y: strikethroughY))
            path.addLine(to: CGPoint(x: wordWidth/2 + extensionLength, y: strikethroughY))
            
            strikethrough.path = path
            strikethrough.strokeColor = .red
            strikethrough.lineWidth = 2.0
            
            // Add animation
            strikethrough.alpha = 0
            label.addChild(strikethrough)
            
            let fadeIn = SKAction.fadeIn(withDuration: 0.2)
            strikethrough.run(fadeIn)
            
            // Change word color to gray
            label.fontColor = .gray
        }
    }
    
    private func crossOutWordInGrid() {
        let startPoint = selectedLetters.first!
        let endPoint = selectedLetters.last!
        
        let line = SKShapeNode()
        let path = CGMutablePath()
        
        let gridWidth = CGFloat(self.gridWidth) * cellSize
        let gridHeight = CGFloat(self.gridHeight) * cellSize
        let startX = -gridWidth / 2
        let startY = -gridHeight / 2
        
        // Calculate centered positions with extended length
        let direction = CGPoint(
            x: CGFloat(endPoint.col - startPoint.col),
            y: CGFloat(endPoint.row - startPoint.row)
        )
        let extensionLength: CGFloat = cellSize * 0.1 // Extend by 10% of cell size
        
        let start = CGPoint(
            x: startX + CGFloat(startPoint.col) * cellSize + cellSize/2 - (direction.x * extensionLength),
            y: startY + CGFloat(startPoint.row) * cellSize + cellSize/2 - (direction.y * extensionLength)
        )
        
        let end = CGPoint(
            x: startX + CGFloat(endPoint.col) * cellSize + cellSize/2 + (direction.x * extensionLength),
            y: startY + CGFloat(endPoint.row) * cellSize + cellSize/2 + (direction.y * extensionLength)
        )
        
        path.move(to: start)
        path.addLine(to: end)
        line.path = path
        line.strokeColor = .red
        line.lineWidth = 3.0
        
        // Add glow effect to the line
        line.glowWidth = 2.0
        line.strokeColor = .red
        
        gridNode?.addChild(line)
        
        // Change color of found word letters
        for (row, col) in selectedLetters {
            letters[row][col].fontColor = .gray
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
    
    // Add this helper function to get positions for a word
    private func getPositionsForWord(_ word: String) -> [(row: Int, col: Int)] {
        var positions: [(row: Int, col: Int)] = []
        for row in 0..<gridHeight {
            for col in 0..<gridWidth {
                let directions = [(0,1), (1,0), (1,1), (-1,1)]
                
                for direction in directions {
                    var currentPositions: [(row: Int, col: Int)] = []
                    var currentWord = ""
                    var currentRow = row
                    var currentCol = col
                    
                    for _ in 0..<word.count {
                        if currentRow >= 0 && currentRow < gridHeight &&
                            currentCol >= 0 && currentCol < gridWidth {
                            currentWord += String(grid[currentRow][currentCol])
                            currentPositions.append((row: currentRow, col: currentCol))
                            currentRow += direction.0
                            currentCol += direction.1
                        }
                    }
                    
                    if currentWord == word {
                        positions = currentPositions
                        break
                    }
                }
            }
        }
        return positions
    }
}
