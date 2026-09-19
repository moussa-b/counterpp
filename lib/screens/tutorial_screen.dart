import 'package:counter/widgets/tutorial_page.dart';
import 'package:flutter/material.dart';
import 'package:counter/l10n/app_localizations.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class TutorialScreen extends StatefulWidget {
  final void Function()? continueCallback;

  const TutorialScreen({super.key, this.continueCallback});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final _controller = PageController();
  late bool _isLastPage = false;
  final double horizontalPadding = 20;
  final double topPadding = 30;
  final double bottomPadding = 20;
  final double buttonMinHeight = 56;
  final double buttonHorizontalPadding = 32;
  final TextStyle buttonTextStyle = const TextStyle(fontSize: 18);
  final List<Widget> pages = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {
      String currentLocale = Localizations.localeOf(context).languageCode;
      if (currentLocale != 'en' && currentLocale != 'fr') {
        currentLocale = 'en';
      }
      final Color color = Theme.of(context).primaryColor.withValues(alpha: 0.5);
      pages.addAll([
        TutorialPage(
          subtitle: AppLocalizations.of(context)!.tutorialMsg1,
          color: color,
          image: 'assets/images/tutorial/tutorial1_$currentLocale.png',
        ),
        TutorialPage(
          subtitle: AppLocalizations.of(context)!.tutorialMsg2,
          color: color,
          image: 'assets/images/tutorial/tutorial2_$currentLocale.png',
        ),
        TutorialPage(
          subtitle: AppLocalizations.of(context)!.tutorialMsg3,
          color: color,
          image: 'assets/images/tutorial/tutorial3_$currentLocale.png',
        ),
        TutorialPage(
          subtitle: AppLocalizations.of(context)!.tutorialMsg4,
          color: color,
          image: 'assets/images/tutorial/tutorial4_$currentLocale.png',
        ),
      ]);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSkip() => _controller.jumpToPage(pages.length);

  void _onNext() => _controller.nextPage(
    duration: const Duration(milliseconds: 350),
    curve: Curves.easeIn,
  );

  void _onContinue() {
    widget.continueCallback != null
        ? widget.continueCallback!()
        : Navigator.pop(context);
  }

  Widget _getPageButtons() {
    // Both sides are Flexible and both labels can ellipsize. The buttons are
    // sized by their text, so a longer translation than English used to push
    // the row past the screen edge: "Suivant" and "Passer" overflowed by 5px
    // at 390dp, and more on a 360dp phone.
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Padding(
            padding: EdgeInsets.only(
              left: horizontalPadding,
              bottom: bottomPadding,
            ),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: TextButton(
                onPressed: _onSkip,
                child: Text(
                  AppLocalizations.of(context)!.skip,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: buttonTextStyle.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
        Flexible(
          child: Padding(
            padding: EdgeInsets.only(
              right: horizontalPadding,
              bottom: bottomPadding,
            ),
            child: Align(
              alignment: Alignment.bottomRight,
              child: SizedBox(
                height: buttonMinHeight,
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: _onNext,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: buttonHorizontalPadding,
                      right: buttonHorizontalPadding,
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.next,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: buttonTextStyle.copyWith(color: Colors.black),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _getLastPageButtons() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(
          left: horizontalPadding,
          right: horizontalPadding,
          bottom: bottomPadding,
        ),
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: Colors.white,
            minimumSize: Size.fromHeight(buttonMinHeight),
          ),
          onPressed: _onContinue,
          child: Text(
            AppLocalizations.of(context)!.start,
            style: buttonTextStyle,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color color = Theme.of(context).primaryColor.withValues(alpha: 0.5);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.5),
        toolbarHeight: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: color,
              child: Padding(
                padding: EdgeInsets.only(
                  top: topPadding,
                  bottom: bottomPadding,
                ),
                child: Center(
                  child: SmoothPageIndicator(
                    controller: _controller,
                    count: pages.length,
                    effect: SlideEffect(
                      dotColor: Colors.white.withAlpha(77),
                      activeDotColor: Colors.white,
                    ),
                    onDotClicked: (index) => _controller.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeIn,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                onPageChanged: (index) {
                  setState(() {
                    _isLastPage = index == pages.length - 1;
                  });
                },
                controller: _controller,
                children: pages,
              ),
            ),
            Container(
              color: color,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _isLastPage ? _getLastPageButtons() : _getPageButtons(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
