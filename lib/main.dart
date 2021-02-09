import 'package:charts_flutter/flutter.dart' as charts;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:statsfspot/services/advertservice.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:auto_size_text/auto_size_text.dart';
import 'dart:math';
import 'package:seekbar/seekbar.dart';

void main() {
  Paint.enableDithering = true;
  runApp(MyApp());
}

class recent {
  final String id;
  final String url;
  final String name;
  final String artist;
  final String playedat;
  final String imagelink;
  final num duration;
  recent(this.id, this.url, this.name, this.playedat, this.imagelink,
      this.duration, this.artist);
}

class recomtrack {
  final String id, url, name, artist, imagelink;
  recomtrack(this.id, this.url, this.name, this.artist, this.imagelink);
}

class genre {
  String gen;
  num coef;
  set setcoef(num newcoef) {
    coef = coef + newcoef;
  }

  genre(this.gen, this.coef);
}

class track {
  final String id;
  final String url;
  final num energy;
  final num tempo;
  final num valance;
  final num dance;
  track(this.id, [this.url, this.energy, this.tempo, this.valance, this.dance]);
}

var clientid = "10bda4a36a694b28b9ef08e2f2956b58";
var clientsecret = "a5924dda34d14f709482d4f4951deb3a";
var redirecturi = "https://example.com/callback";
var authtoken = "";
var username = "";
var timerangechart = 0;
var trackartist = 0;
var timerange = 0;
bool ispremium = false;
charts.Series<String, int> seri;
num energy = 0, instrumental = 0, tempo = 0, valance = 0, dance = 0;
List<String> images = new List<String>();
bool timerangechange = false;
List<recomtrack> trackrecommended = new List<recomtrack>();
List<recomtrack> trackrecommended2 = new List<recomtrack>();
List<recomtrack> trackrecommended3 = new List<recomtrack>();
List<recomtrack> trackstoload = new List<recomtrack>();
List<genre> genres = new List<genre>();
List<genre> genres2 = new List<genre>();
List<String> urls = new List<String>();
List<String> name = new List<String>();
List<String> spfgnr = new List<String>();
List<recent> recentsngs = new List<recent>();
bool playerstat = false;
bool isactive = false;
bool isfirstop = true;
double limit = 0;
int timerange3 = 0;
int secim = 0;
List<double> gnrcnt = new List<double>();
List<charts.Series<chartdata, String>> mainn;
List<chartdata> chartseries = new List<chartdata>();
List<track> tracks = new List<track>();
String currentms = "";
double currentmsd = 0, durationmsd = 0;
String imageurl;
String durationms = "";
String songname = "";
String artistname = "";
bool isplaying = false;
Future<String> getauthtoken() async {
  var token = await SpotifySdk.getAuthenticationToken(
      clientId: clientid,
      redirectUrl: redirecturi,
      scope:
          "user-read-recently-played,user-top-read,user-read-playback-state,user-modify-playback-state,user-read-currently-playing,user-follow-read,user-library-modify,user-read-playback-position,playlist-read-private,user-library-read,streaming,user-read-private");
  print("Token: $token");
  await appconnection();
  return token;
}

Future appconnection() async {
  var res = await SpotifySdk.connectToSpotifyRemote(
      clientId: clientid, redirectUrl: redirecturi);
  print(res);
}

class chartdata {
  final String x;
  final double y;
  final charts.Color c;
  chartdata(this.x, this.y, this.c);
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

String mstomn(int duration) {
  int seconds = duration ~/ 1000;
  int min = seconds ~/ 60;
  int secs = seconds % 60;
  String secstr = (secs < 10) ? "0" + secs.toString() : secs.toString();
  return min.toString() + ":" + secstr;
}

_showdialog(AlertDialog al, BuildContext context) async {
  Future.delayed(new Duration(milliseconds: 50), () {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return al;
        });
  });
}

void getname(BuildContext context) async {
  var response = await http.get("https://api.spotify.com/v1/me",
      headers: {"Authorization": "Bearer " + authtoken});
  var data = json.decode(response.body);
  switch (data["product"]) {
    case "premium":
      ispremium = true;
      break;
    case "free":
      ispremium = false;
      break;
    case "open":
      ispremium = false;
      break;
  }

  if (ispremium == false) {
    AlertDialog alert = new AlertDialog(
      content: Text(
          "Bu uygulamayı kullanabilmek için Spotify Premium sahibi olmalısınız",
          style: TextStyle(fontFamily: "Spotify")),
      actions: [
        FlatButton(
            onPressed: () {
              SystemChannels.platform.invokeMethod('SystemNavigator.pop');
            },
            child: Text("TAMAM"))
      ],
    );

    _showdialog(alert, context);
  }
  if (data["display_name"].toString().contains(" "))
    username = data["display_name"]
        .toString()
        .substring(0, data["display_name"].toString().indexOf(" "));
  else {
    username = data["display_name"].toString();
  }
  username = username.characters.first.toUpperCase() + username.substring(1);
}

void updategenres() async {
  genres.clear();
  tracks.clear();
  energy = 0;
  tempo = 0;
  valance = 0;
  dance = 0;
  String range2 = "middle_term";
  switch (timerangechart) {
    case 0:
      range2 = "short_term";
      break;
    case 1:
      range2 = "medium_term";
      break;
    case 2:
      range2 = "long_term";
      break;
  }
  var itemlist = "";
  List<String> ids = new List<String>();
  List<String> uris = new List<String>();
  var isfirst = true;
  print("auth before: $authtoken");
  var response1 = await http.get(
      "https://api.spotify.com/v1/me/top/tracks?time_range=$range2&limit=30",
      headers: {"Authorization": "Bearer " + authtoken});
  var response2 = await http.get(
      "https://api.spotify.com/v1/me/top/artists?time_range=$range2&limit=30",
      headers: {"Authorization": "Bearer " + authtoken});

  if (tracks.isEmpty == true) {
    for (var item in json.decode(response1.body)["items"]) {
      ids.add(item["id"]);
      uris.add(item["uri"]);
      if (isfirst == true) {
        itemlist = itemlist + item["id"];
        isfirst = false;
      } else {
        itemlist = itemlist + "%2C" + item["id"];
      }
    }
    var trackres = await http.get(
        "https://api.spotify.com/v1/audio-features/?ids=$itemlist",
        headers: {
          "Authorization": "Bearer " + authtoken,
          "Accept": "application/json",
          "Content-Type": "application/json"
        });
    var trackdata = json.decode(trackres.body);
    for (int i = 0; i < ids.length; i++) {
      var thistrack = new track(
          ids[i],
          uris[i],
          trackdata["audio_features"][i]["energy"],
          trackdata["audio_features"][i]["tempo"],
          trackdata["audio_features"][i]["valence"],
          trackdata["audio_features"][i]["danceability"]);
      tracks.add(thistrack);
    }

    for (var item in tracks) {
      energy = energy + item.energy;
      tempo = tempo + item.tempo;
      valance = valance + item.valance;
      dance = dance + item.dance;
    }
    energy = energy / tracks.length * 100;
    tempo = tempo / tracks.length;
    valance = (valance / tracks.length) * 100;
    dance = (dance / tracks.length) * 100;
  }
  var jsonindex = 0;
  var mainindex =
      "genres".allMatches(json.decode(response2.body).toString()).length;
  for (var item in json.decode(response2.body)["items"]) {
    for (var item1 in item["genres"]) {
      if (item.toString().contains("songwriter") == false) {
        var gn = new genre(item1.toString().replaceAll("turkish", "türkçe"),
            mainindex - jsonindex);
        genres.add(gn);
      }
    }
    jsonindex++;
  }
  getspecificitems();
}

