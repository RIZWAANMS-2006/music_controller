import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:Rusic/music_player/online_screens/online_screen.dart';
import 'package:Rusic/music_player/location_screens/location_screen.dart';
import 'package:Rusic/managers/database_manager.dart';
import 'package:Rusic/managers/settings_manager.dart';
import 'package:Rusic/ui/media_ui.dart';
import 'package:Rusic/managers/ui_manager.dart';
import 'package:Rusic/music_player/playlists_tab.dart';

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: setAppBarColor(context),
        border: Border(
          bottom: BorderSide(color: setAppBarBorderColor(context)),
        ),
      ),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return false;
  }
}

// Creating "Rusic"
class Library extends StatefulWidget {
  const Library({super.key});

  @override
  State<Library> createState() => LibraryState();
}

// Creating "Music Controller State Class"
class LibraryState extends State<Library>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: SettingsManager.getLastLibraryTab,
    );

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        SettingsManager.setLastLibraryTab(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          NestedScrollView(
            physics: const BouncingScrollPhysics(),
            headerSliverBuilder: (context, innerbox) {
              return [
                CupertinoSliverNavigationBar(
                  largeTitle: const Text("Library"),
                  middle: const Text("Library"),
                  alwaysShowMiddle: false,
                  backgroundColor: setAppBarColor(context),
                  stretch: true,
                  border: null,
                ),
                SliverPersistentHeader(
                  floating: false,
                  pinned: true,
                  delegate: _StickyTabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      tabAlignment: TabAlignment.start,
                      isScrollable: true,
                      indicatorColor: Colors.red,
                      tabs: const [
                        SizedBox(width: 100, child: Tab(text: "Online")),
                        SizedBox(width: 100, child: Tab(text: "Favourites")),
                        SizedBox(width: 100, child: Tab(text: "Playlists")),
                        SizedBox(width: 100, child: Tab(text: "Locations")),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: Stack(
              children: [
                TabBarView(
                  controller: _tabController,
                  children: [
                    const OnlineScreen(),
                    AnimatedBuilder(
                      animation: DatabaseManager.instance,
                      builder: (context, _) {
                        return OnlineMediaUI(
                          title: "Favorites",
                          showMusicController: true,
                          emptyMessage: "No Favorite Yet...",
                          songsFuture: DatabaseManager.instance
                              .getAllFavoriteSongs(),
                        );
                      },
                    ),
                    const PlaylistsTab(),
                    const LocationsTab(),
                  ],
                ),
                Positioned(
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: 100,
                      width: MediaQuery.of(context).size.width,
                      // decoration: BoxDecoration(
                      //   gradient: LinearGradient(
                      //     colors: [
                      //       Theme.of(
                      //         context,
                      //       ).scaffoldBackgroundColor.withValues(alpha: 0.0),
                      //       Theme.of(
                      //         context,
                      //       ).scaffoldBackgroundColor.withValues(alpha: 0.8),
                      //       Theme.of(context).scaffoldBackgroundColor,
                      //     ],
                      //     begin: Alignment.topCenter,
                      //     end: Alignment.bottomCenter,
                      //   ),
                      // ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
