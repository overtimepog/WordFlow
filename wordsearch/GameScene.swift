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
    private let wordList = [
        "SWIFT", "CODE", "GAME", "FUN", "APP", "RUN",
        "PLAY", "WIN", "LOOP", "DATA", "TEST", "BUG",
        "BYTE", "FILE", "SORT", "LIST", "MAP", "SET",
        "VIEW", "DRAW", "TAP", "DRAG", "DROP", "SYNC",
        "LOAD", "SAVE", "EDIT", "UNDO", "COPY", "LINK",
        "NODE", "PATH", "GRID", "CELL", "FONT", "TEXT",
        "LINE", "RECT", "SIZE", "MOVE", "FADE", "SPIN",
        "ZOOM", "CLIP", "MASK", "BLUR", "FILL", "TIME"
    ]
    private var words: [String] = []
    private var grid: [[Character]] = []
    
    private var selectedLetters: [(row: Int, col: Int)] = []
    private var touchStartPosition: CGPoint?
    private var currentSelection: SKShapeNode?
    
    private var foundWords: Set<String> = []
    private var wordBankLabels: [String: SKLabelNode] = [:]
    
    override func didMove(to view: SKView) {
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        // Initialize words here
        words = selectedWords
        
        Task {
            setupGrid()
        }
    }
    
    private var selectedWords: [String] {
        let maxLength = max(gridWidth, gridHeight)
        let validWords = wordList.filter { $0.count <= maxLength }
        
        var words: Set<String> = []
        while words.count < 6 && !validWords.isEmpty {
            if let word = validWords.randomElement() {
                words.insert(word)
            }
        }
        return Array(words)
    }
    
    private func setupGrid() {
        gridNode?.removeFromParent()
        gridNode = SKNode()
        letters = Array(repeating: Array(repeating: SKLabelNode(), count: gridWidth), count: gridHeight)
        grid = Array(repeating: Array(repeating: " ", count: gridWidth), count: gridHeight)
        
        // Clear found words when setting up new grid
        foundWords.removeAll()
        
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
        // Sort words by length (longest first) to ensure better placement
        let sortedWords = words.sorted { $0.count > $1.count }
        
        for word in sortedWords {
            var placed = false
            var attempts = 0
            let maxAttempts = 200  // Increased attempts for better placement chances
            
            while !placed && attempts < maxAttempts {
                let row = Int.random(in: 0..<gridHeight)
                let col = Int.random(in: 0..<gridWidth)
                
                // All possible directions
                let directions = [
                    (0,1),   // right
                    (1,0),   // down
                    (1,1),   // diagonal down-right
                    (-1,1),  // diagonal up-right
                    (0,-1),  // left
                    (-1,0),  // up
                    (-1,-1), // diagonal up-left
                    (1,-1)   // diagonal down-left
                ]
                
                // Try each direction in random order
                let shuffledDirections = directions.shuffled()
                for direction in shuffledDirections {
                    if canPlaceWord(word, at: (row, col), direction: direction) {
                        placeWord(word, at: (row, col), direction: direction)
                        placed = true
                        break
                    }
                }
                
                attempts += 1
            }
            
            if !placed {
                print("Warning: Could not place word: \(word)")
            }
        }
    }
    
    private func canPlaceWord(_ word: String, at position: (row: Int, col: Int), direction: (dx: Int, dy: Int)) -> Bool {
        let length = word.count
        let characters = Array(word)
        
        // Check each position the word would occupy
        for i in 0..<length {
            let newRow = position.row + (direction.dy * i)
            let newCol = position.col + (direction.dx * i)
            
            // Check bounds
            if newRow < 0 || newRow >= gridHeight || newCol < 0 || newCol >= gridWidth {
                return false
            }
            
            // Allow overlap only if the letters match
            let currentCell = grid[newRow][newCol]
            if currentCell != " " && currentCell != characters[i] {
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
        
        // Clear any existing selection first
        clearSelection()
        
        if let (row, col) = convertPointToGrid(location) {
            // Check if this position is part of any found word
            let isPartOfFoundWord = isPositionPartOfFoundWord(row: row, col: col)
            
            // Only allow selection if the letter is not part of ANY found word
            if !isPartOfFoundWord {
                selectedLetters.append((row, col))
                highlightCell(at: row, col)
            }
        }
    }
    
    private func isPositionPartOfFoundWord(row: Int, col: Int) -> Bool {
        return foundWords.contains { word in
            let wordPositions = getPositionsForWord(word)
            return wordPositions.contains { $0 == (row, col) }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              !selectedLetters.isEmpty else { return }
        
        let location = touch.location(in: gridNode ?? self)
        
        if let (row, col) = convertPointToGrid(location),
           let (startRow, startCol) = selectedLetters.first,
           !isPositionPartOfFoundWord(row: row, col: col) {
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
                
                // Update appearance of all letters
                for r in 0..<gridHeight {
                    for c in 0..<gridWidth {
                        updateLetterAppearance(row: r, col: c)
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
                                    print("Adding new selection at [\(newRow),\(newCol)]")
                                    selectedLetters.append(position)
                                    highlightCell(at: newRow, newCol)
                                    // Remove direct color setting here - let updateLetterAppearance handle it
                                    updateLetterAppearance(row: newRow, col: newCol)
                                }
                            } else {
                                print("Skipping selection at [\(newRow),\(newCol)] - part of found word")
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
            
            // Update all letters in the grid to ensure proper appearance
            for row in 0..<gridHeight {
                for col in 0..<gridWidth {
                    updateLetterAppearance(row: row, col: col)
                }
            }
            
            // Check if all words are found
            if foundWords.count == words.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.resetGame()
                }
            }
        }
        clearSelection()
    }
    
    private func resetGame() {
        // Clear the found words set
        foundWords.removeAll()
        
        // Remove all nodes from gridNode
        gridNode?.removeAllChildren()
        
        // Remove word bank labels
        wordBankLabels.values.forEach { $0.removeFromParent() }
        wordBankLabels.removeAll()
        
        // Reset the grid and letters arrays
        grid.removeAll()
        letters.removeAll()
        
        // Select new words
        words = selectedWords
        
        // Setup the grid again with new words
        setupGrid()
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
        guard !isPositionPartOfFoundWord(row: row, col: col) else { return }
        
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
        updateLetterAppearance(row: row, col: col)
    }
    
    private func clearSelection() {
        // Update appearance for all letters in the grid
        for row in 0..<gridHeight {
            for col in 0..<gridWidth {
                updateLetterAppearance(row: row, col: col)
            }
        }
        
        selectedLetters.removeAll()
        
        // Remove highlight backgrounds
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
        
        // First, get all positions for the found word to ensure we mark all letters
        let word = getSelectedWord()
        let allWordPositions = getPositionsForWord(word)
        
        // Create the crossout line
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
        let extensionLength: CGFloat = cellSize * 0.1
        
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
        line.glowWidth = 2.0
        
        gridNode?.addChild(line)
        
        // Mark ALL positions of the word as gray, not just the selected letters
        for position in allWordPositions {
            letters[position.row][position.col].fontColor = .gray
            letters[position.row][position.col].setScale(1.0)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
    
    private func updateLetterAppearance(row: Int, col: Int) {
        let isFound = isPositionPartOfFoundWord(row: row, col: col)
        let isSelected = selectedLetters.contains(where: { $0 == (row, col) })
        
        // Debug information
        if isFound {
            print("Letter at [\(row),\(col)] is part of found word")
        }
        if isSelected {
            print("Letter at [\(row),\(col)] is currently selected")
        }
        
        // Found words take precedence over selection
        if isFound {
            letters[row][col].fontColor = .gray
            letters[row][col].setScale(1.0)
            
            // Additional debug check for found words
            for word in foundWords {
                if getPositionsForWord(word).contains(where: { $0 == (row, col) }) {
                    print("Letter at [\(row),\(col)] belongs to found word: \(word)")
                }
            }
        } else if isSelected && !isFound {  // Only allow selection if not part of found word
            letters[row][col].fontColor = .yellow
            letters[row][col].setScale(1.2)
        } else {
            letters[row][col].fontColor = .white
            letters[row][col].setScale(1.0)
        }
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