Future loadimages(BuildContext context) async {
  String range = "short_term";
  String trackartistval = "tracks";
  switch (trackartist) {
    case 0:
      trackartistval = "tracks";
      break;
    case 1:
      trackartistval = "artists";
      break;
  }
  switch (timerange) {
    case 0:
      range = "short_term";
      break;
    case 1:
      range = "medium_term";
      break;
    case 2:
      range = "long_term";
      break;
  }

  images.clear();
  name.clear();
  urls.clear();
  if (authtoken == "") {
    authtoken = await getauthtoken();
    var response = await http.get(
        "https://api.spotify.com/v1/me/top/$trackartistval?time_range=$range&limit=30",
        headers: {"Authorization": "Bearer " + authtoken});
    if (json.decode(response.body)["items"] == null) {
      AlertDialog alert = new AlertDialog(
        content: Text(
            "İstatistik ve önerilerinizi görmek için Spotifyda yeteri kadar dinleme yapmadınız",
            style: TextStyle(fontFamily: "Spotify")),
        actions: [
          FlatButton(
              onPressed: () {
                SystemChannels.platform.invokeMethod('SystemNavigator.pop');
              },
              child: Text("TAMAM"))
        ],
      );
      _showdialog(alert, context);
    }

    if (trackartistval == "tracks") {
      for (var item in json.decode(response.body)["items"]) {
        images.add(item["album"]["images"][0]["url"]);
        name.add(item["name"]);
        urls.add(item["uri"]);
        print(item["album"]["images"][0]["url"]);
      }
    } else if (trackartistval == "artists") {
      genres.clear();
      for (var item in json.decode(response.body)["items"]) {
        images.add(item["images"][0]["url"]);
        name.add(item["name"]);
        urls.add(item["uri"]);
        print(item["images"][0]["url"]);
      }
    }
  } else {
    var response = await http.get(
        "https://api.spotify.com/v1/me/top/$trackartistval?time_range=$range&limit=30",
        headers: {"Authorization": "Bearer " + authtoken});
    if (trackartistval == "tracks") {
      for (var item in json.decode(response.body)["items"]) {
        images.add(item["album"]["images"][0]["url"]);
        name.add(item["name"]);
        urls.add(item["uri"]);
        print(item["album"]["images"][0]["url"]);
      }
    } else if (trackartistval == "artists") {
      for (var item in json.decode(response.body)["items"]) {
        images.add(item["images"][0]["url"]);
        name.add(item["name"]);
        print(item["images"][0]["url"]);
      }
    }
  }
}

class aftersplash extends StatefulWidget {
  @override
  _aftersplashstate createState() => _aftersplashstate();
}

class _aftersplashstate extends State<aftersplash> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1b1b1b),
      body: IndexedStack(
        index: current,
        children: <Widget>[home(), play(), lib()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: current,
        selectedItemColor: Colors.green[700],
        unselectedItemColor: Colors.white,
        items: [
          new BottomNavigationBarItem(
            icon: Icon(Icons.format_list_numbered_outlined),
            label: "İstatistik",
          ),
          new BottomNavigationBarItem(
            icon: Icon(Icons.music_note),
            label: "Oynatıcı",
          ),
          new BottomNavigationBarItem(
            icon: Icon(Icons.my_library_music),
            label: "Önerilenler",
          )
        ],
        backgroundColor: Color(0xFF1b1b1b),
        onTap: (int index) {
          setState(() {
            current = index;
          });
        },
      ),
    );
  }
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    waiting();
  }

  int loading = 0;
  Future waiting() async {
    await loadimages(context);
    setState(() {
      loading += 30;
    });

    updategenres();
    setState(() {
      loading += 20;
    });
    getname(context);
    playback();
    setState(() {
      loading += 30;
    });
    await getrocoms();
    setState(() {
      loading += 20;
    });
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (BuildContext context) => aftersplash()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset('assets/splash.png'),
              Text("Yükleniyor %$loading",
                  style: TextStyle(
                      fontFamily: "Spotify", fontSize: 18, color: Colors.white))
            ]),
      ),
    );
  }
}

void getspecificitems() async {
  spfgnr.clear();
  gnrcnt.clear();
  chartseries.clear();
  genres2.clear();
  double total = 0;
  //Genreleri ekle ve hepsinin kaç kere olduğunu bul
  for (var item in genres) {
    if (genres2.where((element) => element.gen == item.gen).isEmpty == true) {
      genres2.add(item);
    } else {
      for (var item1 in genres2.where((element) => element.gen == item.gen)) {
        item1.setcoef = item.coef;
      }
    }
  }
  for (var item in genres2) {
    if (spfgnr.contains(item.gen) == false) {
      spfgnr.add(item.gen);
      gnrcnt.add(double.parse(item.coef.toString()));
    }
  }
//Bubble Sort ile genreleri azdan çoka şekilde sırala
  var iscompleted = 0;
  while (iscompleted == 0) {
    iscompleted = 1;
    for (int i = 0; i < gnrcnt.length - 1; i++) {
      if (gnrcnt[i] < gnrcnt[i + 1]) {
        iscompleted = 0;
        var temp1 = gnrcnt[i];
        gnrcnt[i] = gnrcnt[i + 1];
        gnrcnt[i + 1] = temp1;
        var temp2 = spfgnr[i];
        spfgnr[i] = spfgnr[i + 1];
        spfgnr[i + 1] = temp2;
      }
    }
  }
  //Timrangecharta göre tabloda göstermek için limit
  switch (timerangechart) {
    case 0:
      limit = 1.5;
      break;
    case 1:
      limit = 1.75;
      break;
    case 2:
      limit = 2.0;
      break;
  }
  //Itemların sayıları yerine yüzdelerini hesapla
  for (var item in gnrcnt) {
    total = total + (item * (gnrcnt.length - gnrcnt.indexOf(item)));
  }
  for (var item in gnrcnt) {
    double d = ((item * (gnrcnt.length - gnrcnt.indexOf(item))) / total) * 100;
    gnrcnt[gnrcnt.indexOf(item)] = double.parse(d.toStringAsFixed(2));
  }
  double others = 0;
  List<double> gnrcf = new List<double>();
  List<String> gnrnm = new List<String>();
  for (int i = 0; i < gnrcnt.length; i++) {
    if (gnrcnt[i] < limit) {
      others = others + gnrcnt[i];
      gnrcf.add(gnrcnt[i]);
      gnrnm.add(spfgnr[i]);
    }
  }
  for (int i = 0; i < gnrcf.length; i++) {
    gnrcnt.removeWhere((element) => element == gnrcf[i]);
    spfgnr.removeWhere((element) => element == gnrnm[i]);
  }

  if (others > 0) {
    spfgnr.add("Diğer");
    gnrcnt.add(double.parse(others.toStringAsFixed(2)));
  }
  //Itemları chartdata olarak ekliyoruz
  for (int i = 0; i < spfgnr.length; i++) {
    if (gnrcnt[i] > limit) {
      Random random1 = new Random();
      Random random2 = new Random();
      Random random3 = new Random();
      chartseries.add(chartdata(
          spfgnr[i],
          gnrcnt[i],
          charts.Color(
              r: random1.nextInt(255),
              g: random2.nextInt(255),
              b: random3.nextInt(255))));
    }
  }
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SpotifStats',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'SpotifStats'),
    );
  }
}

var current = 0;

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class home extends StatefulWidget {
  @override
  _home createState() => _home();
}

final AdvertService _advertService = new AdvertService();

class _home extends State<home> with AutomaticKeepAliveClientMixin<home> {
  @override
  bool get wantKeepAlive => true;

  String tokengot = "boş";
  String dropdownval = "Son 1 ay";
  String dropdownval2 = "Şarkılar";
  String dropdownval3 = "Son 1 ay";
  var size = 22;
  var trackartist = 0;
  var timerange = 0;

  @override
  void initState() {
    super.initState();
    opened();
  }

  void getname() async {
    var response = await http.get("https://api.spotify.com/v1/me",
        headers: {"Authorization": "Bearer " + authtoken});
    setState(() {
      var data = json.decode(response.body);
      switch (data["product"]) {
        case "premium":
          ispremium = true;
          break;
        case "free":
          ispremium = false;
          break;
        case "open":
          ispremium = false;
          break;
      }
      if (data["display_name"].toString().contains(" "))
        username = data["display_name"]
            .toString()
            .substring(0, data["display_name"].toString().indexOf(" "));
      else {
        username = data["display_name"].toString();
      }
      username =
          username.characters.first.toUpperCase() + username.substring(1);
    });
  }

