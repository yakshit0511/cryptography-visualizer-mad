/// Caesar Cipher Logic
/// Handles encryption and decryption using shift substitution
class CaesarLogic {
  /// Encrypts text using Caesar cipher with given shift
  static String encrypt(String text, int shift) {
    if (text.isEmpty) return '';
    
    StringBuffer result = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      String char = text[i];
      
      if (char.toUpperCase() != char.toLowerCase()) {
        // It's a letter
        bool isUpper = char == char.toUpperCase();
        int base = isUpper ? 65 : 97; // ASCII: A=65, a=97
        int charCode = char.codeUnitAt(0);
        int shifted = ((charCode - base + shift) % 26 + 26) % 26;
        result.write(String.fromCharCode(base + shifted));
      } else {
        // Not a letter, keep as is
        result.write(char);
      }
    }
    
    return result.toString();
  }
  
  /// Decrypts text using Caesar cipher with given shift
  static String decrypt(String text, int shift) {
    return encrypt(text, -shift);
  }
  
  /// Gets transformation for a single character
  static Map<String, dynamic> getCharTransformation(String char, int shift, bool isEncrypt) {
    if (char.toUpperCase() == char.toLowerCase()) {
      // Not a letter
      return {
        'original': char,
        'transformed': char,
        'isLetter': false,
        'explanation': 'Non-letter character',
      };
    }
    
    bool isUpper = char == char.toUpperCase();
    int base = isUpper ? 65 : 97;
    int charCode = char.codeUnitAt(0);
    int actualShift = isEncrypt ? shift : -shift;
    int shifted = ((charCode - base + actualShift) % 26 + 26) % 26;
    String transformed = String.fromCharCode(base + shifted);
    
    return {
      'original': char,
      'transformed': transformed,
      'isLetter': true,
      'shift': actualShift,
      'explanation': '${char} → ${transformed} (shift ${actualShift > 0 ? '+' : ''}${actualShift})',
    };
  }
  
  /// Gets step-by-step transformation for entire text
  static List<Map<String, dynamic>> getStepByStepTransformation(String text, int shift, bool isEncrypt) {
    List<Map<String, dynamic>> steps = [];
    
    for (int i = 0; i < text.length; i++) {
      steps.add(getCharTransformation(text[i], shift, isEncrypt));
    }
    
    return steps;
  }
}
