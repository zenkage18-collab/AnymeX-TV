
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Small utilities to make widgets focusable and respond to D-Pad/remote input.

typedef OnTvActivate = void Function();

class TvFocusable extends StatefulWidget {
  final Widget child;
  final OnTvActivate? onActivate;
  final bool autofocus;
  final EdgeInsets padding;
  const TvFocusable({Key? key, required this.child, this.onActivate, this.autofocus=false, this.padding = EdgeInsets.zero}) : super(key: key);

  @override
  _TvFocusableState createState() => _TvFocusableState();
}

class _TvFocusableState extends State<TvFocusable> {
  late FocusNode _focusNode;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(canRequestFocus: true, descendantsAreFocusable: false);
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  bool _handleKey(FocusNode node, RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.gameButtonA || key == LogicalKeyboardKey.space) {
        widget.onActivate?.call();
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: Focus(
        focusNode: _focusNode,
        onKey: (_, event) => KeyEventResult.handledWhen(_handleKey(_focusNode, event)),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 120),
            decoration: BoxDecoration(
              boxShadow: _focusNode.hasFocus || _hovered ? [BoxShadow(blurRadius: 8, color: Colors.black26, offset: Offset(0,2))] : null,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// A simple button that works with remote focus and activation.
class TvButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;
  final EdgeInsets padding;
  final bool autofocus;
  const TvButton({Key? key, required this.child, required this.onPressed, this.padding = const EdgeInsets.all(6), this.autofocus=false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      autofocus: autofocus,
      padding: padding,
      onActivate: onPressed,
      child: GestureDetector(
        onTap: onPressed,
        child: Semantics(button: true, child: child),
      ),
    );
  }
}

/// Wrap your MaterialApp with this to enable TV-friendly shortcuts and traversal.
Widget wrapWithTvSupport(Widget app) {
  return FocusTraversalGroup(
    policy: ReadingOrderTraversalPolicy(),
    child: Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.space): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.gameButtonA): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.gameButtonB): const DoNothingAndStopPropagationIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (intent) {
            // Default ActivateIntent handled by focused widgets.
            return null;
          }),
        },
        child: FocusScope(
          debugLabel: 'tv_root_scope',
          child: app,
        ),
      ),
    ),
  );
}