  void updategenres() async {
    genres.clear();
    tracks.clear();
    energy = 0;
    tempo = 0;
    valance = 0;
    dance = 0;
    String range2 = "middle_term";
    switch (timerangechart) {
      case 0:
        range2 = "short_term";
        break;
      case 1:
        range2 = "medium_term";
        break;
      case 2:
        range2 = "long_term";
        break;
    }
    var itemlist = "";
    List<String> ids = new List<String>();
    List<String> uris = new List<String>();
    var isfirst = true;
    print("auth before: $authtoken");
    var response1 = await http.get(
        "https://api.spotify.com/v1/me/top/tracks?time_range=$range2&limit=30",
        headers: {"Authorization": "Bearer " + authtoken});
    var response2 = await http.get(
        "https://api.spotify.com/v1/me/top/artists?time_range=$range2&limit=30",
        headers: {"Authorization": "Bearer " + authtoken});
    if (tracks.isEmpty == true) {
      for (var item in json.decode(response1.body)["items"]) {
        ids.add(item["id"]);
        uris.add(item["uri"]);
        if (isfirst == true) {
          itemlist = itemlist + item["id"];
          isfirst = false;
        } else {
          itemlist = itemlist + "%2C" + item["id"];
        }
      }
      var trackres = await http.get(
          "https://api.spotify.com/v1/audio-features/?ids=$itemlist",
          headers: {
            "Authorization": "Bearer " + authtoken,
            "Accept": "application/json",
            "Content-Type": "application/json"
          });
      var trackdata = json.decode(trackres.body);
      for (int i = 0; i < ids.length; i++) {
        var thistrack = new track(
            ids[i],
            uris[i],
            trackdata["audio_features"][i]["energy"],
            trackdata["audio_features"][i]["tempo"],
            trackdata["audio_features"][i]["valence"],
            trackdata["audio_features"][i]["danceability"]);
        tracks.add(thistrack);
      }

      for (var item in tracks) {
        energy = energy + item.energy;
        tempo = tempo + item.tempo;
        valance = valance + item.valance;
        dance = dance + item.dance;
      }
      energy = energy / tracks.length * 100;
      tempo = tempo / tracks.length;
      valance = (valance / tracks.length) * 100;
      dance = (dance / tracks.length) * 100;
    }
    var jsonindex = 0;
    var mainindex =
        "genres".allMatches(json.decode(response2.body).toString()).length;
    for (var item in json.decode(response2.body)["items"]) {
      for (var item1 in item["genres"]) {
        if (item.toString().contains("songwriter") == false) {
          var gn = new genre(item1.toString().replaceAll("turkish", "türkçe"),
              mainindex - jsonindex);
          genres.add(gn);
        }
      }
      jsonindex++;
    }
    setState(() {
      getspecificitems();
    });
  }

  void opened() {
    setState(() {});
  }

