import 'package:flutter/material.dart';
import 'package:community/features/more/presentation/pages/more_page.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  /// If true (the default), and [leading] is null, Flutter will show
  /// a back button when there is something to pop.
  final bool automaticallyImplyLeading;

  final Widget? leading;

  final List<Widget>? actions;

  final bool showSettingsButton;

  const CustomAppBar({
    super.key,
    required this.title,
    this.automaticallyImplyLeading = true,
    this.leading,
    this.actions,
    this.showSettingsButton = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    // If the user supplied a leading widget, use it.
    // Otherwise, if we’re allowed to imply a leading and Navigator.canPop,
    // show the default back button.
    Widget? resolvedLeading = leading;
    if (resolvedLeading == null &&
        automaticallyImplyLeading &&
        Navigator.canPop(context)) {
      final backButtonColor = Theme.of(context).scaffoldBackgroundColor;
      resolvedLeading = BackButton(
        color: backButtonColor,
      );
    }

    // Prepare actions, including the settings button if requested
    List<Widget> finalActions = List.from(actions ?? []);
    if (showSettingsButton) {
      finalActions.add(
        IconButton(
          icon: Icon(
            Icons.settings,
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          tooltip: 'Settings',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MorePage()),
            );
          },
        ),
      );
    }

    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
      ),
      backgroundColor: Theme.of(context).primaryColor,
      automaticallyImplyLeading: false,
      leading: resolvedLeading,
      actions: finalActions,
    );
  }
}
