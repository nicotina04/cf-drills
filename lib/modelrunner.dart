import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';

class XGBoostRunner {
  late OrtSession _session;

  Future<void> init() async {
    OrtEnv.instance.init();
    final sessionOptions = OrtSessionOptions();
    final modelData = await rootBundle.load('assets/models/XGBoost.onnx');
    final bytes = modelData.buffer.asUint8List();
    _session = OrtSession.fromBuffer(bytes, sessionOptions);
  }

  Future<List<double>> predict(List<double> inputData, int featureSize) async {
    final shape = [1, featureSize];
    final inputOrt = OrtValueTensor.createTensorWithDataList(inputData, shape);
    final inputs = {'input': inputOrt};
    final runOptions = OrtRunOptions();
    final outputs = await _session.runAsync(runOptions, inputs);

    inputOrt.release();
    runOptions.release();

    final result = outputs?[0]?.value;
    outputs?.forEach((elem) => elem?.release());

    if (result is List<double>) {
      print('Prediction result: $result');
      return result;
    } else {
      throw Exception('Unexpected output type: ${result.runtimeType}');
    }
  }

  void dispose() {
    _session.release();
    OrtEnv.instance.release();
  }
}