  Future loadimages_() async {
    String range = "short_term";
    String trackartistval = "tracks";
    switch (trackartist) {
      case 0:
        trackartistval = "tracks";
        break;
      case 1:
        trackartistval = "artists";
        break;
    }
    switch (timerange) {
      case 0:
        range = "short_term";
        break;
      case 1:
        range = "medium_term";
        break;
      case 2:
        range = "long_term";
        break;
    }

    images.clear();
    name.clear();
    urls.clear();
    if (authtoken == "") {
      authtoken = await getauthtoken();
      var response = await http.get(
          "https://api.spotify.com/v1/me/top/$trackartistval?time_range=$range&limit=30",
          headers: {"Authorization": "Bearer " + authtoken});

      setState(() {
        if (trackartistval == "tracks") {
          for (var item in json.decode(response.body)["items"]) {
            images.add(item["album"]["images"][0]["url"]);
            name.add(item["name"]);
            urls.add(item["uri"]);
            print(item["album"]["images"][0]["url"]);
          }
        } else if (trackartistval == "artists") {
          genres.clear();
          for (var item in json.decode(response.body)["items"]) {
            images.add(item["images"][0]["url"]);
            name.add(item["name"]);
            print(item["images"][0]["url"]);
          }
        }
        tokengot = authtoken;
      });
    } else {
      var response = await http.get(
          "https://api.spotify.com/v1/me/top/$trackartistval?time_range=$range&limit=30",
          headers: {"Authorization": "Bearer " + authtoken});
      setState(() {
        if (trackartistval == "tracks") {
          for (var item in json.decode(response.body)["items"]) {
            images.add(item["album"]["images"][0]["url"]);
            name.add(item["name"]);
            urls.add(item["uri"]);
            print(item["album"]["images"][0]["url"]);
          }
        } else if (trackartistval == "artists") {
          for (var item in json.decode(response.body)["items"]) {
            images.add(item["images"][0]["url"]);
            name.add(item["name"]);
            print(item["images"][0]["url"]);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    List<charts.Series<chartdata, String>> _sample() {
      return [
        new charts.Series<chartdata, String>(
            id: "Türler",
            data: chartseries,
            colorFn: (chartdata data, _) => data.c,
            domainFn: (chartdata data, _) => data.x,
            measureFn: (chartdata data, _) => data.y,
            labelAccessorFn: (chartdata row, _) => '${row.x}: ${row.y}')
      ];
    }

    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(children: <Widget>[
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
                padding: EdgeInsets.only(top: 40),
                child: Row(children: [
                  AutoSizeText("Merhaba " + username + ",",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontFamily: "Spotify",
                      )),
                ])),
          ),
          Padding(
              padding: EdgeInsets.only(top: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Theme(
                      data: Theme.of(context).copyWith(
                        canvasColor: Colors.black,
                      ),
                      child: Container(
                          width: 89,
                          child: DropdownButton<String>(
                            isExpanded: true,
                            dropdownColor: Colors.green[700],
                            value: dropdownval,
                            icon: Icon(Icons.arrow_downward),
                            iconSize: 16,
                            elevation: 16,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: "Spotify"),
                            underline: Container(
                              height: 2,
                              color: Colors.green[800],
                            ),
                            onChanged: (String value) async {
                              if (value == "Son 1 ay") {
                                timerange = 0;
                                await loadimages_();
                              } else if (value == "Son 6 ay") {
                                timerange = 1;
                                await loadimages_();
                              } else if (value == "Tüm Zamanlar") {
                                timerange = 2;
                                await loadimages_();
                              }
                              setState(() {
                                dropdownval = value;
                                print(dropdownval);
                              });
                            },
                            items: <String>[
                              'Son 1 ay',
                              'Son 6 ay',
                              'Tüm Zamanlar'
                            ].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ))),
                  Text(
                    " içinde en çok dinlediğin ",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: "Spotify"),
                  ),
                  Theme(
                      data: Theme.of(context).copyWith(
                        canvasColor: Colors.black,
                      ),
                      child: Container(
                          child: DropdownButton<String>(
                        value: dropdownval2,
                        dropdownColor: Colors.green[700],
                        icon: Icon(Icons.arrow_downward),
                        iconSize: 16,
                        elevation: 16,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontFamily: "Spotify"),
                        underline: Container(
                          height: 2,
                          width: 4,
                          color: Colors.green[800],
                        ),
                        onChanged: (String value) {
                          setState(() {
                            dropdownval2 = value;
                            print(dropdownval2);
                          });
                          if (value == "Şarkılar") {
                            trackartist = 0;
                            loadimages_();
                          } else if (value == "Sanatçılar") {
                            trackartist = 1;
                            loadimages_();
                          }
                        },
                        items: <String>['Şarkılar', 'Sanatçılar']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      )))
                ],
              )),
          Container(
              height: 220,
              child: ListView.separated(
                primary: false,
                scrollDirection: Axis.horizontal,
                separatorBuilder: (context, index) {
                  return VerticalDivider(thickness: 0.5);
                },
                itemCount: images.length,
                itemBuilder: (context, position) {
                  return Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Column(children: [
                        SizedBox(
                            height: 200,
                            width: 150,
                            child: Stack(children: [
                              Container(
                                width: 150,
                                height: 170,
                                child: ConstrainedBox(
                                  child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: GestureDetector(
                                          onTap: () async {
                                            var data =
                                                '{"uris":["${urls[position]}"]}';
                                            var res = await http.put(
                                                "https://api.spotify.com/v1/me/player/play",
                                                headers: {
                                                  "Authorization":
                                                      "Bearer " + authtoken,
                                                  "Content-Type":
                                                      "application/json",
                                                  "charset": "utf-8"
                                                },
                                                body: data);
                                            if (json.decode(res.body)["error"]
                                                    ["reason"] ==
                                                "NO_ACTIVE_DEVICE") {
                                              SpotifySdk.play(
                                                  spotifyUri: urls[position]);
                                            }
                                          },
                                          child: Image.network(images[position],
                                              width: 150, height: 170))),
                                  constraints: BoxConstraints(
                                      maxWidth: 150, maxHeight: 170),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: 5),
                                child: Stack(children: [
                                  Align(
                                      alignment: Alignment.topLeft,
                                      child: Text(
                                        "#${position + 1}",
                                        maxLines: 3,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 28,
                                          color: Colors.white,
                                          fontFamily: "Spotify",
                                          shadows: <Shadow>[
                                            Shadow(
                                              offset: Offset(7.0, 7.0),
                                              blurRadius: 3.0,
                                              color:
                                                  Color.fromARGB(100, 0, 0, 0),
                                            ),
                                            Shadow(
                                              offset: Offset(7.0, 7.0),
                                              blurRadius: 15.0,
                                              color:
                                                  Color.fromARGB(100, 0, 0, 0),
                                            ),
                                          ],
                                        ),
                                      )),
                                ]),
                              ),
                              Padding(
                                  padding: EdgeInsets.only(top: 170),
                                  child: Center(
                                      child: Text(
                                    name[position],
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontFamily: "Spotify"),
                                    maxLines: 5,
                                  )))
                            ]))
                      ]));
                },
              )),
          Padding(
              padding: EdgeInsets.only(top: 0, left: 0, right: 0),
              child: Row(children: [
                Text("Dinlediğin Türler",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontFamily: "Spotify")),
                Container(
                    width: 120,
                    margin: EdgeInsets.only(left: 30),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: dropdownval3,
                      dropdownColor: Colors.green[700],
                      icon: Icon(Icons.arrow_downward),
                      iconSize: 22,
                      elevation: 16,
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: "Spotify",
                        fontSize: double.parse(size.toString()),
                      ),
                      underline: Container(
                        height: 2,
                        width: 4,
                        color: Colors.green[800],
                      ),
                      onChanged: (String value) {
                        _advertService.showIntersitial();
                        setState(() {
                          dropdownval3 = value;
                          print(dropdownval3);
                        });
                        if (value == "Son 1 ay") {
                          timerangechart = 0;
                          size = 22;
                          updategenres();
                        } else if (value == "Son 6 ay") {
                          timerangechart = 1;
                          size = 22;
                          updategenres();
                        } else if (value == "Tüm zamanlar") {
                          timerangechart = 2;
                          size = 15;
                          updategenres();
                        }
                      },
                      items: <String>['Son 1 ay', 'Son 6 ay', 'Tüm zamanlar']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ))
              ])),
          SizedBox(
              height: 280,
              width: MediaQuery.of(context).size.width,
              child: Container(
                  height: 280,
                  width: MediaQuery.of(context).size.width,
                  child: charts.PieChart(_sample(),
                      animate: false,
                      behaviors: [
                        new charts.DatumLegend(
                          position: charts.BehaviorPosition.end,
                          entryTextStyle: charts.TextStyleSpec(
                              color: charts.Color.white, fontSize: 10),
                          horizontalFirst: false,
                          outsideJustification:
                              charts.OutsideJustification.middleDrawArea,
                          cellPadding:
                              new EdgeInsets.only(right: 4.0, bottom: 4.0),
                          showMeasures: true,
                          legendDefaultMeasure:
                              charts.LegendDefaultMeasure.firstValue,
                          measureFormatter: (num value) {
                            return value == null ? '-' : '%$value';
                          },
                        ),
                      ],
                      defaultRenderer: new charts.ArcRendererConfig(
                        arcWidth: 40,
                      )))),
          Align(
              alignment: Alignment.topLeft,
              child: AutoSizeText("Dinlediğin Şarkıların ",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontFamily: "Spotify"))),
          Padding(
              padding: EdgeInsets.only(top: 10),
              child: Align(
                  alignment: Alignment.topLeft,
                  child: AutoSizeText(dropdownval3 + " için",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.green[800],
                          fontSize: 22,
                          fontFamily: "Spotify")))),
          Row(children: [
            Padding(
                padding: EdgeInsets.only(top: 10, right: 5),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                          width: MediaQuery.of(context).size.width / 2 - 5,
                          height: 130,
                          padding: EdgeInsets.only(top: 10),
                          color: Color(0xFF222222),
                          child: Column(children: [
                            Align(
                                alignment: Alignment.center,
                                child: Column(children: [
                                  Text(
                                    "Enerji",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: "Spotify",
                                        fontSize: 30),
                                  ),
                                  Padding(
                                      padding: EdgeInsets.only(top: 5),
                                      child: Text(
                                        "%${energy.toStringAsFixed(0)}",
                                        style: TextStyle(
                                            color: Colors.green[800],
                                            fontFamily: "Spotify",
                                            fontSize: 30),
                                      )),
                                  Padding(
                                      padding: EdgeInsets.only(
                                          top: 5, left: 20, right: 20),
                                      child: Text(
                                        "Bu özellik şarkıların hızına ve",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontFamily: "Spotify"),
                                        maxLines: 1,
                                      )),
                                  Padding(
                                      padding:
                                          EdgeInsets.only(left: 25, right: 25),
                                      child: Text(
                                        "gürültüsüne bağlıdır",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontFamily: "Spotify"),
                                        maxLines: 1,
                                      ))
                                ]))
                          ]))),
                )),
            Padding(
                padding: EdgeInsets.only(top: 10, left: 5),
                child: Align(
                    alignment: Alignment.topRight,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                          width: MediaQuery.of(context).size.width / 2 - 5,
                          height: 130,
                          padding: EdgeInsets.only(top: 10),
                          color: Color(
                            0xFF222222,
                          ),
                          child: Column(children: [
                            Align(
                                alignment: Alignment.center,
                                child: Column(children: [
                                  Text(
                                    "Tempo",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: "Spotify",
                                        fontSize: 30),
                                  ),
                                  Padding(
                                      padding: EdgeInsets.only(top: 5),
                                      child: Text(
                                        "${tempo.toStringAsFixed(0)}bpm",
                                        style: TextStyle(
                                            color: Colors.green[800],
                                            fontFamily: "Spotify",
                                            fontSize: 30),
                                      )),
                                  Padding(
                                      padding: EdgeInsets.only(
                                          top: 10, left: 20, right: 20),
                                      child: Text(
                                        "Dinlediğiniz Şarkıların",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontFamily: "Spotify"),
                                        maxLines: 1,
                                      )),
                                  Padding(
                                      padding:
                                          EdgeInsets.only(left: 20, right: 20),
                                      child: Text(
                                        "Ortalama Temposu",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontFamily: "Spotify"),
                                        maxLines: 1,
                                      )),
                                ]))
                          ])),
                    )))
          ]),
          Row(children: [
            Padding(
                padding: EdgeInsets.only(top: 10, right: 5),
                child: Align(
                    alignment: Alignment.topLeft,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: MediaQuery.of(context).size.width / 2 - 5,
                        height: 130,
                        padding: EdgeInsets.only(top: 10),
                        color: Color(0xFF222222),
                        child: Column(children: [
                          Align(
                              alignment: Alignment.center,
                              child: Column(children: [
                                Text(
                                  "Dans",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: "Spotify",
                                      fontSize: 30),
                                ),
                                Padding(
                                    padding: EdgeInsets.only(top: 5),
                                    child: Text(
                                      "%${dance.toStringAsFixed(0)}",
                                      style: TextStyle(
                                          color: Colors.green[800],
                                          fontFamily: "Spotify",
                                          fontSize: 30),
                                    )),
                                Padding(
                                    padding: EdgeInsets.only(
                                        top: 5, left: 25, right: 20),
                                    child: Text(
                                      "Şarkıların dans etmek için ",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontFamily: "Spotify"),
                                      maxLines: 1,
                                    )),
                                Padding(
                                    padding:
                                        EdgeInsets.only(left: 10, right: 10),
                                    child: Text(
                                      "ortalama uygunluğunu gösterir",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontFamily: "Spotify"),
                                      maxLines: 1,
                                    ))
                              ]))
                        ]),
                      ),
                    ))),
            Padding(
                padding: EdgeInsets.only(top: 10, left: 5),
                child: Align(
                    alignment: Alignment.topRight,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                          width: MediaQuery.of(context).size.width / 2 - 5,
                          height: 130,
                          padding: EdgeInsets.only(top: 10),
                          color: Color(0xFF222222),
                          child: Column(children: [
                            Align(
                                alignment: Alignment.center,
                                child: Column(children: [
                                  Text(
                                    "Mutluluk",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: "Spotify",
                                        fontSize: 30),
                                  ),
                                  Padding(
                                      padding: EdgeInsets.only(top: 5),
                                      child: Text(
                                        "%${valance.toStringAsFixed(0)}",
                                        style: TextStyle(
                                            color: Colors.green[800],
                                            fontFamily: "Spotify",
                                            fontSize: 30),
                                      )),
                                  Padding(
                                      padding: EdgeInsets.only(
                                          top: 5, left: 20, right: 20),
                                      child: Text(
                                        "Bu özellik şarkıların ortalama ",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontFamily: "Spotify"),
                                        maxLines: 1,
                                      )),
                                  Padding(
                                      padding:
                                          EdgeInsets.only(left: 25, right: 25),
                                      child: Text(
                                        "mutluluğunu gösterir",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontFamily: "Spotify"),
                                        maxLines: 1,
                                      ))
                                ]))
                          ])),
                    )))
          ])
        ]));
  }
}

