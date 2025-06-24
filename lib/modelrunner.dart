import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'dart:typed_data';

class XGBoostRunner {
  static final XGBoostRunner _instance = XGBoostRunner._internal();
  late OrtSession _session;

  factory XGBoostRunner() {
    return _instance;
  }

  XGBoostRunner._internal();

  Future<void> init() async {
    OrtEnv.instance.init();
    final sessionOptions = OrtSessionOptions();
    final modelData = await rootBundle.load('assets/models/XGBoost.onnx');
    final bytes = modelData.buffer.asUint8List();
    _session = OrtSession.fromBuffer(bytes, sessionOptions);
  }

  Future<double> predict(List<double> inputData, int featureSize) async {
    final shape = [1, featureSize];
    final floatInput = Float32List.fromList(inputData);

    final inputOrt = OrtValueTensor.createTensorWithDataList(floatInput, shape);
    final inputs = {'input': inputOrt};
    final runOptions = OrtRunOptions();
    final outputs = await _session.runAsync(runOptions, inputs);

    inputOrt.release();
    runOptions.release();

    // shape of outputs -> [[class], [[probability]]]

    final proba = outputs?[1]?.value as List<dynamic>;
    final result = proba[0][1] as double;

    outputs?.forEach((elem) => elem?.release());

    return result;
  }

  void dispose() {
    _session.release();
    OrtEnv.instance.release();
  }
}
