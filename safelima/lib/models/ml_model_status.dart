class MlModelStatus {
  final String source;
  final bool loaded;
  final bool batchLoaded;
  final bool onlineLoaded;
  final Map<String, String> errors;
  final String gcsBucket;
  final String batchModelBlob;
  final String onlineModelBlob;
  final String localDir;
  final String batchModelPath;
  final String onlineModelPath;

  const MlModelStatus({
    required this.source,
    required this.loaded,
    required this.batchLoaded,
    required this.onlineLoaded,
    required this.errors,
    required this.gcsBucket,
    required this.batchModelBlob,
    required this.onlineModelBlob,
    required this.localDir,
    required this.batchModelPath,
    required this.onlineModelPath,
  });

  factory MlModelStatus.fromJson(Map<String, dynamic> json) {
    final rawErrors = json['errors'];
    final parsedErrors = <String, String>{};

    if (rawErrors is Map) {
      rawErrors.forEach((key, value) {
        parsedErrors[key.toString()] = value.toString();
      });
    }

    return MlModelStatus(
      source: json['source']?.toString() ?? '',
      loaded: json['loaded'] == true,
      batchLoaded: json['batch_loaded'] == true,
      onlineLoaded: json['online_loaded'] == true,
      errors: parsedErrors,
      gcsBucket: json['gcs_bucket']?.toString() ?? '',
      batchModelBlob: json['batch_model_blob']?.toString() ?? '',
      onlineModelBlob: json['online_model_blob']?.toString() ?? '',
      localDir: json['local_dir']?.toString() ?? '',
      batchModelPath: json['batch_model_path']?.toString() ?? '',
      onlineModelPath: json['online_model_path']?.toString() ?? '',
    );
  }
}