class play extends StatefulWidget {
  @override
  _play createState() => _play();
}

String getdiff(String date) {
  DateTime dt = DateTime.parse(date);
  var days = DateTime.now().difference(dt).inDays;
  var hrs = DateTime.now().difference(dt).inHours;
  var mins = DateTime.now().difference(dt).inMinutes;
  var secs = DateTime.now().difference(dt).inSeconds;
  if (days > 0)
    return days.toString() + " gün";
  else if (hrs > 0)
    return hrs.toString() + " saat";
  else if (mins > 0)
    return mins.toString() + " dk";
  else if (secs > 0)
    return secs.toString() + " sn";
  else
    return "şimdi";
}

void playback() async {
  if (authtoken == "") {
    await getauthtoken();
  }
  var response = await http.get(
      "https://api.spotify.com/v1/me/player?market=TR",
      headers: {"Authorization": " Bearer " + authtoken});
  if (response.statusCode != 204) {
    var decoded = json.decode(response.body);
    currentms = mstomn(decoded["progress_ms"]);
    imageurl = decoded["item"]["album"]["images"][0]["url"];
    durationms = mstomn(decoded["item"]["duration_ms"]);
    currentmsd = double.parse(decoded["progress_ms"].toString());
    durationmsd = double.parse(decoded["item"]["duration_ms"].toString());
    songname = decoded["item"]["name"];
    bool isfirst = true;
    for (var item in decoded["item"]["artists"]) {
      if (isfirst == true) {
        artistname = item["name"];
        isfirst = false;
      } else
        artistname = artistname + " & " + item["name"];
    }
    isplaying = decoded["is_playing"];
  }
}

class songimage extends StatelessWidget {
  Widget build(BuildContext context) {
    if (playerstat == true) {
      return Image.network(
        imageurl,
        width: 120,
        height: 120,
      );
    } else {
      return Image.asset(
        "assets/notrack.png",
        width: 120,
        height: 120,
      );
    }
  }
}

void recentsongs() async {
  recentsngs.clear();
  String tracksstr = "";
  bool isfirsttrack = true;
  var res = await http.get(
      "https://api.spotify.com/v1/me/player/recently-played?limit=50",
      headers: {"Authorization": " Bearer " + authtoken});
  var decoded = json.decode(res.body)["items"];
  for (var item in decoded) {
    if (isfirsttrack == true) {
      tracksstr = item["track"]["id"].toString();
      isfirsttrack = false;
    } else {
      tracksstr = tracksstr + "%2C" + item["track"]["id"];
    }
  }
  List<String> played_ats = new List<String>();
  var res2 = await http.get(
      "https://api.spotify.com/v1/tracks/?ids=" + tracksstr,
      headers: {"Authorization": " Bearer " + authtoken});
  var decoded2 = await json.decode(res2.body)["tracks"];
  var artists_ = "";
  for (var item in decoded) {
    for (var item1 in decoded2) {
      if (item1["id"] == item["track"]["id"]) {
        for (var item2 in item1["artists"]) {
          if (artists_ == "") {
            artists_ = item2["name"];
          } else {
            artists_ = artists_ + " & " + item2["name"];
          }
        }
        recent _rcent = recent(
            item["track"]["id"].toString(),
            item["track"]["uri"].toString(),
            item["track"]["name"],
            item["played_at"],
            item1["album"]["images"][0]["url"].toString(),
            item["track"]["duration_ms"],
            artists_);
        if (played_ats.contains(_rcent.playedat) == false) {
          recentsngs.add(_rcent);
          played_ats.add(_rcent.playedat);
        }
      }
      artists_ = "";
    }
  }
}

class _play extends State<play> {
  Timer proggrestimer;
  List<String> played_ats = new List<String>();
  void recentsongs_() async {
    String tracksstr = "";
    bool isfirsttrack = true;
    var res = await http.get(
        "https://api.spotify.com/v1/me/player/recently-played?limit=50",
        headers: {"Authorization": " Bearer " + authtoken});
    var decoded = json.decode(res.body)["items"];
    for (var item in decoded) {
      if (isfirsttrack == true) {
        tracksstr = item["track"]["id"].toString();
        isfirsttrack = false;
      } else {
        tracksstr = tracksstr + "%2C" + item["track"]["id"];
      }
    }

    var res2 = await http.get(
        "https://api.spotify.com/v1/tracks/?ids=" + tracksstr,
        headers: {"Authorization": " Bearer " + authtoken});
    var decoded2 = await json.decode(res2.body)["tracks"];
    var artists_ = "";
    for (var item in decoded) {
      for (var item1 in decoded2) {
        if (item1["id"] == item["track"]["id"]) {
          for (var item2 in item1["artists"]) {
            if (artists_ == "") {
              artists_ = item2["name"];
            } else {
              artists_ = artists_ + " & " + item2["name"];
            }
          }
          recent _rcent = recent(
              item["track"]["id"].toString(),
              item["track"]["uri"].toString(),
              item["track"]["name"],
              item["played_at"],
              item1["album"]["images"][0]["url"].toString(),
              item["track"]["duration_ms"],
              artists_);
          if (played_ats.contains(_rcent.playedat) == false) {
            setState(() {
              recentsngs.add(_rcent);
            });

            played_ats.add(_rcent.playedat);
          }
        }
        artists_ = "";
      }
    }

    print("recent loaded");
  }

  @override
  void initState() {
    super.initState();

    if (authtoken == "") {
      Future.delayed(new Duration(seconds: 1), () {
        playback();
        recentsongs_();
      });
    } else {
      playback();
      recentsongs_();
    }

    proggrestimer = Timer.periodic(new Duration(seconds: 1), (timer) {
      playback();
    });
    Timer.periodic(new Duration(seconds: 2), (timer) {
      recentsongs_();
    });
    Timer.periodic(new Duration(seconds: 30), (timer) {
      appconnection();
    });
  }

  void starttimer() {
    playback();
    proggrestimer =
        new Timer.periodic(new Duration(milliseconds: 1000), (timer) {
      playback();
    });
    print(proggrestimer.isActive.toString());
  }

