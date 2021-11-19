import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_appwrite/dart_appwrite.dart';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;

void main(List<String> arguments) async {
  Map<String, String> env = Platform.environment;

  // Initialise the client SDK
  final client = Client();
  client
      .setEndpoint('http://192.168.1.13:8080/v1')
      .setProject(env['APPWRITE_FUNCTION_PROJECT_ID'])
      .setKey(env['APPWRITE_API_KEY'])
      .setSelfSigned(status: true);

  // List collections
  final response =
      (await Database(client).listCollections()).data as Map<String, dynamic>;
  final beersCollectionId = (response['collections'] as List<dynamic>)
          .map((collection) => collection as Map<String, dynamic>)
          .firstWhere((collection) => collection['name'] == 'beers')[r'$id']
      as String;

  String functionData = env['APPWRITE_FUNCTION_EVENT_DATA'].toString();
  Map<String, dynamic> jsonDoc = json.decode(functionData);

  final List<Beer> beers;
  if (jsonDoc[r'$collection'] == beersCollectionId) {
    beers = [Beer.fromJson(jsonDoc)];
  } else {
    print('🍺 Processing beers for brewery "${jsonDoc['name']}"...');
    beers = (jsonDoc['beers'] as List<dynamic>)
        .map((b) => b as Map<String, dynamic>)
        .map((b) => Beer.fromJson(b))
        .toList();
  }
  await Future.wait(
    beers.map(
      (b) => processBeer(
        client,
        b,
        beersCollectionId,
      ),
    ),
  );
}

Future<void> processBeer(
  Client client,
  Beer beer,
  String beersCollectionId,
) async {
  if (beer.hasInternalImage) {
    print(
        '🍺🥷 Beer "${beer.name}" already has an internal image set, ignoring.');
    return;
  }
  if (!beer.hasExternalImage) {
    print(
        '🍺🥷 Beer "${beer.name}" does not have an external image URL set, ignoring.');
    return;
  }

  print('🍺 Beer "${beer.name}" needs storage, will process now !');

  // Store external image to AppWrite storage
  final imageId = await copyBeerImage(client, beer);
  await updateDocumentWithInternalImage(
    client,
    beer,
    beersCollectionId,
    imageId,
  );
  print('🍺✅ Beer "${beer.name}" processed !');
}

Future<String> copyBeerImage(Client client, Beer beer) async {
  return downloadExternalImage(beer).then(
      (response) => uploadImageToAppwrite(client, beer, response.bodyBytes));
}

Future<http.Response> downloadExternalImage(Beer beer) {
  print('🍺 Beer "${beer.name}": downloading external image...');
  return http.get(Uri.parse(beer.imageExternalUrl!));
}

Future<String> uploadImageToAppwrite(Client client, Beer beer, Uint8List file) {
  print('🍺 Beer "${beer.name}": storing image to AppWrite...');
  return Storage(client).createFile(
    file: MultipartFile.fromBytes(
      'file',
      file,
      filename: 'beer-${beer.id}.jpg',
      contentType: http_parser.MediaType("image", "jpg"),
    ),
    read: ['*'],
  ).then((response) => (response.data as Map<String, dynamic>)[r'$id']);
}

Future<void> updateDocumentWithInternalImage(
  Client client,
  Beer beer,
  String collectionId,
  String imageId,
) async {
  print(
      '🍺 Beer "${beer.name}": updating document with internal image path...');
  final db = Database(client);
  await db.updateDocument(
    collectionId: collectionId,
    documentId: beer.id,
    data: {'internal_image_id': imageId},
  );
}

class Beer {
  final String id;
  final String name;
  final String? imageExternalUrl;
  final String? imageInternalId;

  Beer.fromJson(Map<String, dynamic> json)
      : id = json[r'$id'] as String,
        name = json['name'] as String,
        imageExternalUrl = json['external_image_url'] as String?,
        imageInternalId = json['internal_image_id'] as String?;

  bool get needsImageStorage => !hasInternalImage && hasExternalImage;

  bool get hasInternalImage =>
      imageInternalId != null && imageInternalId!.isNotEmpty;

  bool get hasExternalImage =>
      imageExternalUrl != null && imageExternalUrl!.isNotEmpty;
}
