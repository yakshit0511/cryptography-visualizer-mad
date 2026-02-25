class MatrixInverseDetails {
  final int determinant;
  final int determinantMod26;
  final int determinantInverseMod26;
  final List<List<int>> cofactorMatrix;
  final List<List<int>> adjugateMatrix;
  final List<List<int>> inverseMatrix;

  const MatrixInverseDetails({
    required this.determinant,
    required this.determinantMod26,
    required this.determinantInverseMod26,
    required this.cofactorMatrix,
    required this.adjugateMatrix,
    required this.inverseMatrix,
  });
}

class HillStepData {
  final List<List<int>> keyMatrix;
  final List<int> messageVector;
  final List<List<String>> multiplicationTerms;
  final List<int> rawProducts;
  final List<int> modResults;
  final List<int> resultVector;
  final List<String> inputLetters;
  final List<String> resultLetters;
  final MatrixInverseDetails? inverseDetails;

  const HillStepData({
    required this.keyMatrix,
    required this.messageVector,
    required this.multiplicationTerms,
    required this.rawProducts,
    required this.modResults,
    required this.resultVector,
    required this.inputLetters,
    required this.resultLetters,
    this.inverseDetails,
  });
}

class HillCipherResult {
  final String normalizedInput;
  final String paddedInput;
  final String normalizedKey;
  final String output;
  final HillStepData steps;

  const HillCipherResult({
    required this.normalizedInput,
    required this.paddedInput,
    required this.normalizedKey,
    required this.output,
    required this.steps,
  });
}

class HillCipherLogic {
  static const int _mod = 26;

  static String sanitizeAZ(String value) {
    final upper = value.toUpperCase();
    final onlyLetters = upper.replaceAll(RegExp(r'[^A-Z]'), '');
    return onlyLetters;
  }

  static String padToThree(String value) {
    if (value.length >= 3) {
      return value.substring(0, 3);
    }
    return value.padRight(3, 'X');
  }

  static String? validatePlaintext(String value) {
    if (value.trim().isEmpty) {
      return 'Plaintext is required.';
    }

    if (!RegExp(r'^[a-zA-Z]+$').hasMatch(value.trim())) {
      return 'Plaintext must contain only letters A-Z.';
    }

    if (sanitizeAZ(value).length > 3) {
      return 'Use at most 3 letters for this visualization block.';
    }

    return null;
  }

  static String? validateKey(String value) {
    final key = sanitizeAZ(value);

    if (key.length != 9) {
      return 'Key must be exactly 9 letters (A-Z).';
    }

    final matrix = keyToMatrix(key);
    final det = determinant3x3(matrix);
    final detMod = positiveMod(det, _mod);

    if (_modInverse(detMod, _mod) == null) {
      return 'Invalid key: determinant has no modular inverse mod 26.';
    }

    return null;
  }

  static HillCipherResult encrypt({
    required String plaintext,
    required String key,
  }) {
    final normalizedInput = sanitizeAZ(plaintext);
    final normalizedKey = sanitizeAZ(key);

    final inputError = validatePlaintext(normalizedInput);
    if (inputError != null) {
      throw FormatException(inputError);
    }

    final keyError = validateKey(normalizedKey);
    if (keyError != null) {
      throw FormatException(keyError);
    }

    final padded = padToThree(normalizedInput);
    final keyMatrix = keyToMatrix(normalizedKey);
    final messageVector = textToVector(padded);

    final multiplication = _multiplyMatrixVectorDetailed(
      keyMatrix,
      messageVector,
    );
    final resultText = vectorToText(multiplication.modResults);

    return HillCipherResult(
      normalizedInput: normalizedInput,
      paddedInput: padded,
      normalizedKey: normalizedKey,
      output: resultText,
      steps: HillStepData(
        keyMatrix: keyMatrix,
        messageVector: messageVector,
        multiplicationTerms: multiplication.terms,
        rawProducts: multiplication.raw,
        modResults: multiplication.modResults,
        resultVector: multiplication.modResults,
        inputLetters: padded.split(''),
        resultLetters: resultText.split(''),
      ),
    );
  }

  static HillCipherResult decrypt({
    required String ciphertext,
    required String key,
  }) {
    final normalizedInput = sanitizeAZ(ciphertext);
    final normalizedKey = sanitizeAZ(key);

    final inputError = validatePlaintext(normalizedInput);
    if (inputError != null) {
      throw FormatException(inputError.replaceFirst('Plaintext', 'Ciphertext'));
    }

    final keyError = validateKey(normalizedKey);
    if (keyError != null) {
      throw FormatException(keyError);
    }

    final padded = padToThree(normalizedInput);
    final keyMatrix = keyToMatrix(normalizedKey);
    final inverse = inverseMatrixMod26(keyMatrix);
    if (inverse == null) {
      throw const FormatException('Could not compute inverse matrix mod 26.');
    }

    final cipherVector = textToVector(padded);
    final multiplication = _multiplyMatrixVectorDetailed(
      inverse.inverseMatrix,
      cipherVector,
    );
    final resultText = vectorToText(multiplication.modResults);

    return HillCipherResult(
      normalizedInput: normalizedInput,
      paddedInput: padded,
      normalizedKey: normalizedKey,
      output: resultText,
      steps: HillStepData(
        keyMatrix: keyMatrix,
        messageVector: cipherVector,
        multiplicationTerms: multiplication.terms,
        rawProducts: multiplication.raw,
        modResults: multiplication.modResults,
        resultVector: multiplication.modResults,
        inputLetters: padded.split(''),
        resultLetters: resultText.split(''),
        inverseDetails: inverse,
      ),
    );
  }

