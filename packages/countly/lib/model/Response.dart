class Response {
  final String data;
  final bool success;

  Response({required this.data, required this.success});

  @override
  String toString() {
    return 'Response{data: $data, success: $success}';
  }
}
