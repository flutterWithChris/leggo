import 'dart:async';

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:leggo/bloc/place/edit_places_bloc.dart';
import 'package:leggo/bloc/saved_categories/bloc/saved_lists_bloc.dart';
import 'package:leggo/bloc/saved_places/bloc/saved_places_bloc.dart';
import 'package:leggo/cubit/lists/list_sort_cubit.dart';
import 'package:leggo/globals.dart';
import 'package:leggo/model/place.dart';
import 'package:leggo/model/place_list.dart';
import 'package:leggo/model/user.dart';
import 'package:leggo/view/widgets/list_page/list_page_appbar.dart';
import 'package:leggo/view/widgets/main_bottom_navbar.dart';
import 'package:leggo/view/widgets/places/add_place_card.dart';
import 'package:leggo/view/widgets/places/blank_place_card.dart';
import 'package:leggo/view/widgets/places/place_card.dart';
import 'package:leggo/view/widgets/places/search_places_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

import '../widgets/list_page/button_bars.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  List<Widget> rows = [];
  List<PlaceCard> placeCards = [];
  late final ScrollController mainScrollController;
  final StreamController<int> controller = StreamController.broadcast();
  final DraggableScrollableController draggableScrollableController =
      DraggableScrollableController();
  int selectionType = 1;
  final GlobalKey _addPlaceShowcase = GlobalKey();
  final GlobalKey _checklistShowcase = GlobalKey();
  final GlobalKey _randomWheelShowcase = GlobalKey();
  final GlobalKey _inviteCollaboratorShowcase = GlobalKey();
  final GlobalKey _visitedFilterShowcase = GlobalKey();

  @override
  void initState() {
    mainScrollController = ScrollController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    BuildContext? buildContext;
    List<Place> selectedPlaces = context.watch<EditPlacesBloc>().selectedPlaces;
    return FutureBuilder<bool?>(
        future: getShowcaseStatus('categoryPageShowcaseComplete'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              (snapshot.data == null || snapshot.data == false)) {
            WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
              await Future.delayed(const Duration(milliseconds: 400));
              if (ShowCaseWidget.of(context).mounted == false) {
                ShowCaseWidget.of(buildContext!).startShowCase([
                  _addPlaceShowcase,
                  _visitedFilterShowcase,
                  _inviteCollaboratorShowcase,
                  _randomWheelShowcase,
                  _checklistShowcase
                ]);
              }
            });
          }
          return ShowCaseWidget(onFinish: () async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            prefs.setBool('categoryPageShowcaseComplete', true);
          }, builder: Builder(
            builder: (context) {
              buildContext = context;
              return Scaffold(
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.endDocked,
                bottomNavigationBar: MainBottomNavBar(),
                floatingActionButton: Showcase(
                  targetBorderRadius: BorderRadius.circular(50),
                  targetPadding: const EdgeInsets.all(8.0),
                  key: _addPlaceShowcase,
                  description: 'Search & add places with this button!',
                  child: FloatingActionButton(
                    shape: const StadiumBorder(),
                    // backgroundColor: Theme.of(context).primaryColor.withOpacity(0.5),
                    child: const Icon(Icons.add_location_alt_outlined),
                    onPressed: () async {
                      await showModalBottomSheet(
                          backgroundColor: Theme.of(context)
                              .scaffoldBackgroundColor
                              .withOpacity(0.8),
                          isScrollControlled: true,
                          context: context,
                          builder: (context) {
                            return const SearchPlacesSheet();
                          });
                    },
                  ),
                ),
                body: BlocBuilder<SavedPlacesBloc, SavedPlacesState>(
                  builder: (context, state) {
                    if (state is SavedPlacesFailed) {
                      return const Center(
                        child: Text('Error Loading List!'),
                      );
                    }

                    if (state is SavedPlacesLoaded ||
                        state is SavedPlacesUpdated ||
                        state is SavedPlacesLoading) {
                      User? listOwner =
                          context.watch<SavedListsBloc>().state.listOwner;
                      PlaceList? currentPlaceList =
                          context.watch<SavedListsBloc>().state.placeList;
                      List<User>? contributors =
                          context.watch<SavedPlacesBloc>().state.contributors;
                      List<String> contributorAvatars = [];
                      List<Place>? places =
                          context.watch<SavedListsBloc>().state.places;
                      if (state is SavedPlacesLoaded && listOwner != null) {
                        contributorAvatars.add(listOwner.profilePicture!);
                        if (contributors != null) {
                          for (User user in contributors) {
                            contributorAvatars.add(user.profilePicture!);
                          }
                        }

                        if (state.places.isNotEmpty) {
                          rows = [
                            for (Place place in state.places)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4.0, horizontal: 8.0),
                                child: PlaceCard(
                                    place: place,
                                    placeList: currentPlaceList!,
                                    imageUrl: place.mainPhoto,
                                    memoryImage: place.mainPhoto,
                                    placeName: place.name!,
                                    ratingsTotal: place.rating,
                                    placeDescription: place.reviews![0]['text'],
                                    closingTime: place.hours![0],
                                    placeLocation: place.city!),
                              )
                          ];
                          if (state.places.length < 5) {
                            for (int i = 0; i < 5 - state.places.length; i++) {
                              rows.add(Opacity(
                                opacity: 0.4,
                                child: Animate(effects: const [
                                  ShimmerEffect(
                                      duration: Duration(milliseconds: 500),
                                      curve: Curves.easeInOut),
                                ], child: const BlankPlaceCard()),
                              ));
                            }
                          }
                        } else {
                          rows = [
                            for (int i = 0; i < 5; i++)
                              Opacity(
                                opacity: 0.4,
                                child: Animate(effects: const [
                                  ShimmerEffect(
                                      duration: Duration(milliseconds: 500),
                                      curve: Curves.easeInOut),
                                  SlideEffect(
                                    curve: Curves.easeOutBack,
                                  )
                                ], child: const BlankPlaceCard()),
                              )
                          ];
                          rows.insert(
                            0,
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Animate(
                                effects: const [
                                  SlideEffect(
                                    curve: Curves.easeOutBack,
                                  ),
                                  ShimmerEffect(
                                      duration: Duration(milliseconds: 500),
                                      curve: Curves.easeInOut)
                                ],
                                child: const AddPlaceCard(),
                              ),
                            ),
                          );
                        }
                      }

                      return BlocConsumer<EditPlacesBloc, EditPlacesState>(
                        listener: (context, state) async {
                          if (state is EditPlacesSubmitted) {
                            context.read<ListSortCubit>().state.status ==
                                    'Visited'
                                ? context.read<SavedPlacesBloc>().add(
                                    LoadVisitedPlaces(
                                        placeList: currentPlaceList!))
                                : context.read<SavedPlacesBloc>().add(
                                    LoadPlaces(placeList: currentPlaceList!));
                            context
                                .read<SavedListsBloc>()
                                .add(LoadSavedLists());
                          }
                        },
                        builder: (context, state) {
                          return Stack(
                            alignment: AlignmentDirectional.bottomCenter,
                            children: [
                              CustomScrollView(
                                controller: mainScrollController,
                                slivers: [
                                  CategoryPageAppBar(
                                      listOwner: listOwner,
                                      contributors: contributors,
                                      placeList: currentPlaceList,
                                      scrollController: mainScrollController),
                                  RandomPlaceBar(
                                    keys: [
                                      _visitedFilterShowcase,
                                      _inviteCollaboratorShowcase,
                                      _randomWheelShowcase,
                                      _checklistShowcase
                                    ],
                                    currentPlaceList: context
                                        .read<SavedPlacesBloc>()
                                        .state
                                        .placeList,
                                    controller: controller,
                                    places: context
                                        .read<SavedPlacesBloc>()
                                        .state
                                        .places,
                                  ),
                                  context.watch<SavedPlacesBloc>().state
                                          is SavedPlacesLoaded
                                      ? StreamBuilder<List<Place>>(
                                          stream: context
                                              .watch<SavedPlacesBloc>()
                                              .state
                                              .placeStream,
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData == false ||
                                                snapshot.data == null) {
                                              return const SliverToBoxAdapter();
                                            }

                                            if (snapshot.hasData &&
                                                snapshot.data != null) {
                                              List<Widget> placeCards = [];
                                              print(
                                                  'snapshot has data ${snapshot.data}');
                                              //rows.clear();
                                              List<Place> places =
                                                  snapshot.data!;
                                              if (places.isNotEmpty &&
                                                  context
                                                          .watch<SavedPlacesBloc>()
                                                          .state
                                                      is SavedPlacesLoaded) {
                                                placeCards = [
                                                  for (Place place in places)
                                                    Padding(
                                                      padding: const EdgeInsets
                                                              .symmetric(
                                                          vertical: 4.0,
                                                          horizontal: 8.0),
                                                      child: PlaceCard(
                                                          place: place,
                                                          placeList: context
                                                              .read<
                                                                  SavedPlacesBloc>()
                                                              .state
                                                              .placeList!,
                                                          imageUrl:
                                                              place.mainPhoto,
                                                          memoryImage:
                                                              place.mainPhoto,
                                                          placeName:
                                                              place.name!,
                                                          ratingsTotal:
                                                              place.rating,
                                                          placeDescription:
                                                              place.reviews![0]
                                                                  ['text'],
                                                          closingTime:
                                                              place.hours![0],
                                                          placeLocation:
                                                              place.city!),
                                                    )
                                                ]
                                                    .animate()
                                                    .slideY(
                                                        curve:
                                                            Curves.easeOutSine,
                                                        begin: -1.0,
                                                        duration: 400.ms)
                                                    .fadeIn(
                                                      //delay: 100.ms,
                                                      curve: Curves.easeOutSine,
                                                      //  duration: 600.ms,
                                                    );
                                              }

                                              for (int i = 0; i < 5; i++) {
                                                rows.add(Opacity(
                                                  opacity: 0.4,
                                                  child: Animate(
                                                      effects: const [
                                                        ShimmerEffect(
                                                            duration: Duration(
                                                                milliseconds:
                                                                    500),
                                                            curve: Curves
                                                                .easeInOut),
                                                        SlideEffect(
                                                          curve: Curves
                                                              .easeOutBack,
                                                        )
                                                      ],
                                                      child:
                                                          const BlankPlaceCard()),
                                                ));
                                              }
                                              rows.insertAll(0, placeCards);
                                            } else {
                                              rows = [
                                                for (int i = 0; i < 5; i++)
                                                  Opacity(
                                                    opacity: 0.4,
                                                    child: Animate(
                                                        effects: const [
                                                          ShimmerEffect(
                                                              duration: Duration(
                                                                  milliseconds:
                                                                      500),
                                                              curve: Curves
                                                                  .easeInOut),
                                                          SlideEffect(
                                                            curve: Curves
                                                                .easeOutBack,
                                                          )
                                                        ],
                                                        child:
                                                            const BlankPlaceCard()),
                                                  )
                                              ];
                                            }
                                            return SliverList(
                                                delegate:
                                                    SliverChildBuilderDelegate(
                                                        (context, index) =>
                                                            rows[index],
                                                        childCount:
                                                            rows.length));

                                            //     SliverChildListDelegate(
                                            //   rows
                                            //       .animate(
                                            //         interval: 150.ms,
                                            //       )
                                            //       .slideY(
                                            //           curve: Curves.easeOutSine,
                                            //           begin: -1.0,
                                            //           duration: 400.ms)
                                            //       .fadeIn(
                                            //         //delay: 100.ms,
                                            //         curve: Curves.easeOutSine,
                                            //         //  duration: 600.ms,
                                            //       ),
                                            // ));

                                            return SliverList(
                                                delegate:
                                                    SliverChildListDelegate(
                                              [
                                                for (int i = 0; i < 5; i++)
                                                  Opacity(
                                                    opacity: 0.4,
                                                    child: Animate(
                                                        effects: const [
                                                          ShimmerEffect(
                                                              duration: Duration(
                                                                  milliseconds:
                                                                      500),
                                                              curve: Curves
                                                                  .easeInOut),
                                                          SlideEffect(
                                                            curve: Curves
                                                                .easeOutBack,
                                                          )
                                                        ],
                                                        child:
                                                            const BlankPlaceCard()),
                                                  )
                                              ],
                                            ));
                                          },
                                        )
                                      : const SliverToBoxAdapter(
                                          child: SizedBox()),
                                ],
                              ),
                              if (state is EditPlacesStarted ||
                                  state is PlaceAdded ||
                                  state is PlaceRemoved)
                                Positioned(
                                  bottom: 12.0,
                                  child: Animate(
                                    effects: const [
                                      SlideEffect(
                                          begin: Offset(0.0, 3.0),
                                          duration: Duration(milliseconds: 400),
                                          curve: Curves.easeOutSine)
                                    ],
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Padding(
                                            padding: const EdgeInsets.only(
                                                left: 16.0),
                                            child: selectionType == 0
                                                ? ElevatedButton(
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.red.shade600,
                                                      foregroundColor:
                                                          Colors.white,
                                                    ),
                                                    onPressed: () {
                                                      context
                                                                  .read<
                                                                      ListSortCubit>()
                                                                  .state
                                                                  .status ==
                                                              'Visited'
                                                          ? context
                                                              .read<
                                                                  EditPlacesBloc>()
                                                              .add(DeleteVisitedPlaces(
                                                                  placeList:
                                                                      currentPlaceList!))
                                                          : context
                                                              .read<
                                                                  EditPlacesBloc>()
                                                              .add(DeletePlaces(
                                                                  placeList:
                                                                      currentPlaceList!));
                                                      // context.read<EditPlacesBloc>().add(
                                                      //     FinishEditing(places: places, placeList: placeList));
                                                    },
                                                    child: Text.rich(
                                                        TextSpan(children: [
                                                      const TextSpan(
                                                          text: 'Delete '),
                                                      TextSpan(
                                                          text:
                                                              '${selectedPlaces.length} ',
                                                          style: const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                      const TextSpan(
                                                          text: 'Places'),
                                                    ])))
                                                : ElevatedButton(
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor: FlexColor
                                                          .bahamaBlueLightPrimary,
                                                      foregroundColor:
                                                          Colors.white,
                                                    ),
                                                    onPressed: () {
                                                      context
                                                          .read<
                                                              EditPlacesBloc>()
                                                          .add(MarkVisitedPlaces(
                                                              placeList:
                                                                  currentPlaceList!));
                                                      // context.read<EditPlacesBloc>().add(
                                                      //     FinishEditing(places: places, placeList: placeList));
                                                    },
                                                    child: Text.rich(
                                                        TextSpan(children: [
                                                      const TextSpan(
                                                          text: 'Mark '),
                                                      TextSpan(
                                                          text:
                                                              '${selectedPlaces.length} ',
                                                          style: const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                      const TextSpan(
                                                          text:
                                                              'Places Visited'),
                                                    ])))),
                                        selectionType == 0
                                            ? context
                                                        .read<ListSortCubit>()
                                                        .state
                                                        .status ==
                                                    'Visited'
                                                ? const SizedBox()
                                                : PopupMenuButton(
                                                    position:
                                                        PopupMenuPosition.under,
                                                    icon: const CircleAvatar(
                                                        child: Icon(Icons
                                                            .keyboard_arrow_down_sharp)),
                                                    itemBuilder: (context) => [
                                                      PopupMenuItem(
                                                          onTap: () {
                                                            setState(() {
                                                              selectionType = 1;
                                                            });
                                                          },
                                                          child: const Text(
                                                              'Mark Visited'))
                                                    ],
                                                  )
                                            : PopupMenuButton(
                                                position:
                                                    PopupMenuPosition.under,
                                                icon: const CircleAvatar(
                                                    child: Icon(Icons
                                                        .keyboard_arrow_down_sharp)),
                                                itemBuilder: (context) => [
                                                  PopupMenuItem(
                                                      onTap: () {
                                                        setState(() {
                                                          selectionType = 0;
                                                        });
                                                      },
                                                      child: const Text(
                                                          'Delete Places'))
                                                ],
                                              )
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      );
                    } else {
                      return const Center(
                          child: Text('Something Went Wrong...'));
                    }
                  },
                ),
              );
            },
          ));
        });
  }

  @override
  void dispose() {
    draggableScrollableController.dispose();
    super.dispose();
  }
}