  static List<List<int>> keyToMatrix(String key) {
    final values = key.split('').map(letterToNumber).toList();
    return [values.sublist(0, 3), values.sublist(3, 6), values.sublist(6, 9)];
  }

  static List<int> textToVector(String text) {
    return text.split('').map(letterToNumber).toList();
  }

  static String vectorToText(List<int> vector) {
    return vector.map(numberToLetter).join();
  }

  static int letterToNumber(String letter) {
    return letter.toUpperCase().codeUnitAt(0) - 65;
  }

  static String numberToLetter(int value) {
    final normalized = positiveMod(value, _mod);
    return String.fromCharCode(normalized + 65);
  }

  static int determinant3x3(List<List<int>> matrix) {
    final a = matrix[0][0];
    final b = matrix[0][1];
    final c = matrix[0][2];
    final d = matrix[1][0];
    final e = matrix[1][1];
    final f = matrix[1][2];
    final g = matrix[2][0];
    final h = matrix[2][1];
    final i = matrix[2][2];

    return a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g);
  }

  static MatrixInverseDetails? inverseMatrixMod26(List<List<int>> matrix) {
    final determinant = determinant3x3(matrix);
    final determinantMod26 = positiveMod(determinant, _mod);
    final detInverse = _modInverse(determinantMod26, _mod);

    if (detInverse == null) {
      return null;
    }

    final cofactors = _cofactorMatrix3x3(matrix);
    final adjugate = _transpose3x3(cofactors);

    final inverse = List.generate(3, (row) {
      return List.generate(3, (col) {
        final value = detInverse * adjugate[row][col];
        return positiveMod(value, _mod);
      });
    });

    return MatrixInverseDetails(
      determinant: determinant,
      determinantMod26: determinantMod26,
      determinantInverseMod26: detInverse,
      cofactorMatrix: cofactors,
      adjugateMatrix: adjugate,
      inverseMatrix: inverse,
    );
  }

  static int positiveMod(int value, int mod) {
    return ((value % mod) + mod) % mod;
  }

  static _MultiplicationResult _multiplyMatrixVectorDetailed(
    List<List<int>> matrix,
    List<int> vector,
  ) {
    final raw = <int>[];
    final modResults = <int>[];
    final terms = <List<String>>[];

    for (int row = 0; row < 3; row++) {
      final rowTerms = <String>[];
      int sum = 0;
      for (int col = 0; col < 3; col++) {
        final term = matrix[row][col] * vector[col];
        sum += term;
        rowTerms.add('${matrix[row][col]}×${vector[col]}');
      }
      raw.add(sum);
      modResults.add(positiveMod(sum, _mod));
      terms.add(rowTerms);
    }

    return _MultiplicationResult(
      raw: raw,
      modResults: modResults,
      terms: terms,
    );
  }

  static List<List<int>> _cofactorMatrix3x3(List<List<int>> matrix) {
    final cofactors = List.generate(3, (_) => List.filled(3, 0));

    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        final minor = _minor2x2(matrix, row, col);
        final detMinor = minor[0][0] * minor[1][1] - minor[0][1] * minor[1][0];
        final sign = ((row + col) % 2 == 0) ? 1 : -1;
        cofactors[row][col] = sign * detMinor;
      }
    }

    return cofactors;
  }

  static List<List<int>> _minor2x2(
    List<List<int>> matrix,
    int skipRow,
    int skipCol,
  ) {
    final minor = <List<int>>[];

    for (int row = 0; row < 3; row++) {
      if (row == skipRow) continue;
      final minorRow = <int>[];
      for (int col = 0; col < 3; col++) {
        if (col == skipCol) continue;
        minorRow.add(matrix[row][col]);
      }
      minor.add(minorRow);
    }

    return minor;
  }

  static List<List<int>> _transpose3x3(List<List<int>> matrix) {
    return List.generate(3, (row) {
      return List.generate(3, (col) => matrix[col][row]);
    });
  }

  static int? _modInverse(int value, int mod) {
    value = positiveMod(value, mod);
    for (int candidate = 1; candidate < mod; candidate++) {
      if ((value * candidate) % mod == 1) {
        return candidate;
      }
    }
    return null;
  }
}

class _MultiplicationResult {
  final List<int> raw;
  final List<int> modResults;
  final List<List<String>> terms;

  _MultiplicationResult({
    required this.raw,
    required this.modResults,
    required this.terms,
  });
}
