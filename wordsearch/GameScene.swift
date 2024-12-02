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
        "ZOOM", "CLIP", "MASK", "BLUR", "FILL", "TIME",
        "ARRAY", "CLASS", "DEBUG", "ERROR", "FLOAT", "GUARD",
        "HASH", "INPUT", "JSON", "KEYS", "LABEL", "MODAL",
        "NULL", "OBJECT", "PRINT", "QUERY", "RANGE", "STACK",
        "TUPLE", "URL", "VALUE", "WHILE", "XCODE", "YIELD",
        "ASYNC", "BREAK", "CATCH", "DEFER", "ENUM", "FINAL",
        "FRAME", "GROUP", "HTTPS", "INDEX", "JOIN", "KEYBOARD"
    ]
    private var words: [String] = []
    private var grid: [[Character]] = []
    
    private var selectedLetters: [(row: Int, col: Int)] = []
    private var touchStartPosition: CGPoint?
    private var currentSelection: SKShapeNode?
    
    private var foundWords: Set<String> = []
    private var wordBankLabels: [String: SKLabelNode] = [:]
    
    private enum Direction {
        case right, down, diagonalDownRight, diagonalUpRight
        
        var offset: (dx: Int, dy: Int) {
            switch self {
            case .right: return (0, 1)
            case .down: return (1, 0)
            case .diagonalDownRight: return (1, 1)
            case .diagonalUpRight: return (-1, 1)
            }
        }
        
        static var allCases: [Direction] {
            return [.right, .down, .diagonalDownRight, .diagonalUpRight]
        }
    }
    
    private var highlightedNodes: [SKShapeNode] = []
    
    private struct Constants {
        static let highlightAlpha: CGFloat = 0.3
        static let lineWidth: CGFloat = 2.0
        static let scaleSelected: CGFloat = 1.2
        static let scaleNormal: CGFloat = 1.0
        static let wordBankPadding: CGFloat = 20
        static let wordHeight: CGFloat = 40
        static let wordSpacing: CGFloat = 20
        static let wordsPerRow = 3
        static let letterColorNormal: UIColor = .white
        static let maxRowWidth: CGFloat = 400
    }
    
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
        let wordbankY = startY + gridHeight + 78
        
        createWordBank(above: wordbankY)
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
                letter.fontColor = Constants.letterColorNormal
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
        // Clear previous labels
        wordBankLabels.values.forEach { $0.removeFromParent() }
        wordBankLabels.removeAll()
        
        // Create constants for layout
        let padding = Constants.wordBankPadding
        let wordHeight = Constants.wordHeight
        let maxRowWidth = Constants.maxRowWidth
        let maxWordsPerRow = 3 // Max words allowed per row unless wrapping is needed
        
        // Prepare rows
        var currentRowWords: [SKLabelNode] = []
        var allRows: [[SKLabelNode]] = []
        var currentRowWidth: CGFloat = 0
        
        // Process each word for wrapping
        for word in words {
            // Create a label to calculate its size
            let wordLabel = SKLabelNode(fontNamed: "Arial")
            wordLabel.text = word
            wordLabel.fontSize = 30
            wordLabel.fontColor = .white
            wordLabel.horizontalAlignmentMode = .center
            wordLabel.verticalAlignmentMode = .center
            
            // Calculate the actual width of the word
            let wordWidth = wordLabel.frame.size.width
            
            // Check if the word should wrap (exceeds max width OR max words per row)
            if (currentRowWords.count == maxWordsPerRow || currentRowWidth + wordWidth + CGFloat(currentRowWords.count) * Constants.wordSpacing > maxRowWidth) && !currentRowWords.isEmpty {
                // Add the current row to rows
                allRows.append(currentRowWords)
                currentRowWords = []
                currentRowWidth = 0
            }
            
            // Add the word to the current row
            currentRowWords.append(wordLabel)
            currentRowWidth += wordWidth
        }
        
        // Add the final row if there are leftover words
        if !currentRowWords.isEmpty {
            allRows.append(currentRowWords)
        }
        
        // Calculate bank dimensions
        let bankWidth = maxRowWidth
        let bankHeight = CGFloat(allRows.count) * wordHeight + padding * 2
        let background = SKShapeNode(rectOf: CGSize(width: bankWidth, height: bankHeight + 50))
        background.fillColor = .darkGray
        background.strokeColor = .white
        background.alpha = 0.3
        background.position = CGPoint(x: 0, y: yPosition + bankHeight / 2)
        addChild(background)
        
        // Add topic label
        let topicLabel = SKLabelNode(fontNamed: "Arial")
        topicLabel.text = "stuff lol"
        topicLabel.fontSize = 36
        topicLabel.fontColor = .white
        topicLabel.position = CGPoint(x: 0, y: yPosition + bankHeight + 30)
        addChild(topicLabel)
        
        // Place words in their rows
        for (rowIndex, rowWords) in allRows.enumerated() {
            // Calculate total row width
            let totalRowWidth = rowWords.reduce(0) { $0 + $1.frame.size.width } + CGFloat(rowWords.count - 1) * Constants.wordSpacing
            
            // Center the row by adjusting the starting X position
            var currentX = -totalRowWidth / 2
            let rowY = yPosition + bankHeight - padding - CGFloat(rowIndex) * wordHeight
            
            for wordLabel in rowWords {
                // Set the position of the word label
                let wordWidth = wordLabel.frame.size.width
                wordLabel.position = CGPoint(x: currentX + wordWidth / 2, y: rowY)
                addChild(wordLabel)
                
                // Update word bank dictionary
                if let word = wordLabel.text {
                    wordBankLabels[word] = wordLabel
                }
                
                // Move to the next position
                currentX += wordWidth + Constants.wordSpacing
            }
        }
    }
    
    private func placeWords() {
        var availableSpaces: [(row: Int, col: Int)] = []
        for row in 0..<gridHeight {
            for col in 0..<gridWidth {
                availableSpaces.append((row, col))
            }
        }
        availableSpaces.shuffle()
        
        let sortedWords = words.sorted { $0.count > $1.count }
        for word in sortedWords {
            var placed = false
            for position in availableSpaces {
                for direction in Direction.allCases.shuffled() {
                    let (dx, dy) = direction.offset
                    if canPlaceWordWithoutOverlap(word, at: position, direction: (dx, dy)) {
                        placeWord(word, at: position, direction: (dx, dy))
                        placed = true
                        break
                    }
                }
                if placed { break }
            }
            
            if !placed {
                print("Warning: Could not place word: \(word). Trying with fewer words...")
                // Could implement fallback strategy here if needed
            }
        }
    }
    
    private func canPlaceWordWithoutOverlap(_ word: String, at position: (row: Int, col: Int), direction: (dx: Int, dy: Int)) -> Bool {
        let length = word.count
        
        // Check each position the word would occupy
        for i in 0..<length {
            let newRow = position.row + (direction.dy * i)
            let newCol = position.col + (direction.dx * i)
            
            // Check bounds
            if newRow < 0 || newRow >= gridHeight || newCol < 0 || newCol >= gridWidth {
                return false
            }
            
            // Ensure the cell is empty
            let currentCell = grid[newRow][newCol]
            if currentCell != " " {
                return false
            }
        }
        
        return true
    }
    
    private func placeWord(_ word: String, at position: (row: Int, col: Int), direction: (dx: Int, dy: Int)) {
        for (index, char) in word.enumerated() {
            let newRow = position.row + (direction.dy * index)
            let newCol = position.col + (direction.dx * index)
            grid[newRow][newCol] = char
            letters[newRow][newCol].text = String(char)
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
            // Only proceed if this position is not part of a found word
            if !isPositionPartOfFoundWord(row: row, col: col) {
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
        guard let touch = touches.first, !selectedLetters.isEmpty else { return }
        
        let location = touch.location(in: gridNode ?? self)
        
        if let (row, col) = convertPointToGrid(location),
           let (startRow, startCol) = selectedLetters.first {
            
            // Calculate row and column differences
            let rowDiff = row - startRow
            let colDiff = col - startCol
            
            // Determine the primary direction based on the larger difference
            let isHorizontal = abs(rowDiff) == 0
            let isVertical = abs(colDiff) == 0
            let isDiagonal = abs(rowDiff) == abs(colDiff)
            
            if isHorizontal || isVertical || isDiagonal {
                // Keep the first cell in the selection
                let firstPosition = selectedLetters[0]
                selectedLetters = [firstPosition]
                
                // Clear any previous highlights
                highlightedNodes.forEach { $0.removeFromParent() }
                highlightedNodes.removeAll()
                
                // Reset all letter colors to white
                for row in 0..<gridHeight {
                    for col in 0..<gridWidth {
                        if !isPositionPartOfFoundWord(row: row, col: col) {
                            letters[row][col].fontColor = Constants.letterColorNormal
                            letters[row][col].setScale(Constants.scaleNormal)
                        }
                    }
                }
                
                // Highlight the first cell (including blue background)
                highlightCell(at: firstPosition.row, firstPosition.col)
                
                // Calculate the path for the selection
                let steps = max(abs(rowDiff), abs(colDiff))
                if steps > 0 {
                    let rowStep = isDiagonal ? (rowDiff / steps) : (isVertical ? (rowDiff > 0 ? 1 : -1) : 0)
                    let colStep = isDiagonal ? (colDiff / steps) : (isHorizontal ? (colDiff > 0 ? 1 : -1) : 0)
                    
                    for i in 1...steps {
                        let newRow = startRow + (rowStep * i)
                        let newCol = startCol + (colStep * i)
                        
                        // Ensure the cell is within bounds and valid
                        if newRow >= 0 && newRow < gridHeight &&
                            newCol >= 0 && newCol < gridWidth &&
                            !isPositionPartOfFoundWord(row: newRow, col: newCol) {
                            
                            selectedLetters.append((newRow, newCol))
                            highlightCell(at: newRow, newCol)
                        }
                    }
                }
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let word = getSelectedWord().uppercased() // Ensure uppercase for matching

        if words.contains(word) && !foundWords.contains(word) {
            // Word found - process it
            print("Found word: \(word)")
            foundWords.insert(word) // Mark word as found
            crossOutFromWordBank(word)
            crossOutWordInGrid() // Mark word on the grid

            // Clear selection to avoid lingering selections
            clearSelection()

            // Check if all words are found
            if foundWords.count == words.count {
                print("All words found :)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.resetGame()
                }
            }
        } else {
            // Invalid or duplicate word selection
            print("Invalid or duplicate word selection: \(word)")
            clearSelection() // Clear any invalid selection
        }
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
        
        let highlight = SKShapeNode(rectOf: CGSize(width: cellSize, height: cellSize))
        highlight.fillColor = .blue
        highlight.alpha = Constants.highlightAlpha
        
        let startX = -CGFloat(gridWidth) * cellSize / 2
        let startY = -CGFloat(gridHeight) * cellSize / 2
        
        highlight.position = CGPoint(
            x: startX + CGFloat(col) * cellSize + cellSize / 2,
            y: startY + CGFloat(row) * cellSize + cellSize / 2
        )
        
        gridNode?.addChild(highlight)
        highlightedNodes.append(highlight)
        
        // Update letter appearance
        letters[row][col].fontColor = .yellow
        letters[row][col].setScale(Constants.scaleSelected)
    }
    
    private func clearSelection() {
        // Remove all highlights
        highlightedNodes.forEach { $0.removeFromParent() }
        highlightedNodes.removeAll()
        
        // Reset the font color and scale of all letters
        for row in 0..<gridHeight {
            for col in 0..<gridWidth {
                if !isPositionPartOfFoundWord(row: row, col: col) {
                    letters[row][col].fontColor = Constants.letterColorNormal
                    letters[row][col].setScale(Constants.scaleNormal)
                }
            }
        }
        
        // Clear the selection
        selectedLetters.removeAll()
    }
    
    private func getSelectedWord() -> String {
        guard !selectedLetters.isEmpty else { return "" } // Handle empty selection case
        return selectedLetters.map { grid[$0.row][$0.col] }.map(String.init).joined()
    }
    
    private func crossOutFromWordBank(_ word: String) {
        if let label = wordBankLabels[word] {
            // Create strikethrough line
            let strikethrough = SKShapeNode()
            let path = CGMutablePath()
            
            let wordWidth = CGFloat(word.count) * (label.fontSize * 0.6)
            let extensionLength: CGFloat = label.fontSize * 0.2
            
            //move this up a bit on the y axis
            let strikethroughY: CGFloat = -label.fontSize * 0.10
            
            path.move(to: CGPoint(x: -wordWidth/2 - extensionLength, y: strikethroughY))
            path.addLine(to: CGPoint(x: wordWidth/2 + extensionLength, y: strikethroughY))
            
            strikethrough.path = path
            strikethrough.strokeColor = .red
            strikethrough.lineWidth = 5.0
            
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
        guard let firstPosition = selectedLetters.first, let lastPosition = selectedLetters.last else { return }

        // Get all positions for the found word
        let word = getSelectedWord()
        let allWordPositions = getPositionsForWord(word)

        // Create a crossout line
        let line = SKShapeNode()
        let path = CGMutablePath()

        let gridWidth = CGFloat(self.gridWidth) * cellSize
        let gridHeight = CGFloat(self.gridHeight) * cellSize
        let startX = -gridWidth / 2
        let startY = -gridHeight / 2

        // Calculate centered positions with extended length
        let direction = CGPoint(
            x: CGFloat(lastPosition.col - firstPosition.col),
            y: CGFloat(lastPosition.row - firstPosition.row)
        )
        let extensionLength: CGFloat = cellSize * 0.1

        let start = CGPoint(
            x: startX + CGFloat(firstPosition.col) * cellSize + cellSize / 2 - (direction.x * extensionLength),
            y: startY + CGFloat(firstPosition.row) * cellSize + cellSize / 2 - (direction.y * extensionLength)
        )

        let end = CGPoint(
            x: startX + CGFloat(lastPosition.col) * cellSize + cellSize / 2 + (direction.x * extensionLength),
            y: startY + CGFloat(lastPosition.row) * cellSize + cellSize / 2 + (direction.y * extensionLength)
        )

        path.move(to: start)
        path.addLine(to: end)
        line.path = path
        line.strokeColor = .red
        line.lineWidth = 3.0
        line.glowWidth = 2.0

        gridNode?.addChild(line)

        // Mark all positions of the word as gray and remove blue highlights
        for position in allWordPositions {
            letters[position.row][position.col].fontColor = .gray
            letters[position.row][position.col].setScale(Constants.scaleNormal)

            // Remove any highlights from these cells
            highlightedNodes.removeAll { highlight in
                let highlightX = startX + CGFloat(position.col) * cellSize + cellSize / 2
                let highlightY = startY + CGFloat(position.row) * cellSize + cellSize / 2
                if highlight.position.x == highlightX && highlight.position.y == highlightY {
                    highlight.removeFromParent()
                    return true
                }
                return false
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
    
    private func updateLetterAppearance(row: Int, col: Int) {
        let letter = letters[row][col]
        
        switch (isPositionPartOfFoundWord(row: row, col: col), selectedLetters.contains { $0 == (row, col) }) {
        case (true, _):  // Found word takes precedence
            letter.fontColor = .gray
            letter.setScale(Constants.scaleNormal)
        case (_, true):  // Selected but not found
            letter.fontColor = .yellow
            letter.setScale(Constants.scaleSelected)
        default:         // Neither found nor selected
            letter.fontColor = Constants.letterColorNormal
            letter.setScale(Constants.scaleNormal)
        }
    }
    
    // Add this helper function to get positions for a word
    private func getPositionsForWord(_ word: String) -> [(row: Int, col: Int)] {
        let characters = Array(word)
        for row in 0..<gridHeight {
            for col in 0..<gridWidth {
                if grid[row][col] != characters[0] { continue }  // Quick first letter check
                
                for direction in Direction.allCases {
                    let (dx, dy) = direction.offset
                    var positions: [(Int, Int)] = [(row, col)]
                    var isValid = true
                    
                    // Check remaining letters
                    for i in 1..<characters.count {
                        let newRow = row + i * dy
                        let newCol = col + i * dx
                        
                        if newRow < 0 || newRow >= gridHeight || 
                           newCol < 0 || newCol >= gridWidth || 
                           grid[newRow][newCol] != characters[i] {
                            isValid = false
                            break
                        }
                        positions.append((newRow, newCol))
                    }
                    
                    if isValid {
                        return positions
                    }
                }
            }
        }
        return []
    }
}