  Future playback() async {
    if (authtoken == "") {
      await getauthtoken();
    }
    var response = await http.get(
        "https://api.spotify.com/v1/me/player?market=TR",
        headers: {"Authorization": " Bearer " + authtoken});
    if (response.statusCode != 204) {
      setState(() {
        playerstat = true;
        var decoded = json.decode(response.body);
        currentms = mstomn(decoded["progress_ms"]);
        imageurl = decoded["item"]["album"]["images"][0]["url"];
        durationms = mstomn(decoded["item"]["duration_ms"]);
        currentmsd = double.parse(decoded["progress_ms"].toString());
        print(currentmsd);
        durationmsd = double.parse(decoded["item"]["duration_ms"].toString());
        songname = decoded["item"]["name"];
        bool isfirst = true;
        for (var item in decoded["item"]["artists"]) {
          if (isfirst == true) {
            artistname = item["name"];
            isfirst = false;
          } else
            artistname = artistname + " & " + item["name"];
        }
        isplaying = decoded["is_playing"];
      });
    } else {
      setState(() {
        playerstat = false;
      });

      imageurl = null;
      currentmsd = 0.0;
      currentms = "0:00";
      durationms = "0:00";
      durationmsd = 0.0;
      songname = "Şarkı yok";
      artistname = "Şarkı yok";
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            Padding(
                padding: EdgeInsets.only(top: 40, left: 15),
                child: Row(children: [
                  AutoSizeText("Şu anda çalınan ",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontFamily: "Spotify",
                      )),
                ])),
            Padding(
              padding: EdgeInsets.only(top: 10, left: 10, right: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                    width: MediaQuery.of(context).size.width - 10,
                    height: 177,
                    color: Color(0xFF222222),
                    child: Row(children: [
                      Padding(
                          padding: EdgeInsets.only(left: 10),
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                  width: 130,
                                  height: 130,
                                  child: songimage()))),
                      Container(
                          width: MediaQuery.of(context).size.width - 160,
                          child: Padding(
                              padding: EdgeInsets.only(top: 50, left: 5),
                              child: Column(
                                children: [
                                  Padding(
                                      padding: EdgeInsets.only(left: 5),
                                      child: Column(children: [
                                        Align(
                                            alignment: Alignment.centerLeft,
                                            child: AutoSizeText(
                                              songname,
                                              maxLines: 1,
                                              style: TextStyle(
                                                  fontSize: 15,
                                                  fontFamily: "Spotify",
                                                  color: Colors.white),
                                            )),
                                        Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              artistname,
                                              maxLines: 1,
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  fontFamily: "Spotify",
                                                  color: Colors.white),
                                            ))
                                      ])),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(40),
                                      child: Container(
                                        width: 190,
                                        height: 10,
                                        child: Container(
                                            width: 500,
                                            child: ispremium
                                                ? SeekBar(
                                                    value: playerstat
                                                        ? (currentmsd /
                                                            durationmsd)
                                                        : 0,
                                                    progressColor:
                                                        Colors.green[800],
                                                    onStartTrackingTouch: () {
                                                      setState(() {});
                                                      proggrestimer.cancel();
                                                    },
                                                    onProgressChanged:
                                                        (double value) {
                                                      setState(() {
                                                        currentms = mstomn(
                                                            (value *
                                                                    durationmsd)
                                                                .toInt());
                                                        currentmsd =
                                                            value * durationmsd;
                                                      });
                                                    },
                                                    onStopTrackingTouch:
                                                        () async {
                                                      currentmsd =
                                                          currentmsd + 1000;
                                                      currentms = mstomn(
                                                          currentmsd.toInt());
                                                      var res = await http.put(
                                                          "https://api.spotify.com/v1/me/player/seek?position_ms=${currentmsd.toStringAsFixed(0)}",
                                                          headers: {
                                                            "Authorization":
                                                                " Bearer " +
                                                                    authtoken
                                                          });
                                                      print(res.body);
                                                      print(res.statusCode);

                                                      Future.delayed(
                                                          new Duration(
                                                              milliseconds:
                                                                  900), () {
                                                        setState(() {
                                                          starttimer();
                                                        });
                                                      });
                                                    },
                                                  )
                                                : LinearProgressIndicator(
                                                    value: currentmsd /
                                                        durationmsd,
                                                    valueColor:
                                                        new AlwaysStoppedAnimation<
                                                                Color>(
                                                            Colors.green[800]),
                                                    backgroundColor:
                                                        Colors.grey[800],
                                                  )),
                                      ),
                                    ),
                                  ),
                                  Row(children: [
                                    Padding(
                                        padding: EdgeInsets.only(
                                            right: 115, left: 6),
                                        child: Text(
                                          currentms,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12),
                                        )),
                                    Padding(
                                        padding: EdgeInsets.only(left: 18),
                                        child: Text(
                                          durationms,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12),
                                        )),
                                  ]),
                                  Padding(
                                    padding:
                                        EdgeInsets.only(bottom: 14, left: 21),
                                    child: Row(
                                      children: [
                                        IconButton(
                                            iconSize: 35,
                                            icon: Icon(
                                              Icons.skip_previous,
                                              color: ispremium
                                                  ? Colors.white
                                                  : Colors.grey,
                                            ),
                                            color: Colors.white,
                                            onPressed: () async {
                                              if (ispremium == true) {
                                                var res = await http.post(
                                                    "https://api.spotify.com/v1/me/player/previous",
                                                    headers: {
                                                      "Authorization":
                                                          " Bearer " + authtoken
                                                    });
                                                if (res.statusCode == 204) {
                                                  setState(() {
                                                    playback();
                                                  });
                                                }
                                              } else {
                                                Scaffold.of(context)
                                                    .showSnackBar(SnackBar(
                                                        content: Text(
                                                            "Lütfen Spotify Premium Satın alın",
                                                            style: TextStyle(
                                                                fontFamily:
                                                                    "Spotify",
                                                                color: Colors
                                                                    .white)),
                                                        duration: Duration(
                                                            seconds: 2)));
                                              }
                                            }),
                                        IconButton(
                                            iconSize: 40,
                                            icon: isplaying
                                                ? Icon(
                                                    Icons.pause_circle_filled,
                                                    color: Colors.white,
                                                  )
                                                : Icon(
                                                    Icons.play_circle_fill,
                                                    color: Colors.white,
                                                  ),
                                            color: Colors.white,
                                            onPressed: () async {
                                              if (isplaying == true) {
                                                await http.put(
                                                    "https://api.spotify.com/v1/me/player/pause",
                                                    headers: {
                                                      "Authorization":
                                                          " Bearer " + authtoken
                                                    });
                                                playback();
                                              } else {
                                                await http.put(
                                                    "https://api.spotify.com/v1/me/player/play",
                                                    headers: {
                                                      "Authorization":
                                                          " Bearer " + authtoken
                                                    });
                                                playback();
                                              }
                                            }),
                                        IconButton(
                                            iconSize: 35,
                                            icon: Icon(
                                              Icons.skip_next,
                                              color: ispremium
                                                  ? Colors.white
                                                  : Colors.grey,
                                            ),
                                            color: Colors.white,
                                            onPressed: () async {
                                              if (ispremium == true) {
                                                var res = await http.post(
                                                    "https://api.spotify.com/v1/me/player/next",
                                                    headers: {
                                                      "Authorization":
                                                          " Bearer " + authtoken
                                                    });
                                                print(res.body);
                                                if (res.statusCode == 204) {
                                                  playback();
                                                }
                                              } else {
                                                Scaffold.of(context)
                                                    .showSnackBar(SnackBar(
                                                        content: Text(
                                                            "Lütfen Spotify Premium Satın alın",
                                                            style: TextStyle(
                                                                fontFamily:
                                                                    "Spotify",
                                                                color: Colors
                                                                    .white)),
                                                        duration: Duration(
                                                            seconds: 2)));
                                              }
                                            }),
                                      ],
                                    ),
                                  ),
                                ],
                              )))
                    ])),
              ),
            ),
            Padding(
                padding: EdgeInsets.only(top: 15, left: 15),
                child: Row(children: [
                  AutoSizeText("En Son Çalınanlar ",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontFamily: "Spotify",
                      )),
                ])),
            ListView.separated(
              padding: EdgeInsets.only(top: 10),
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              primary: false,
              separatorBuilder: (context, index) => Divider(
                color: Color(0xFF1b1b1b),
                height: 5,
              ),
              itemCount: recentsngs.length,
              itemBuilder: (context, position) {
                var timedif = getdiff(recentsngs[position].playedat);
                return InkWell(
                    onTap: () async {
                      _advertService.showIntersitial();
                      var data = '{"uris":["${recentsngs[position].url}"]}';
                      var res = await http.put(
                          "https://api.spotify.com/v1/me/player/play",
                          headers: {
                            "Authorization": "Bearer " + authtoken,
                            "Content-Type": "application/json",
                            "charset": "utf-8"
                          },
                          body: data);
                      if (res.statusCode != 204) {
                        try {
                          SpotifySdk.play(spotifyUri: recentsngs[position].url);
                        } on PlatformException catch (e) {
                          await appconnection();
                          SpotifySdk.play(spotifyUri: recentsngs[position].url);
                        }
                      }

                      setState(() {});
                    },
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 75,
                          width: MediaQuery.of(context).size.width - 20,
                          color: Color(0xFF222222),
                          child: Wrap(children: [
                            SizedBox(
                                width: 50,
                                height: 70,
                                child: Padding(
                                    padding: EdgeInsets.only(top: 13),
                                    child: Align(
                                        alignment: Alignment.center,
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.history,
                                              size: 32,
                                              color: Colors.white,
                                            ),
                                            Text(
                                              timedif,
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13),
                                            )
                                          ],
                                        )))),
                            SizedBox(
                                height: 75,
                                width: 64,
                                child: Align(
                                    alignment: Alignment.center,
                                    child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          alignment: Alignment.center,
                                          width: 64,
                                          height: 64,
                                          child: Image.network(
                                              recentsngs[position].imagelink,
                                              width: 64,
                                              height: 64,
                                              fit: BoxFit.fill),
                                        )))),
                            Padding(
                                padding: EdgeInsets.only(left: 13),
                                child: SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width - 134,
                                    height: 75,
                                    child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          AutoSizeText(
                                              recentsngs[position].name,
                                              maxLines: 1,
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: "Spotify",
                                                  fontSize: 15)),
                                          AutoSizeText(
                                            recentsngs[position].artist,
                                            maxLines: 1,
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontFamily: "Spotify",
                                                fontSize: 12),
                                          )
                                        ])))
                          ]),
                        )));
              },
            )
          ],
        ));
  }
}

