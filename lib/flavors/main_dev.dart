import '../bootstrap.dart';
import '../core/config/app_config.dart';
import '../core/config/environment.dart';

/// Dev runs against a locally-hosted API.
///
/// `useMockData: false` is what puts the app on real repositories — with it
/// true, `bootstrap` applies `mockOverrides()` and every wired endpoint is
/// bypassed, however correct the repository is.
///
/// **Base URL.** The iOS simulator shares the Mac's network stack, so
/// `localhost` reaches the host process directly. Two things follow from that:
///
///   * The port is the ASP.NET **https** profile from the host's
///     `launchSettings.json` — check it there if requests don't land.
///   * The dev certificate is not in the simulator's trust store even after
///     `dotnet dev-certs https --trust`, so `ApiClient` accepts it for loopback
///     hosts in debug dev builds only. Plain `http://localhost:<port>` works
///     too — `Info.plist` allows local networking.
///
/// Other targets: Android emulator → `http://10.0.2.2:<port>`; a physical
/// device → the Mac's LAN IP, with the host bound to `0.0.0.0` rather than
/// `localhost`.
Future<void> main() => bootstrap(
      AppConfig(
        environment: Environment.dev,
        appName: 'مهندس (Dev)',
        apiBaseUrl: 'https://localhost:7199',
        enableLogging: true,
        useMockData: false,
        // No Bunny credentials here any more. The storage zone — name, write
        // password, region endpoint — comes from
        // `GET /api/social/Storage/Zone`, so it is per tenant and rotatable
        // without an app release. Fill it in on the server (socialmedia
        // .StorageSettings); until a row exists the photo control stays hidden
        // and registration simply sends no imageUrl.
        //
        // What may stay here is the public pull-zone URL, which is only ever
        // used to READ. Set it and photos already on a profile keep rendering
        // before the zone lands, and on a host whose row is not in yet:
        //   cdnBaseUrl: 'https://<pull-zone>.b-cdn.net',
      ),
    );
