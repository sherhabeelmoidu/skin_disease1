import 'package:flutter/material.dart';
import 'package:skin_disease1/utils/responsive_helper.dart';

/// Example of how to use ResponsiveHelper in your screens
/// This is a reference implementation showing best practices

class ResponsiveExampleScreen extends StatelessWidget {
  const ResponsiveExampleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Responsive Example'),
      ),
      body: SingleChildScrollView(
        // Use responsive padding
        padding: ResponsiveHelper.getScreenPadding(context),
        child: Center(
          // Constrain content width on larger screens
          child: Container(
            constraints: BoxConstraints(
              maxWidth: ResponsiveHelper.getMaxWidth(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Responsive text
                Text(
                  'Responsive Title',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 24),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsivePadding(context)),
                
                // Responsive grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: ResponsiveHelper.getGridCrossAxisCount(context),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemCount: 8,
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Item ${index + 1}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                SizedBox(height: ResponsiveHelper.getResponsivePadding(context)),
                
                // Conditional layout based on device type
                if (ResponsiveHelper.isMobile(context))
                  _buildMobileLayout(context)
                else if (ResponsiveHelper.isTablet(context))
                  _buildTabletLayout(context)
                else
                  _buildDesktopLayout(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        Text('Mobile Layout'),
        // Mobile-specific widgets
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text('Tablet Layout - Left')),
        Expanded(child: Text('Tablet Layout - Right')),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 2, child: Text('Desktop Layout - Main')),
        Expanded(flex: 1, child: Text('Desktop Layout - Sidebar')),
      ],
    );
  }
}

/// Best Practices for Responsive Design in Flutter:
/// 
/// 1. Always use MediaQuery or ResponsiveHelper for screen-dependent values
/// 2. Use Expanded/Flexible widgets instead of fixed widths
/// 3. Wrap scrollable content in SingleChildScrollView
/// 4. Use LayoutBuilder for complex adaptive layouts
/// 5. Test on multiple screen sizes (small phone, large phone, tablet)
/// 6. Ensure minimum touch target size of 48x48 dp
/// 7. Use SafeArea to handle notches and system UI
/// 8. Handle text overflow with maxLines and overflow properties
/// 9. Use AspectRatio for maintaining proportions
/// 10. Consider orientation changes (portrait/landscape)