Future getrocoms() async {
  isactive = true;

  var timelimit = "short_term";
  switch (timerange3) {
    case 0:
      timelimit = "short_term";
      break;
    case 1:
      timelimit = "medium_term";
      break;
    case 2:
      timelimit = "long_term";
      break;
  }

  if (trackrecommended.isEmpty == true) {
    await rload0(timelimit);
  }

  if (trackrecommended2.isEmpty == true) {
    await rload1(timelimit);
  }
  if (trackrecommended3.isEmpty == true) {
    await rload3(timelimit);
  }
  if (timerangechange == true) {
    switch (secim) {
      case 0:
        await rload0(timelimit);
        trackstoload = trackrecommended;
        break;
      case 1:
        await rload1(timelimit);
        trackstoload = trackrecommended2;
        break;
      case 2:
        await rload3(timelimit);
        trackstoload = trackrecommended3;
        break;
    }
  }

  switch (secim) {
    case 0:
      trackstoload = trackrecommended;
      break;
    case 1:
      trackstoload = trackrecommended2;
      break;
    case 2:
      trackstoload = trackrecommended3;
      break;
  }

  print("done");
  isactive = false;
}

Future rload0(String timelimit) async {
  trackrecommended.clear();
  var res1 = await http.get(
      "https://api.spotify.com/v1/me/top/tracks?time_range=$timelimit&limit=3",
      headers: {"Authorization": "Bearer " + authtoken});
  var res2 = await http.get(
      "https://api.spotify.com/v1/me/top/artists?time_range=$timelimit&limit=2",
      headers: {"Authorization": "Bearer " + authtoken});
  var decoded1_ = json.decode(res1.body);
  var decoded2_ = json.decode(res2.body);
  var res3 = await http.get(
      "https://api.spotify.com/v1/recommendations?limit=50&seed_tracks=${decoded1_["items"][0]["id"]},${decoded1_["items"][1]["id"]},${decoded1_["items"][2]["id"]}&seed_artists=${decoded2_["items"][0]["id"]},${decoded2_["items"][1]["id"]}&target_energy=${energy / 100}&target_valence=${valance / 100}&target_tempo=${tempo / 100}&target_dance=${dance / 100}",
      headers: {"Authorization": "Bearer " + authtoken});
  var idlist = "";
  for (var item in json.decode(res3.body)["tracks"]) {
    if (idlist == "") {
      idlist = item["id"];
    } else {
      idlist = idlist + "%2C" + item["id"];
    }
  }
  var res4 = await http.get("https://api.spotify.com/v1/tracks?ids=" + idlist,
      headers: {"Authorization": "Bearer " + authtoken});
  int i = 0;
  for (var item in json.decode(res3.body)["tracks"]) {
    bool isfirst = true;
    var artst = "";
    for (var item in json.decode(res4.body)["tracks"][i]["artists"]) {
      if (isfirst == true) {
        artst = item["name"];
        isfirst = false;
      } else
        artst = artst + " & " + item["name"];
    }
    var tr = recomtrack(
        item["id"],
        json.decode(res4.body)["tracks"][i]["uri"],
        json.decode(res4.body)["tracks"][i]["name"],
        artst,
        json.decode(res4.body)["tracks"][i]["album"]["images"][0]["url"]);
    trackrecommended.add(tr);
    i++;
  }
}

Future rload1(String timelimit) async {
  trackrecommended2.clear();
  var res1 = await http.get(
      "https://api.spotify.com/v1/me/top/tracks?time_range=$timelimit&limit=5",
      headers: {"Authorization": "Bearer " + authtoken});
  var decoded_ = json.decode(res1.body)["items"];
  var res3 = await http.get(
      "https://api.spotify.com/v1/recommendations?limit=50&seed_tracks=${decoded_[0]["id"]},${decoded_[1]["id"]},${decoded_[2]["id"]},${decoded_[3]["id"]},${decoded_[4]["id"]}",
      headers: {"Authorization": "Bearer " + authtoken});
  var idlist = "";
  for (var item in json.decode(res3.body)["tracks"]) {
    if (idlist == "") {
      idlist = item["id"];
    } else {
      idlist = idlist + "%2C" + item["id"];
    }
  }
  var res4 = await http.get("https://api.spotify.com/v1/tracks?ids=" + idlist,
      headers: {"Authorization": "Bearer " + authtoken});
  int i = 0;
  for (var item in json.decode(res3.body)["tracks"]) {
    bool isfirst = true;
    var artst = "";
    for (var item in json.decode(res4.body)["tracks"][i]["artists"]) {
      if (isfirst == true) {
        artst = item["name"];
        isfirst = false;
      } else
        artst = artst + " & " + item["name"];
    }
    var tr = recomtrack(
        item["id"],
        json.decode(res4.body)["tracks"][i]["uri"],
        json.decode(res4.body)["tracks"][i]["name"],
        artst,
        json.decode(res4.body)["tracks"][i]["album"]["images"][0]["url"]);
    trackrecommended2.add(tr);
    i++;
  }
}

