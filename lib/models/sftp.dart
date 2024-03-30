enum FileType {
  file,
  directory,
}

class FileInfo {
  final String name;
  final FileType type;
  final int size;
  final DateTime? modificationDate; // 可选，某些情况下可能获取不到

  FileInfo({
    required this.name,
    required this.type,
    required this.size,
    this.modificationDate,
  });
}

class OperationResult {
  final bool isSuccess;
  final String? errorMessage;

  OperationResult.success() : isSuccess = true, errorMessage = null;

  OperationResult.failure({this.errorMessage}) : isSuccess = false;

  @override
  String toString() {
    if (isSuccess) {
      return 'Operation completed successfully';
    } else {
      return 'Operation failed: $errorMessage';
    }
  }
}
