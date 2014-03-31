// Original:
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Ported to ViewTree by Brian Slesinsky

library sunflower;

import 'dart:html';
import 'dart:math';
import 'package:viewtree/core.dart';
import 'package:viewtree/browser.dart';

const String ORANGE = "orange";
const int SEED_RADIUS = 2;
const int SCALE_FACTOR = 4;
const num TAU = PI * 2;
const int MAX_D = 300;
const num centerX = MAX_D / 2;
const num centerY = centerX;

final num PHI = (sqrt(5) + 1) / 2;

final $ = new Tags();

final Sunflower = new TagDef(
  widget: (_) => new SunflowerWidget()
);

void main() {
  root("#sunflower").mount(Sunflower());
}

class SunflowerWidget extends Widget<SunflowerState> {
  final _canvas = new ElementRef<CanvasElement>();

  SunflowerWidget() : super({}) {
    didMount.listen((_) => draw());
    didUpdate.listen((_) => draw());
  }

  get firstState => new SunflowerState();

  void onChange(ChangeEvent e) {
    nextState.seeds = int.parse(e.value);
  }

  @override
  View render() {
    return $.Div(inner: [

        $.Div(id: "container", inner: [
            $.Canvas(width: 300, height: 300, clazz: "center", ref: _canvas),
            $.Form(clazz: "center", inner: [
                $.Input(type: "range", max: 1000, value: state.seeds, onChange: onChange)
            ]),
            $.Img(src: "math.png", width: "350px", height: "42px", clazz: "center")
        ]),

        $.Footer(inner: [
            $.P(id: "notes", inner: "${state.seeds} seeds")
        ]),
    ]);
  }

  /// Draw the complete figure for the current number of seeds.
  void draw() {
    CanvasRenderingContext2D context = _canvas.elt.context2D;
    int seeds = state.seeds;
    context.clearRect(0, 0, MAX_D, MAX_D);
    for (var i = 0; i < seeds; i++) {
      final num theta = i * TAU / PHI;
      final num r = sqrt(i) * SCALE_FACTOR;
      drawSeed(context, centerX + r * cos(theta), centerY - r * sin(theta));
    }
  }

  /// Draw a small circle representing a seed centered at (x,y).
  void drawSeed(CanvasRenderingContext2D context, num x, num y) {
    context..beginPath()
           ..lineWidth = 2
           ..fillStyle = ORANGE
           ..strokeStyle = ORANGE
           ..arc(x, y, SEED_RADIUS, 0, TAU, false)
           ..fill()
           ..closePath()
           ..stroke();
  }
}

class SunflowerState extends State {
  int seeds = 500;

  @override
  State clone() =>
      new SunflowerState()
          ..seeds = seeds;
}