Future rload3(String timelimit) async {
  trackrecommended3.clear();
  var res2 = await http.get(
      "https://api.spotify.com/v1/me/top/artists?time_range=$timelimit&limit=5",
      headers: {"Authorization": "Bearer " + authtoken});
  var decoded_ = json.decode(res2.body)["items"];
  var res3 = await http.get(
      "https://api.spotify.com/v1/recommendations?limit=50&seed_artists=${decoded_[0]["id"]},${decoded_[1]["id"]},${decoded_[2]["id"]},${decoded_[3]["id"]},${decoded_[4]["id"]}",
      headers: {"Authorization": "Bearer " + authtoken});
  var idlist = "";
  for (var item in json.decode(res3.body)["tracks"]) {
    if (idlist == "") {
      idlist = item["id"];
    } else {
      idlist = idlist + "%2C" + item["id"];
    }
  }
  var res4 = await http.get("https://api.spotify.com/v1/tracks?ids=" + idlist,
      headers: {"Authorization": "Bearer " + authtoken});
  int i = 0;
  for (var item in json.decode(res3.body)["tracks"]) {
    bool isfirst = true;
    var artst = "";
    for (var item in json.decode(res4.body)["tracks"][i]["artists"]) {
      if (isfirst == true) {
        artst = item["name"];
        isfirst = false;
      } else
        artst = artst + " & " + item["name"];
    }
    var tr = recomtrack(
        item["id"],
        json.decode(res4.body)["tracks"][i]["uri"],
        json.decode(res4.body)["tracks"][i]["name"],
        artst,
        json.decode(res4.body)["tracks"][i]["album"]["images"][0]["url"]);
    trackrecommended3.add(tr);
    i++;
  }
}

class lib extends StatefulWidget {
  @override
  _lib createState() => _lib();
}

class _lib extends State<lib> {
  String dropdownval_ = "Son 1 ay";
  String dropdownval2_ = "Hepsi";
  @override
  void initState() {
    super.initState();
    if (isactive == false) getrocoms();
  }

  Future getrocoms_() async {
    isactive = true;

    var timelimit = "short_term";
    switch (timerange3) {
      case 0:
        timelimit = "short_term";
        break;
      case 1:
        timelimit = "medium_term";
        break;
      case 2:
        timelimit = "long_term";
        break;
    }

    if (trackrecommended.isEmpty == true) {
      await rload0(timelimit);
    }

    if (trackrecommended2.isEmpty == true) {
      await rload1(timelimit);
    }
    if (trackrecommended3.isEmpty == true) {
      await rload3(timelimit);
    }
    if (timerangechange == true) {
      switch (secim) {
        case 0:
          await rload0(timelimit);
          trackstoload = trackrecommended;
          break;
        case 1:
          await rload1(timelimit);
          trackstoload = trackrecommended2;
          break;
        case 2:
          await rload3(timelimit);
          trackstoload = trackrecommended3;
          break;
      }
    }

    switch (secim) {
      case 0:
        trackstoload = trackrecommended;
        break;
      case 1:
        trackstoload = trackrecommended2;
        break;
      case 2:
        trackstoload = trackrecommended3;
        break;
    }

    print("done");
    isactive = false;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            Align(
                alignment: Alignment.topLeft,
                child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Text("Şuna Göre Önerileri Göster",
                        style: TextStyle(
                            fontFamily: "Spotify",
                            fontSize: 21,
                            color: Colors.white)))),
            Padding(
                padding: EdgeInsets.only(top: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Theme(
                        data: Theme.of(context).copyWith(
                          canvasColor: Colors.black,
                        ),
                        child: Container(
                            width: 89,
                            child: DropdownButton<String>(
                              isExpanded: true,
                              dropdownColor: Colors.green[700],
                              value: dropdownval_,
                              icon: Icon(Icons.arrow_downward),
                              iconSize: 16,
                              elevation: 16,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontFamily: "Spotify"),
                              underline: Container(
                                height: 2,
                                color: Colors.green[800],
                              ),
                              onChanged: (String value) async {
                                _advertService.showIntersitial();
                                if (value == "Son 1 ay") {
                                  timerange3 = 0;
                                  timerangechange = true;
                                  await getrocoms_();
                                  setState(() {});
                                } else if (value == "Son 6 ay") {
                                  timerange3 = 1;
                                  timerangechange = true;
                                  await getrocoms_();
                                  setState(() {});
                                } else if (value == "Tüm Zamanlar") {
                                  timerange3 = 2;
                                  timerangechange = true;
                                  await getrocoms_();
                                  setState(() {});
                                }
                                setState(() {
                                  dropdownval_ = value;
                                  print(dropdownval_);
                                });
                              },
                              items: <String>[
                                'Son 1 ay',
                                'Son 6 ay',
                                'Tüm Zamanlar'
                              ].map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ))),
                    Text(
                      " içinde en çok dinlediğin ",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: "Spotify"),
                    ),
                    Theme(
                        data: Theme.of(context).copyWith(
                          canvasColor: Colors.black,
                        ),
                        child: Container(
                            child: DropdownButton<String>(
                          value: dropdownval2_,
                          dropdownColor: Colors.green[700],
                          icon: Icon(Icons.arrow_downward),
                          iconSize: 16,
                          elevation: 16,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontFamily: "Spotify"),
                          underline: Container(
                            height: 2,
                            width: 4,
                            color: Colors.green[800],
                          ),
                          onChanged: (String value) async {
                            if (value == "Şarkılar") {
                              secim = 1;
                              await getrocoms_();
                            } else if (value == "Sanatçılar") {
                              secim = 2;
                              await getrocoms_();
                            } else if (value == "Hepsi") {
                              secim = 0;
                              await getrocoms_();
                            }
                            setState(() {
                              dropdownval2_ = value;
                              print(dropdownval2_);
                            });
                          },
                          items: <String>['Şarkılar', 'Sanatçılar', 'Hepsi']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        )))
                  ],
                )),
            ListView.separated(
              padding: EdgeInsets.only(top: 10),
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              primary: false,
              separatorBuilder: (context, index) => Divider(
                color: Color(0xFF1b1b1b),
                height: 5,
              ),
              itemCount: trackstoload.length,
              itemBuilder: (context, position) {
                return InkWell(
                    onTap: () async {
                      _advertService.showIntersitial();
                      try {
                        var data = '{"uris":["${trackstoload[position].url}"]}';
                        var res = await http.put(
                            "https://api.spotify.com/v1/me/player/play",
                            headers: {
                              "Authorization": "Bearer " + authtoken,
                              "Content-Type": "application/json",
                              "charset": "utf-8"
                            },
                            body: data);
                        if (res.statusCode != 204) {
                          SpotifySdk.play(
                              spotifyUri: trackstoload[position].url);
                        }
                        await recentsongs();
                      } on PlatformException catch (e) {
                        appconnection();
                        var data = '{"uris":["${trackstoload[position].url}"]}';
                        var res = await http.put(
                            "https://api.spotify.com/v1/me/player/play",
                            headers: {
                              "Authorization": "Bearer " + authtoken,
                              "Content-Type": "application/json",
                              "charset": "utf-8"
                            },
                            body: data);
                        if (res.statusCode != 204) {
                          try {
                            SpotifySdk.play(
                                spotifyUri: trackstoload[position].url);
                          } catch (e) {
                            appconnection();
                            SpotifySdk.play(
                                spotifyUri: trackstoload[position].url);
                          }
                        }
                        await recentsongs();
                      }
                      setState(() {});
                    },
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 75,
                          width: MediaQuery.of(context).size.width - 20,
                          color: Color(0xFF222222),
                          child: Wrap(children: [
                            SizedBox(
                              width: 30,
                              height: 75,
                            ),
                            SizedBox(
                                height: 75,
                                width: 64,
                                child: Align(
                                    alignment: Alignment.center,
                                    child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          alignment: Alignment.center,
                                          width: 64,
                                          height: 64,
                                          child: Image.network(
                                              trackstoload[position].imagelink,
                                              width: 64,
                                              height: 64,
                                              fit: BoxFit.fill),
                                        )))),
                            Padding(
                                padding: EdgeInsets.only(left: 13),
                                child: SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width - 134,
                                    height: 75,
                                    child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          AutoSizeText(
                                              trackstoload[position].name,
                                              maxLines: 1,
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: "Spotify",
                                                  fontSize: 15)),
                                          AutoSizeText(
                                            trackstoload[position].artist,
                                            maxLines: 1,
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontFamily: "Spotify",
                                                fontSize: 12),
                                          )
                                        ])))
                          ]),
                        )));
              },
            )
          ],
        ));
  }
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return SplashScreen();
  }
}
