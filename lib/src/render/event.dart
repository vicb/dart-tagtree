part of render;

/// Contains all the handlers for one Root.
class _HandlerMap {
  // A multimap from (event type, path) to the handler to call.
  final _handlers = <String, Map<String, dynamic>> {};

  getHandler(String typeName, String path) {
    _handlers.putIfAbsent(typeName, () => {});
    return _handlers[typeName][path];
  }

  void setHandler(String typeName, String path, var handler) {
    if (handler == null) {
      removeHandler(typeName, path);
      return;
    }
    assert(handler is Function || handler is RemoteFunction);
    _handlers.putIfAbsent(typeName, () => {});
    _handlers[typeName][path] = handler;
  }

  void removeHandler(String typeName, String path) {
    if (_handlers.containsKey(typeName)) {
      _handlers[typeName].remove(path);
    }
  }

  void removeHandlersForPath(String path) {
    for (String key in _handlers.keys) {
      Map m = _handlers[key];
      m.remove(path);
    }
  }
}

bool _inEvent = false;

/// Calls any event handlers in this tree.
/// On return, there may be some dirty nodes to be re-rendered.
/// Note: nodes may also change state outside any event handler;
/// for example, due to a timer.
/// TODO: bubbling. For now, just exact match.
void _dispatch(HandlerEvent e, _HandlerMap handlers) {
  if (_inEvent) {
    // React does this too; see EVENT_SUPPRESSION
    print("ignored ${e.typeName} received while processing another event");
    return;
  }
  _inEvent = true;
  try {
    if (e.elementPath != null) {
      var handler = handlers.getHandler(e.typeName, e.elementPath);
      if (handler != null) {
        debugLog("\n### ${e.typeName}");
        handler(e);
      } else {
        debugLog("\n (${e.typeName})");
      }
    } else {
      debugLog("\n (${e.typeName})");
    }
  } finally {
    _inEvent = false;
  }
}