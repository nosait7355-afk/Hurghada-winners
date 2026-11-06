// Breakpoints for the Web responsive architecture (Desktop/Tablet/Mobile
// shells). Android and Windows are unaffected — Windows is a separate project,
// and Android always falls in the Mobile range below since native phone
// viewports are far under kTabletBreakpoint.
const double kTabletBreakpoint = 700;
const double kDesktopBreakpoint = 1200;

enum ScreenTier { mobile, tablet, desktop }

ScreenTier screenTierOf(double width) {
  if (width >= kDesktopBreakpoint) return ScreenTier.desktop;
  if (width >= kTabletBreakpoint) return ScreenTier.tablet;
  return ScreenTier.mobile;
}
