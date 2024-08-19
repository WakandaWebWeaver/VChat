import 'dart:convert';
import 'package:http/http.dart' as http;


class SpotifyService {
  final String _clientId = "6625bc24e6e94f34bbb3e0a2cb919950";
  final String _clientSecret = "41b7dd55519a4f1c93e32227a0d752b7";
  String? _accessToken;

  SpotifyService() {
    _getAccessToken();
  }

  Future<void> _getAccessToken() async {
    final response = await http.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {
        'Authorization': 'Basic ${base64Encode(utf8.encode('$_clientId:$_clientSecret'))}',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'client_credentials',
      },
    );

    final data = json.decode(response.body);
    _accessToken = data['access_token'];
  }

  Future<Map<String, dynamic>> searchSong(String query) async {
    if (_accessToken == null) {
      await _getAccessToken();
    }

    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/search?q=$query&type=track'),
      headers: {
        'Authorization': 'Bearer $_accessToken!',
      },
    );

    final data = json.decode(response.body);
    final track = data['tracks']['items'][0];

    return {
      'name': track['name'],
      'singer': track['artists'][0]['name'],
      'albumArt': track['album']['images'][0]['url'],
      'uri': track['uri'],
    };
  }
}
