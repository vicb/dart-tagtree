part of core;

/// A Transaction renders one animation frame for one Root.
class Transaction extends _Mount {
  final Root root;
  final NextFrame frame;
  final EventDispatcher dispatcher;

  // What to do
  final View nextTop;
  final List<Widget> _widgetsToUpdate;

  // What was done
  final List<String> _unmountedFormPaths = [];
  final List<String> _unmountedPaths = [];
  final List<Widget> _updatedWidgets = [];

  Transaction(this.root, this.frame, this.dispatcher, this.nextTop, Iterable<Widget> widgetsToUpdate)
      : _widgetsToUpdate = new List.from(widgetsToUpdate);

  void run() {
    if (nextTop != null) {
      // Repace the entire tree.
      root._top = _updateRoot(root.path, root._top, nextTop);
    }

    // Sort ancestors ahead of children.
    _widgetsToUpdate.sort((a, b) => a.depth - b.depth);

    for (Widget w in _widgetsToUpdate) {
      update(w, null);
    }

    _finish();
  }

  void _finish() {
    for (Ref r in _mountedRefs) {
      frame.onRefMounted(r);
    }

    for (Elt form in _mountedForms) {
      frame.onFormMounted(root, form.path);
    }

    for (String path in _unmountedFormPaths) {
      frame.onFormUnmounted(path);
    }

    for (String path in _unmountedPaths) {
      frame.detachElement(path);
    }

    for (var w in _mountedWidgets) {
      w._didMount.add(true);
    }

    for (var w in _updatedWidgets) {
      w._didUpdate.add(true);
    }
  }

  // Returns the new top view.
  View _updateRoot(String path, View current, View next) {
    if (current == null) {
      StringBuffer html = new StringBuffer();
      mountView(next, html, path, 0);
      frame.mount(html.toString());
      return next;
    } else if (current.canUpdateTo(next)) {
      print("updating current view at ${path}");
      update(current, next);
      return current;
    } else {
      print("replacing current view ${path}");
      // Set the current element first because unmount clears the node cache
      frame.visit(path);
      current.unmount(this);

      var html = new StringBuffer();
      mountView(next, html, path, 0);
      frame.replaceElement(html.toString());
      return next;
    }
  }

  /// Updates a view in place.
  ///
  /// After the update, it should have the same props as nextVersion and any DOM changes
  /// needed should have been sent to nextFrame for rendering.
  ///
  /// If nextVersion is null, the props are unchanged, but a stateful view may apply any pending
  /// state.
  void update(View current, View nextVersion) {
    if (current is Text) {
      _updateText(current, nextVersion);
    } else if (current is Widget) {
      _updateWidget(current, nextVersion);
    } else if (current is Elt) {
      current.update(nextVersion, this);
    } else {
      throw "cannot update: ${current.runtimeType}";
    }
  }

  void _updateText(Text current, Text next) {
    if (next == null || current.value == next.value) {
      return; // no internal state to update
    }
    current.value = next.value;
    frame
        ..visit(current.path)
        ..setInnerText(current.value);
  }

  void _updateWidget(Widget current, Widget next) {
    View newShadow = current._updateAndRender(next);

    if (current._shadow.canUpdateTo(newShadow)) {
      update(current._shadow, newShadow);
    } else {
      mountReplacementShadow(current, newShadow);
      current._shadow = newShadow;
    }
    if (current._didUpdate.hasListener) {
      _updatedWidgets.add(current);
    }
  }

  /// Updates DOM attributes and event handlers of an Elt.
  void _updateDomProperties(String eltPath, Map<Symbol, dynamic> oldProps, Map<Symbol, dynamic> newProps) {
    frame.visit(eltPath);

    // Delete any removed props
    for (Symbol key in oldProps.keys) {
      if (newProps.containsKey(key)) {
        continue;
      }

      if (dispatcher.isHandlerKey(key)) {
        dispatcher.removeHandler(key, eltPath);
      } else if (_allAtts.containsKey(key)) {
        frame.removeAttribute(_allAtts[key]);
      }
    }

    // Update any new or changed props
    for (Symbol key in newProps.keys) {
      var oldVal = oldProps[key];
      var newVal = newProps[key];
      if (oldVal == newVal) {
        continue;
      }

      if (dispatcher.isHandlerKey(key)) {
        dispatcher.setHandler(key, eltPath, newVal);
      } else if (_allAtts.containsKey(key)) {
        String name = _allAtts[key];
        String val = _makeDomVal(key, newVal);
        frame.setAttribute(name, val);
      }
    }
  }
}