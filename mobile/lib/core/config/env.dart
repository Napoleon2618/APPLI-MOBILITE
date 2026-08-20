import 'package:envied/envied.dart';

part 'env.g.dart';

/// Reads the Supabase URL and anon key from the `.env` file at build time.
///
/// `.env` is never committed (see `.gitignore`); `.env.example` documents
/// the expected keys. Values are compiled into the binary by `envied`, not
/// read at runtime, so there is no secret bundled as a plain asset file.
@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'SUPABASE_URL')
  static const String supabaseUrl = _Env.supabaseUrl;

  @EnviedField(varName: 'SUPABASE_ANON_KEY')
  static const String supabaseAnonKey = _Env.supabaseAnonKey;
}
