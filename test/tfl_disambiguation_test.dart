import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tube_london/services/tfl_service.dart';

/// Verifies that planJourney survives TfL's HTTP 300 "disambiguation" response
/// (the historical cause of "Journey planning failed") by resolving the top
/// candidate's coordinates and retrying.
void main() {
  test('planJourney resolves HTTP 300 disambiguation then retries', () async {
    final dio = Dio();
    var calls = 0;
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      calls++;
      if (options.path.contains('/to/Waterloo')) {
        // First call: ambiguous destination -> 300 with candidates.
        handler.resolve(Response(
          requestOptions: options,
          statusCode: 300,
          data: {
            'toLocationDisambiguation': {
              'disambiguationOptions': [
                {
                  'matchQuality': 900,
                  'place': {'lat': 51.5035, 'lon': -0.1132, 'commonName': 'Waterloo'}
                }
              ]
            }
          },
        ));
      } else {
        // Retry with resolved coordinates -> real journeys.
        handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'journeys': [
              {
                'duration': 22,
                'legs': [
                  {
                    'duration': 22,
                    'mode': {'name': 'tube'},
                    'departurePoint': {'commonName': 'A'},
                    'arrivalPoint': {'commonName': 'Waterloo'},
                  }
                ]
              }
            ]
          },
        ));
      }
    }));

    final svc = TflService(dio: dio);
    final journeys = await svc.planJourney(from: '51.51,-0.10', to: 'Waterloo');

    expect(calls, 2, reason: 'should retry once after disambiguation');
    expect(journeys, hasLength(1));
    expect(journeys.first.durationMinutes, 22);
  });

  test('planJourney returns empty (not error) when no journeys and no candidates', () async {
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {'journeys': <dynamic>[]},
      ));
    }));
    final svc = TflService(dio: dio);
    expect(await svc.planJourney(from: 'a', to: 'b'), isEmpty);
  });
}
