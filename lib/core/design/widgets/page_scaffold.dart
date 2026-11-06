import 'package:flutter/material.dart';
import '../../utils/context_extensions.dart';
import '../tokens/kera_colors.dart';

/// Safe-area, keyboard-dismissing page wrapper with optional pull-to-refresh.
class PageScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Future<void> Function()? onRefresh;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final EdgeInsetsGeometry padding;

  const PageScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.onRefresh,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: padding,
      child: body,
    );

    if (onRefresh != null) {
      content = RefreshIndicator(
        color: KeraColors.orange500,
        backgroundColor: context.cardBg,
        onRefresh: onRefresh!,
        child: content,
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: backgroundColor ?? context.scaffoldBg,
        appBar: appBar,
        body: SafeArea(child: content),
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      ),
    );
  }
}

