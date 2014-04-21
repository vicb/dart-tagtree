part of core;

/// A Tag generalizes an HTML element to also include templates and widgets. Tags
/// form a tag tree similar to how HTML elements form a tree.
///
/// Each Tag has a TagDef, which determines the tag's behavior when a tag tree is rendered.
///
/// Its props are similar to HTML attributes but instead of storing a string, they sometimes
/// store arbitrary JSON or callback functions.
///
/// The children of a tag (if any) are in its "inner" prop.
///
/// To construct a Tag that renders as an HTML element, call the appropriate method on
/// [htmlTags].
///
/// To create a custom tag, first use [defineTemplate] or [defineWidget] to create
/// a TagDef, then call it with the appropriate named parameters for its props.
class Tag implements Jsonable {
  final TagDef def;
  final Map<Symbol, dynamic> props;

  Tag._raw(this.def, this.props);

  String get jsonTag => def.getJsonTag(this);
}

/// A TagDef acts as a tag constructor and also determines the behavior of the
/// tags it creates. TagDefs shouldn't be created directly; instead use
/// [defineTemplate] or [defineWidget].
abstract class TagDef {

  const TagDef();

  Tag makeTag(Map<Symbol, dynamic> props) {
    return new Tag._raw(this, props);
  }

  /// Subclass hook to make tags encodable as tagged JSON.
  /// By default, they aren't encodable.
  String getJsonTag(Tag tag) => null;

  // Implement call() with any named arguments.
  noSuchMethod(Invocation inv) {
    if (inv.isMethod && inv.memberName == #call) {
      if (!inv.positionalArguments.isEmpty) {
        throw "position arguments not supported for tags";
      }
      return makeTag(inv.namedArguments);
    }
    return super.noSuchMethod(inv);
  }
}

/// The internal constructor for tags representing HTML elements.
///
/// To construct a Tag, use [htmlTags] instead of calling this directly.
class EltDef extends TagDef {
  final String tagName;

  EltDef._raw(this.tagName);

  @override
  Tag makeTag(Map<Symbol, dynamic> props) {
    for (Symbol key in props.keys) {
      if (!_htmlPropNames.containsKey(key)) {
        throw "property not supported: ${key}";
      }
    }

    var inner = props[#inner];
    assert(inner == null || inner is String || inner is Tag || inner is Iterable);
    assert(inner == null || props[#innerHtml] == null);
    assert(props[#value] == null || props[#defaultValue] == null);

    return new Tag._raw(this, props);
  }

  @override
  String getJsonTag(Tag tag) => tagName;
}

/// Creates tags that are rendered by expanding a template.
/// To construct, use [defineTemplate].
class TemplateDef extends TagDef {
  final ShouldUpdateFunc shouldUpdate;
  final Function _renderFunc;

  TemplateDef._raw(ShouldUpdateFunc shouldUpdate, Function render) :
    this.shouldUpdate = shouldUpdate == null ? _alwaysUpdate : shouldUpdate,
    this._renderFunc = render {
    assert(render != null);
  }

  Tag render(Map<Symbol, dynamic> props) {
    return Function.apply(_renderFunc, [], props);
  }

  static _alwaysUpdate(p, next) => true;
}

/// Creates tags that are rendered as a Widget.
/// To construct, use [defineWidget].
class WidgetDef extends TagDef {
  final CreateWidgetFunc createWidget;
  const WidgetDef._raw(this.createWidget);
}

