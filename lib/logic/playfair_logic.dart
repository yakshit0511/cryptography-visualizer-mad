/// Playfair Cipher Logic
/// Implements 5×5 matrix-based digraph encryption/decryption
class PlayfairLogic {
  static const int matrixSize = 5;
  
  /// Generates 5×5 Playfair matrix from key
  static List<List<String>> generateMatrix(String key) {
    // Remove duplicates and non-letters, convert to uppercase, replace J with I
    String processedKey = key.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '').replaceAll('J', 'I');
    Set<String> seen = {};
    List<String> keyLetters = [];
    
    for (int i = 0; i < processedKey.length; i++) {
      String char = processedKey[i];
      if (!seen.contains(char)) {
        seen.add(char);
        keyLetters.add(char);
      }
    }
    
    // Add remaining alphabet letters (excluding J)
    for (int i = 65; i <= 90; i++) {
      String char = String.fromCharCode(i);
      if (char != 'J' && !seen.contains(char)) {
        keyLetters.add(char);
      }
    }
    
    // Create 5×5 matrix
    List<List<String>> matrix = [];
    int index = 0;
    for (int row = 0; row < matrixSize; row++) {
      List<String> rowList = [];
      for (int col = 0; col < matrixSize; col++) {
        rowList.add(keyLetters[index++]);
      }
      matrix.add(rowList);
    }
    
