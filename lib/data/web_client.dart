import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:invoiceninja_flutter/.env.dart';
import 'package:http/http.dart' as http;
import 'package:invoiceninja_flutter/constants.dart';
import 'package:invoiceninja_flutter/utils/strings.dart';
import 'package:path/path.dart';
import 'package:version/version.dart';

class WebClient {
  const WebClient();

  Future<dynamic> get(
    String url,
    String token, {
    bool rawResponse = false,
  }) async {
    if (Config.DEMO_MODE) {
      throw 'Server requests are not supported in the demo';
    }

    if (!url.contains('?')) {
      url += '?';
    }
    print('GET: $url');

    if (url.contains('invoiceninja.com')) {
      url += '&per_page=$kMaxRecordsPerApiPage';
    } else {
      url += '&per_page=999999';
    }

    final http.Response response = await http.Client().get(
      url,
      headers: _getHeaders(url, token),
    );

    if (rawResponse) {
      return response;
    }

    _checkResponse(response);

    final dynamic jsonResponse = json.decode(response.body);

    //debugPrint(response.body, wrapWidth: 1000);

    return jsonResponse;
  }

  Future<dynamic> post(
    String url,
    String token, {
    dynamic data,
    String filePath,
    String fileIndex,
    String secret,
    String password,
    bool rawResponse = false,
  }) async {
    if (Config.DEMO_MODE) {
      throw 'Server requests are not supported in the demo';
    }

    if (!url.contains('?')) {
      url += '?';
    }

    print('POST: $url');
    if (!kReleaseMode) {
      printWrapped('Data: $data');
    }
    http.Response response;

    if (filePath != null) {
      response = await _uploadFile(url, token, filePath,
          fileIndex: fileIndex, data: data);
    } else {
      response = await http.Client()
          .post(url,
              body: data,
              headers:
                  _getHeaders(url, token, secret: secret, password: password))
          .timeout(const Duration(seconds: kMaxPostSeconds));
    }

    if (rawResponse) {
      return response;
    }

    _checkResponse(response);

    return json.decode(response.body);
  }

  Future<dynamic> put(
    String url,
    String token, {
    dynamic data,
    String filePath,
    String fileIndex = 'file',
    String password,
  }) async {
    if (Config.DEMO_MODE) {
      throw 'Server requests are not supported in the demo';
    }

    if (!url.contains('?')) {
      url += '?';
    }

    print('PUT: $url');
    if (!kReleaseMode) {
      printWrapped('Data: $data');
    }
    http.Response response;

    if (filePath != null) {
      response = await _uploadFile(url, token, filePath,
          fileIndex: fileIndex, data: data, method: 'PUT');
    } else {
      response = await http.Client().put(
        url,
        body: data,
        headers: _getHeaders(url, token, password: password),
      );
    }

    _checkResponse(response);

    return json.decode(response.body);
  }

  Future<dynamic> delete(String url, String token, {String password}) async {
    if (Config.DEMO_MODE) {
      throw 'Server requests are not supported in the demo';
    }

    if (!url.contains('?')) {
      url += '?';
    }

    print('Delete: $url');

    final http.Response response = await http.Client().delete(
      url,
      headers: _getHeaders(url, token, password: password),
    );

    _checkResponse(response);

    return json.decode(response.body);
  }
}

Map<String, String> _getHeaders(String url, String token,
    {String secret, String password}) {
  if (url.startsWith(Constants.hostedApiUrl)) {
    secret = Config.API_SECRET;
  }
  final headers = {
    'X-API-SECRET': secret,
    'X-Requested-With': 'XMLHttpRequest',
    'Content-Type': 'application/json',
  };

  if (token != null && token.isNotEmpty) {
    headers['X-API-Token'] = token;
  }

  if (password != null && password.isNotEmpty) {
    headers['X-API-PASSWORD'] = password;
  }

  return headers;
}

void _checkResponse(http.Response response) {
  /*
  debugPrint(
      'response: ${response.statusCode} ${response.body.substring(0, min(response.body.length, 30000))}',
      wrapWidth: 1000);
  debugPrint('response: ${response.statusCode} ${response.body}');
   */
  if (!kReleaseMode) {
    printWrapped('${response.statusCode} ${response.body}');
  }
  print('headers: ${response.headers}');

  final serverVersion = response.headers['x-app-version'];
  final minClientVersion = response.headers['x-minimum-client-version'];

  if (serverVersion == null) {
    throw 'Error: please check that Invoice Ninja v5 is installed on the server';
  } else {
    if (Version.parse(kClientVersion) < Version.parse(minClientVersion)) {
      throw 'Error: client not supported, please update to the latest version [v$kClientVersion < v$minClientVersion]';
    } else if (Version.parse(serverVersion) <
        Version.parse(kMinServerVersion)) {
      throw 'Error: server not supported, please update to the latest version [v$serverVersion < v$kMinServerVersion]';
    } else if (response.statusCode >= 400) {
      print('==== FAILED ====');
      throw _parseError(response.statusCode, response.body);
    }
  }
}

String _parseError(int code, String response) {
  dynamic message = response;

  if (response.contains('DOCTYPE html')) {
    return '$code: An error occurred';
  }

  try {
    final dynamic jsonResponse = json.decode(response);

    message = jsonResponse['message'] ?? jsonResponse;

    if (jsonResponse['errors'] != null &&
        (jsonResponse['errors'] as Map).isNotEmpty) {
      message += '\n';
      try {
        jsonResponse['errors'].forEach((String field, dynamic errors) {
          (errors as List<dynamic>)
              .forEach((dynamic error) => message += '\n • $error');
        });
      } catch (error) {
        print('Failed to parse error: $error');
      }
    }
  } catch (error) {
    print('Failed to parse error: $error');
  }

  return '$code: $message';
}

Future<http.Response> _uploadFile(String url, String token, String filePath,
    {String method = 'POST', String fileIndex = 'file', dynamic data}) async {
  dynamic multipartFile;

  if (filePath.startsWith('data:')) {
    final parts = filePath.split(',');
    final prefix = parts[0];
    final startIndex = prefix.indexOf('/') + 1;
    final endIndex = prefix.indexOf(';');
    final fileExt = prefix.substring(startIndex, endIndex);
    final bytes = base64.decode(parts[1]);
    multipartFile = http.MultipartFile.fromBytes(fileIndex, bytes,
        filename: 'file.$fileExt');
  } else {
    final file = File(filePath);
    final stream = http.ByteStream(file.openRead().cast());
    final length = await file.length();
    multipartFile = http.MultipartFile(fileIndex, stream, length,
        filename: basename(file.path));
  }

  final request = http.MultipartRequest(method, Uri.parse(url))
    ..fields.addAll(data ?? {})
    ..headers.addAll(_getHeaders(url, token))
    ..files.add(multipartFile);

  return await http.Response.fromStream(await request.send())
      .timeout(const Duration(minutes: 10));
}
