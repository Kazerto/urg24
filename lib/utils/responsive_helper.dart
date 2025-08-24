import 'package:flutter/material.dart';

class ResponsiveHelper {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }
  
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= 768 && 
           MediaQuery.of(context).size.width < 1024;
  }
  
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }
  
  static bool isWeb() {
    return identical(0, 0.0) == false; // Simple web detection
  }
  
  static double getMaxWidth(BuildContext context) {
    if (isMobile(context)) return double.infinity;
    if (isTablet(context)) return 600;
    return 400; // Desktop - center content
  }
  
  static EdgeInsets getScreenPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0);
    } else {
      // Desktop - center content with side margins
      double sideMargin = (MediaQuery.of(context).size.width - 400) / 2;
      return EdgeInsets.symmetric(
        horizontal: sideMargin > 0 ? sideMargin : 32.0,
        vertical: 32.0,
      );
    }
  }
}

// Widget wrapper pour centrer le contenu sur web/desktop
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  
  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context)) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth ?? ResponsiveHelper.getMaxWidth(context),
          ),
          child: child,
        ),
      );
    }
    
    return child;
  }
}