    return matrix;
  }
  
  /// Prepares plaintext into digraphs (pairs)
  static String preparePlaintext(String text) {
    String cleaned = text.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '').replaceAll('J', 'I');
    StringBuffer result = StringBuffer();
    
    for (int i = 0; i < cleaned.length; i += 2) {
      if (i + 1 < cleaned.length) {
        String first = cleaned[i];
        String second = cleaned[i + 1];
        
        // If both letters are same, insert X
        if (first == second) {
          result.write(first);
          result.write('X');
          i--; // Process second letter again in next iteration
        } else {
          result.write(first);
          result.write(second);
        }
      } else {
        // Odd letter at end, add X
        result.write(cleaned[i]);
        result.write('X');
      }
    }
    
    return result.toString();
  }
  
  /// Finds position of letter in matrix
  static Map<String, int> findPosition(List<List<String>> matrix, String letter) {
    for (int row = 0; row < matrixSize; row++) {
      for (int col = 0; col < matrixSize; col++) {
        if (matrix[row][col] == letter) {
          return {'row': row, 'col': col};
        }
      }
    }
    return {'row': -1, 'col': -1};
  }
  
  /// Encrypts a single digraph
  static Map<String, dynamic> encryptDigraph(String digraph, List<List<String>> matrix) {
    String first = digraph[0];
    String second = digraph[1];
    
    Map<String, int> pos1 = findPosition(matrix, first);
    Map<String, int> pos2 = findPosition(matrix, second);
    
    int row1 = pos1['row']!;
    int col1 = pos1['col']!;
    int row2 = pos2['row']!;
    int col2 = pos2['col']!;
    
    String encrypted;
    String rule;
    String explanation;
    List<String> highlightCells = [];
    
    if (row1 == row2) {
      // Same row → shift right
      int newCol1 = (col1 + 1) % matrixSize;
      int newCol2 = (col2 + 1) % matrixSize;
      encrypted = matrix[row1][newCol1] + matrix[row2][newCol2];
      rule = 'Same Row';
      explanation = 'Both letters in same row. Shift each letter 1 position RIGHT. $first→${matrix[row1][newCol1]}, $second→${matrix[row2][newCol2]}';
      highlightCells = [
        matrix[row1][col1],
        matrix[row2][col2],
        matrix[row1][newCol1],
        matrix[row2][newCol2],
      ];
    } else if (col1 == col2) {
      // Same column → shift down
      int newRow1 = (row1 + 1) % matrixSize;
      int newRow2 = (row2 + 1) % matrixSize;
      encrypted = matrix[newRow1][col1] + matrix[newRow2][col2];
      rule = 'Same Column';
      explanation = 'Both letters in same column. Shift each letter 1 position DOWN. $first→${matrix[newRow1][col1]}, $second→${matrix[newRow2][col2]}';
      highlightCells = [
        matrix[row1][col1],
        matrix[row2][col2],
        matrix[newRow1][col1],
        matrix[newRow2][col2],
      ];
    } else {
      // Rectangle → swap columns
      encrypted = matrix[row1][col2] + matrix[row2][col1];
      rule = 'Rectangle';
      explanation = 'Letters form rectangle. Swap columns: $first takes ${matrix[row1][col2]}\'s column, $second takes ${matrix[row2][col1]}\'s column';
      highlightCells = [
        matrix[row1][col1],
        matrix[row2][col2],
        matrix[row1][col2],
        matrix[row2][col1],
      ];
    }
    
    return {
      'encrypted': encrypted,
      'rule': rule,
      'explanation': explanation,
      'highlightCells': highlightCells,
      'positions': {'first': {'row': row1, 'col': col1}, 'second': {'row': row2, 'col': col2}},
    };
  }
  
  /// Decrypts a single digraph
  static Map<String, dynamic> decryptDigraph(String digraph, List<List<String>> matrix) {
    String first = digraph[0];
    String second = digraph[1];
    
    Map<String, int> pos1 = findPosition(matrix, first);
    Map<String, int> pos2 = findPosition(matrix, second);
    
    int row1 = pos1['row']!;
    int col1 = pos1['col']!;
    int row2 = pos2['row']!;
    int col2 = pos2['col']!;
    
    String decrypted;
    String rule;
    String explanation;
    List<String> highlightCells = [];
    
    if (row1 == row2) {
      // Same row → shift left
      int newCol1 = (col1 - 1 + matrixSize) % matrixSize;
      int newCol2 = (col2 - 1 + matrixSize) % matrixSize;
      decrypted = matrix[row1][newCol1] + matrix[row2][newCol2];
      rule = 'Same Row';
      explanation = 'Both letters in same row. Shift each letter 1 position LEFT. $first→${matrix[row1][newCol1]}, $second→${matrix[row2][newCol2]}';
      highlightCells = [
        matrix[row1][col1],
        matrix[row2][col2],
        matrix[row1][newCol1],
        matrix[row2][newCol2],
      ];
    } else if (col1 == col2) {
      // Same column → shift up
      int newRow1 = (row1 - 1 + matrixSize) % matrixSize;
      int newRow2 = (row2 - 1 + matrixSize) % matrixSize;
      decrypted = matrix[newRow1][col1] + matrix[newRow2][col2];
      rule = 'Same Column';
      explanation = 'Both letters in same column. Shift each letter 1 position UP. $first→${matrix[newRow1][col1]}, $second→${matrix[newRow2][col2]}';
      highlightCells = [
        matrix[row1][col1],
        matrix[row2][col2],
        matrix[newRow1][col1],
        matrix[newRow2][col2],
      ];
    } else {
      // Rectangle → swap columns (same as encryption)
      decrypted = matrix[row1][col2] + matrix[row2][col1];
      rule = 'Rectangle';
      explanation = 'Letters form rectangle. Swap columns: $first takes ${matrix[row1][col2]}\'s column, $second takes ${matrix[row2][col1]}\'s column';
      highlightCells = [
        matrix[row1][col1],
        matrix[row2][col2],
        matrix[row1][col2],
        matrix[row2][col1],
      ];
    }
    
    return {
      'decrypted': decrypted,
      'rule': rule,
      'explanation': explanation,
      'highlightCells': highlightCells,
      'positions': {'first': {'row': row1, 'col': col1}, 'second': {'row': row2, 'col': col2}},
    };
  }
  
  /// Full encryption
  static Map<String, dynamic> encrypt(String text, String key) {
    if (text.isEmpty || key.isEmpty) {
      return {
        'result': '',
        'steps': [],
        'matrix': [],
      };
    }
    
    List<List<String>> matrix = generateMatrix(key);
    String preparedText = preparePlaintext(text);
    List<Map<String, dynamic>> steps = [];
    StringBuffer result = StringBuffer();
    
    for (int i = 0; i < preparedText.length; i += 2) {
      String digraph = preparedText.substring(i, i + 2);
      Map<String, dynamic> step = encryptDigraph(digraph, matrix);
      steps.add(step);
      result.write(step['encrypted']);
    }
    
    return {
      'result': result.toString(),
      'steps': steps,
      'matrix': matrix,
    };
  }
  
  /// Full decryption
  static Map<String, dynamic> decrypt(String text, String key) {
    if (text.isEmpty || key.isEmpty) {
      return {
        'result': '',
        'steps': [],
        'matrix': [],
      };
    }
    
    List<List<String>> matrix = generateMatrix(key);
    String preparedText = preparePlaintext(text);
    List<Map<String, dynamic>> steps = [];
    StringBuffer result = StringBuffer();
    
    for (int i = 0; i < preparedText.length; i += 2) {
      String digraph = preparedText.substring(i, i + 2);
      Map<String, dynamic> step = decryptDigraph(digraph, matrix);
      steps.add(step);
      result.write(step['decrypted']);
    }
    
    return {
      'result': result.toString(),
      'steps': steps,
      'matrix': matrix,
    };
  }
}
