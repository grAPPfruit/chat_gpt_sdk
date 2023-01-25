import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chat_gpt_sdk/src/api/endpoint.dart';
import 'package:chat_gpt_sdk/src/constants.dart';
import 'package:chat_gpt_sdk/src/model/ai_model.dart';
import 'package:chat_gpt_sdk/src/model/complete_req.dart';
import 'package:chat_gpt_sdk/src/model/complete_res.dart';
import 'package:chat_gpt_sdk/src/model/engine_model.dart';
import 'package:chat_gpt_sdk/src/model/generate_image_req.dart';
import 'package:chat_gpt_sdk/src/model/generate_img_res.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api/auth_header_interceptor.dart';

class ChatGPT {
  ChatGPT(this.dio, this.prefs, this.token) {
    if (dio.options.baseUrl.isEmpty) {
      dio.options.baseUrl = kBaseUrl;
    }
    if (dio.options.connectTimeout == 0) {
      dio.options.connectTimeout = 5000;
    }
    if (dio.options.sendTimeout == 0) {
      dio.options.sendTimeout = 5000;
    }
    if (dio.options.receiveTimeout == 0) {
      dio.options.receiveTimeout = 5000;
    }

    dio.interceptors.add(AuthHeaderInterceptor(prefs));
    setToken(token);
  }

  final Dio dio;
  final SharedPreferences prefs;
  final String token;

  /// set new token
  Future<void> setToken(String token) async {
    await prefs.setString(kTokenKey, token);
  }

  ///### About Method
  /// - Answer questions based on existing knowledge.
  /// - Create code to call the Stripe API using natural language.
  /// - Classify items into categories via example.
  /// - look more
  /// https://beta.openai.com/examples
  Future<CompleteRes?> onCompleteText({required CompleteReq request}) async {
    final res = await dio.post("$kBaseUrl$kCompletion",
        data: json.encode(request.toJson()));
    if (res.statusCode != HttpStatus.ok) {
      // print(
      //     "complete error: ${res?.statusMessage} code: ${res?.statusCode} data: ${res?.data}");
    }
    return res.data == null ? null : CompleteRes.fromJson(res.data);
  }

  ///### About Method
  /// - Answer questions based on existing knowledge.
  /// - Create code to call the Stripe API using natural language.
  /// - Classify items into categories via example.
  /// - look more
  /// https://beta.openai.com/examples
  Stream<CompleteRes?> onCompleteStream({required CompleteReq request}) {
    _completeText(request: request);
    return _completeControl.stream;
  }

  final _completeControl = StreamController<CompleteRes>.broadcast();
  void _completeText({required CompleteReq request}) {
    dio
        .post("$kBaseUrl$kCompletion", data: json.encode(request.toJson()))
        .asStream()
        .listen((response) {
      if (response.statusCode != HttpStatus.ok) {
        _completeControl
          ..sink
          ..addError(
              "complete error: ${response.statusMessage} code: ${response.statusCode} data: ${response.data}");
      } else {
        _completeControl
          ..sink
          ..add(CompleteRes.fromJson(response.data));
      }
    });
  }

  ///### close complete stream
  void close() {
    _completeControl.close();
  }

  ///find all list model ai
  Future<AiModel> listModel() async {
    final res = await dio.get("$kBaseUrl$kModelList");
    if (res.statusCode != HttpStatus.ok) {}
    return AiModel.fromJson(res.data);
  }

  /// find all list engine ai
  Future<EngineModel> listEngine() async {
    final res = await dio.get("$kBaseUrl$kEngineList");
    if (res.statusCode != HttpStatus.ok) {
      if (kDebugMode) {
        print(
            "error: ${res.statusMessage} code: ${res.statusCode} data: ${res.data}");
      }
    }
    return EngineModel.fromJson(res.data);
  }

  ///generate image with prompt
  Stream<GenerateImgRes> generateImageStream(GenerateImage request) {
    _generateImage(request);
    return _genImgController.stream;
  }

  final _genImgController = StreamController<GenerateImgRes>.broadcast();
  void _generateImage(GenerateImage request) {
    dio
        .post("$kBaseUrl$kGenerateImage", data: json.encode(request.toJson()))
        .asStream()
        .listen((response) {
      if (response.statusCode != HttpStatus.ok) {
        _genImgController
          ..sink
          ..addError(
              "generate image error: ${response.statusMessage} code: ${response.statusCode} data: ${response.data}");
      } else {
        _genImgController
          ..sink
          ..add(GenerateImgRes.fromJson(response.data));
      }
    });
  }

  void genImgClose() {
    _genImgController.close();
  }

  ///generate image with prompt
  Future<GenerateImgRes?> generateImage(GenerateImage request) async {
    final response = await dio.post(
      "$kBaseUrl$kGenerateImage",
      data: json.encode(request.toJson()),
    );

    return response.data != null
        ? GenerateImgRes.fromJson(response.data)
        : null;
  }
}
