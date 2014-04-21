/**
 * This library includes all the shared code in the framework.
 *
 * To mount a tag tree in a browser, you also need package:viewtree/browser.dart.
 * To handle sessions on the server, you also need package:viewtree/server.dart.
 */
library core;

import 'dart:async' show Stream, StreamController, StreamSink;
import 'dart:convert';

part 'src/core/codec.dart';
part 'src/core/debug.dart';
part 'src/core/elt.dart';
part 'src/core/event.dart';

part 'src/core/html.dart';
part 'src/core/json.dart';
part 'src/core/state.dart';
part 'src/core/tag.dart';
part 'src/core/template.dart';
part 'src/core/text.dart';
part 'src/core/widget.dart';
