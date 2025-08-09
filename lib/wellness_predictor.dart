import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';

class WellnessPredictor {
  late final Interpreter _interpreter;
  late final Map<String, dynamic> _meta;
  late final List<String> _featureOrder;
  static final WellnessPredictor _instance = WellnessPredictor._internal();
  bool _isInitialized = false;

  // Factory constructor for singleton pattern
  factory WellnessPredictor() {
    return _instance;
  }

  // Private constructor
  WellnessPredictor._internal();

  Future<void> loadModel() async {
    if (_isInitialized) return;
    
    try {
      _interpreter = await Interpreter.fromAsset('assets/wellness_grader.tflite');
      final metaStr = await rootBundle.loadString('assets/wellness_meta.json');
      _meta = jsonDecode(metaStr) as Map<String, dynamic>;
      _featureOrder = List<String>.from(_meta['feature_order'] as List);
      _isInitialized = true;
    } catch (e) {
      print('Error loading wellness model: $e');
      rethrow;
    }
  }

  double score(Map<String, dynamic> inputs) {
    if (!_isInitialized) {
      throw StateError('WellnessPredictor not initialized. Call loadModel() first.');
    }

    // Validate all required features are present
    final missingFeatures = _featureOrder.where(
      (key) => !inputs.containsKey(key) && inputs[key] == null).toList();
    
    if (missingFeatures.isNotEmpty) {
      print('Warning: Missing features: ${missingFeatures.join(', ')}');
    }

    // Create input vector
    final vector = Float32List(_featureOrder.length);
    for (var i = 0; i < _featureOrder.length; i++) {
      final key = _featureOrder[i];
      vector[i] = _encode(key, inputs[key]);
    }

    final inputBatch = [vector];
    final outputBatch = List.generate(1, (_) => List<double>.filled(1, 0.0));

    try {
      _interpreter.run(inputBatch, outputBatch);
      final raw = outputBatch[0][0];        
      return (raw * 100).clamp(0, 100); 
    } catch (e) {
      print('Error running model inference: $e');
      return 0.0; // Return safe default
    }    
  }

  double _encode(String key, dynamic v) {
    if (v == null) return -1;

    try {
      if (v is Iterable) return v.length.toDouble();
      if (v is num) return v.toDouble();

      if (v is String) {
        // Handle empty strings
        if (v.isEmpty) return -1;

        // Categorical mapping
        final categoricalMappings = _meta['categorical_mapping'] as Map<String, dynamic>?;
        if (categoricalMappings != null && categoricalMappings.containsKey(key)) {
          final catMap = Map<String, int>.from(categoricalMappings[key] as Map);
          final result = catMap[v]?.toDouble();
          if (result != null) return result;
          print('Warning: Unknown categorical value "$v" for feature "$key"');
          return -1;
        }

        // Time column normalization
        final timeColumns = List<String>.from(_meta['time_columns_normalized'] as List? ?? []);
        if (timeColumns.contains(key)) {
          final parts = v.split(':');
          if (parts.length == 2) {
            try {
              final mins = int.parse(parts[0]) * 60 + int.parse(parts[1]);
              return mins / 1440.0;
            } catch (e) {
              print('Error parsing time value "$v" for feature "$key": $e');
              return -1;
            }
          }
        }
      }

      print('Warning: Unrecognized format for feature "$key": $v');
      return -1;
    } catch (e) {
      print('Error encoding feature "$key" with value "$v": $e');
      return -1;
    }
  }

  void close() {
    if (_isInitialized) {
      _interpreter.close();
      _isInitialized = false;
    }
  }
}