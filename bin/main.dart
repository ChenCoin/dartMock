import 'dart:convert';
import 'dart:io';
import 'package:http_server/http_server.dart' show VirtualDirectory;

void main(List<String> arguments) {
  var config = json.decode(File("config.json").readAsStringSync());
  int port = int.parse(config["port"]);
  String staticDir = Platform.script.resolve(config["static"]).toFilePath();
  String prefix = config["prefix"];
  List<dynamic> mockData = config["data"];

  print("server run on port: " + port.toString());
  print("staticDir: " + staticDir);
  print("prefix: " + prefix);

  var virDir = new VirtualDirectory(staticDir)..allowDirectoryListing = true;
  virDir.directoryHandler = (dir, request) {
    var indexUri = new Uri.file(dir.path).resolve('index.html');
    virDir.serveFile(new File(indexUri.toFilePath()), request);
  };

  HttpServer.bind(InternetAddress.loopbackIPv4, port).then((server) {
    server.listen((request) {
      print("request: " + request.uri.path);
      if (request.uri.path.startsWith(prefix)) {
        var match = false;
        for (Map<String, dynamic> item in mockData) {
          if ("/api" + item["path"] == request.uri.path) {
            String result = item["result"];
            if (result != null) {
              request.response
                ..write(result)
                ..close();
              match = true;
              break;
            }
          }
        }
        if (!match) {
          request.response
            ..write("404")
            ..close();
        }
      } else
        virDir.serveRequest(request);
    });
  });
}
