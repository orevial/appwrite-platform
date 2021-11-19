import 'dart:io';

import 'package:dart_appwrite/dart_appwrite.dart';

late Beer beer;

final breweries = <Brewery>[
  Brewery(
    name: 'Espiga',
    description:
        'The passion to create a different, natural, and local beer. And the vocation of two biologists to give life to a beer with personality and a special character. A unique high-quality beer. Crafted in the heart of Penedès. A beer to enjoy, not only of the beer itself, but also of all the process: from the first idea, the first tests, the whole elaboration… To finally drinking it in company.',
    country: 'Spain',
    beers: <Beer>[
      Beer(
        name: 'Hyperactive',
        type: 'DDH IPA',
        abv: 7.5,
        imageExternalUrl:
            'https://www.beergium.com/9512-big_default_2x/espiga-hyperactive-tdh-ipa-cans-44cl.jpg',
      ),
      Beer(
        name: 'Citrus Base',
        type: 'DDH IPA',
        abv: 5.5,
        imageExternalUrl:
            'https://www.espiga.cat/wp-content/uploads/2021/06/WEB-700x700_Citrus-Base-44cl.png',
      ),
      Beer(
        name: 'Dark Way',
        type: 'DDH IPA',
        abv: 7.5,
        imageExternalUrl:
            'https://www.espiga.cat/wp-content/uploads/2020/09/CERVESA-ESPIGA-DARK-WAY-CERVESA-ARTESANA-IMPERIAL-STOUT.png',
      ),
      Beer(
        name: 'Garage',
        type: 'IPA',
        abv: 5.5,
        imageExternalUrl:
            'https://static.unepetitemousse.fr/produits/bieres/espiga/garage-ipa.jpg',
      ),
    ],
  ),
  Brewery(
    name: 'To Øl',
    description:
        'Starting out as a home brewing project back in 2005, To Øl was permanently established in 2010 working as a gypsy brewery lending in on other breweries spare capacity for the following decade. In 2019 we took over a former food factory in the Western part of Zealand, Denmark, where we’re setting up a full-blown specially designed brewery and craft beverage hub. To Øl City is the name of the place.',
    country: 'Denmark',
    beers: <Beer>[
      Beer(
        name: 'City',
        type: 'Session IPA',
        abv: 4.5,
        imageExternalUrl:
            'https://www.dunells.com/media/xafpyetq/0018735_0.jpeg?mode=pad&width=800&height=800&saturation=0&bgcolor=ffffff',
      ),
      Beer(
        name: 'When life gives you Mango',
        type: 'Milkshake IPA',
        abv: 4.5,
        imageExternalUrl: 'https://img.saveur-biere.com/img/p/36220-55345.jpg',
      ),
    ],
  ),
  Brewery(
    name: 'Effet Papillon',
    description: '',
    country: 'France',
    beers: <Beer>[],
  ),
  Brewery(
    name: 'Piggy Brewing',
    description: '',
    country: 'France',
    beers: <Beer>[
      Beer(
        name: 'Eroica',
        type: 'DDH IPA',
        abv: 6.1,
        imageExternalUrl:
            'https://media.cdnws.com/_i/214303/1558/1356/58/the-piggy-brewing-company-eroica-44cl.png',
      ),
    ],
  ),
  Brewery(
    name: 'La Superbe',
    description: '',
    country: 'France',
    beers: <Beer>[],
  ),
  Brewery(
    name: 'Le Détour !',
    description: '',
    country: 'France',
    beers: <Beer>[],
  ),
];

void main(List<String> arguments) async {
  Map<String, String> env = Platform.environment;
  final client = Client()
    ..setEndpoint('http://192.168.1.13:8080/v1')
    ..setProject(env['APPWRITE_FUNCTION_PROJECT_ID'])
    ..setKey(env['APPWRITE_API_KEY'])
    ..setSelfSigned(status: true);
  final db = Database(client);

  // Delete collections
  print('Deleting collections...');
  final collections =
      (await db.listCollections()).data['collections'] as List<dynamic>;
  for (final collection in collections) {
    await db.deleteCollection(
      collectionId: (collection as Map<String, dynamic>)[r'$id'] as String,
    );
  }

  // Recreate collections
  print('Creating beers collection...');
  final beersCollectionId = ((await db.createCollection(
    name: 'beers',
    read: ['*'],
    write: [],
    rules: [
      {
        "type": "text",
        "key": "name",
        "label": "Name",
        "default": "",
        "array": false,
        "required": false,
        "list": []
      },
      {
        "type": "text",
        "key": "type",
        "label": "Type",
        "default": "",
        "array": false,
        "required": false,
        "list": []
      },
      {
        "type": "numeric",
        "key": "abv",
        "label": "ABV",
        "default": 0,
        "array": false,
        "required": false,
        "list": []
      },
      {
        "type": "url",
        "key": "external_image_url",
        "label": "External image URL",
        "default": "",
        "array": false,
        "required": false,
        "list": []
      },
      {
        "type": "text",
        "key": "internal_image_id",
        "label": "Internal image ID",
        "default": "",
        "array": false,
        "required": false,
        "list": []
      }
    ],
  ))
      .data as Map<String, dynamic>)[r'$id'] as String;

  print('Creating breweries collection...');
  final breweriesCollectionId = ((await db.createCollection(
    name: 'breweries',
    read: ['*'],
    write: [],
    rules: [
      {
        "type": "text",
        "key": "name",
        "label": "Name",
        "default": "",
        "array": false,
        "required": false,
        "list": []
      },
      {
        "type": "text",
        "key": "country",
        "label": "Country",
        "default": "",
        "array": false,
        "required": false,
        "list": []
      },
      {
        "type": "text",
        "key": "description",
        "label": "Description",
        "default": "",
        "array": false,
        "required": false,
        "list": []
      },
      {
        "type": "document",
        "key": "beers",
        "label": "Beers",
        "default": "",
        "array": true,
        "required": false,
        "list": [beersCollectionId]
      }
    ],
  ))
      .data as Map<String, dynamic>)[r'$id'] as String;

  // Populate database
  print('Populating database...');
  final futures = breweries.map(
    (brewery) {
      return db
          .createDocument(
            collectionId: breweriesCollectionId,
            data: brewery.toJson(),
            read: ['*'],
            write: [],
          )
          .then((response) => response.data as Map<String, dynamic>)
          .then((response) => response[r'$id'] as String)
          .then(
            (breweryDocId) async {
              for (final beer in brewery.beers) {
                print('Pushing doc for beer ${beer.name}...');
                await db.createDocument(
                  collectionId: beersCollectionId,
                  data: beer.toJson(),
                  read: ['*'],
                  write: [],
                  parentDocument: breweryDocId,
                  parentProperty: 'beers',
                  parentPropertyType: 'prepend',
                );
              }
              return Future.wait([]);
            },
          );
    },
  );
  await Future.wait(futures);

  print('Done with success !');
}

class Brewery {
  final String name;
  final String description;
  final String country;
  final List<Beer> beers;

  Brewery({
    required this.name,
    required this.description,
    required this.country,
    required this.beers,
  });

  Map<String, dynamic> toJson() => {
        "name": name,
        "description": description,
        "country": country,
      };
}

class Beer {
  final String name;
  final String type;
  final double abv;
  final String imageExternalUrl;

  Beer({
    required this.name,
    required this.type,
    required this.abv,
    required this.imageExternalUrl,
  });

  Map<String, dynamic> toJson() => {
        "name": name,
        "type": type,
        "abv": abv,
        "external_image_url": imageExternalUrl,
      };
}
