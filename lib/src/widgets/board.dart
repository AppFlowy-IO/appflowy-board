import 'package:appflowy_board/src/utils/log.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'board_data.dart';
import 'board_group/group.dart';
import 'board_group/group_data.dart';
import 'reorder_flex/drag_state.dart';
import 'reorder_flex/drag_target_interceptor.dart';
import 'reorder_flex/reorder_flex.dart';
import 'reorder_phantom/phantom_controller.dart';
import '../rendering/board_overlay.dart';

class AppFlowyBoardScrollController {
  AppFlowyBoardState? _boardState;

  void scrollToBottom(String groupId,
      {void Function(BuildContext)? completed}) {
    _boardState?.reorderFlexActionMap[groupId]?.scrollToBottom(completed);
  }
}

class AppFlowyBoardConfig {
  // board
  final double boardCornerRadius;

  // group
  final Color groupBackgroundColor;
  final double groupCornerRadius;
  final EdgeInsets groupMargin;
  final EdgeInsets groupHeaderPadding;
  final EdgeInsets groupBodyPadding;
  final EdgeInsets groupFooterPadding;
  final bool stretchGroupHeight;

  // card
  final EdgeInsets cardMargin;

  const AppFlowyBoardConfig({
    this.boardCornerRadius = 6.0,
    this.groupCornerRadius = 6.0,
    this.groupBackgroundColor = Colors.transparent,
    this.groupMargin = const EdgeInsets.symmetric(horizontal: 8),
    this.groupHeaderPadding = const EdgeInsets.symmetric(horizontal: 16),
    this.groupBodyPadding = const EdgeInsets.symmetric(horizontal: 12),
    this.groupFooterPadding = const EdgeInsets.symmetric(horizontal: 12),
    this.stretchGroupHeight = true,
    this.cardMargin = const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
  });
}

class AppFlowyBoard extends StatelessWidget {
  /// The widget that will be rendered as the background of the board.
  final Widget? background;

  /// The [cardBuilder] function which will be invoked on each card build.
  /// The [cardBuilder] takes the [BuildContext],[AppFlowyGroupData] and
  /// the corresponding [AppFlowyGroupItem].
  ///
  /// must return a widget.
  final AppFlowyBoardCardBuilder cardBuilder;

  /// The [headerBuilder] function which will be invoked on each group build.
  /// The [headerBuilder] takes the [BuildContext] and [AppFlowyGroupData].
  ///
  /// must return a widget.
  final AppFlowyBoardHeaderBuilder? headerBuilder;

  /// The [footerBuilder] function which will be invoked on each group build.
  /// The [footerBuilder] takes the [BuildContext] and [AppFlowyGroupData].
  ///
  /// must return a widget.
  final AppFlowyBoardFooterBuilder? footerBuilder;

  /// A controller for [AppFlowyBoard] widget.
  ///
  /// A [AppFlowyBoardController] can be used to provide an initial value of
  /// the board by calling `addGroup` method with the passed in parameter
  /// [AppFlowyGroupData]. A [AppFlowyGroupData] represents one
  /// group data. Whenever the user modifies the board, this controller will
  /// update the corresponding group data.
  ///
  /// Also, you can register the callbacks that receive the changes. Check out
  /// the [AppFlowyBoardController] for more information.
  ///
  final AppFlowyBoardController controller;

  /// A constraints applied to [AppFlowyBoardGroup] widget.
  final BoxConstraints groupConstraints;

  /// A controller is used by the [ReorderFlex].
  ///
  /// The [ReorderFlex] will used the primary scrollController of the current
  /// [BuildContext] by using PrimaryScrollController.of(context).
  /// If the primary scrollController is null, we will assign a new [ScrollController].
  final ScrollController? scrollController;

  ///
  final AppFlowyBoardConfig config;

  /// A controller is used to control each group scroll actions.
  ///
  final AppFlowyBoardScrollController? boardScrollController;

  /// A widget that is shown before the first group in the Board
  ///
  final Widget? leading;

  /// A widget that is shown after the last group in the Board
  ///
  final Widget? trailing;

  const AppFlowyBoard({
    super.key,
    required this.controller,
    required this.cardBuilder,
    this.background,
    this.footerBuilder,
    this.headerBuilder,
    this.scrollController,
    this.boardScrollController,
    this.groupConstraints = const BoxConstraints(maxWidth: 200),
    this.config = const AppFlowyBoardConfig(),
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: Consumer<AppFlowyBoardController>(
        builder: (context, notifier, child) {
          final boardState = AppFlowyBoardState();
          BoardPhantomController phantomController = BoardPhantomController(
            delegate: controller,
            groupsState: boardState,
          );

          if (boardScrollController != null) {
            boardScrollController!._boardState = boardState;
          }

          return _AppFlowyBoardContent(
            config: config,
            dataController: controller,
            scrollController: scrollController,
            scrollManager: boardScrollController,
            boardState: boardState,
            background: background,
            delegate: phantomController,
            groupConstraints: groupConstraints,
            cardBuilder: cardBuilder,
            footerBuilder: footerBuilder,
            headerBuilder: headerBuilder,
            phantomController: phantomController,
            onReorder: controller.moveGroup,
            leading: leading,
            trailing: trailing,
          );
        },
      ),
    );
  }
}

class _AppFlowyBoardContent extends StatefulWidget {
  final AppFlowyBoardConfig config;
  final OnReorder onReorder;
  final OverlapDragTargetDelegate delegate;
  final AppFlowyBoardController dataController;
  final AppFlowyBoardScrollController? scrollManager;
  final ScrollController? scrollController;
  final AppFlowyBoardState boardState;
  final BoxConstraints groupConstraints;
  final AppFlowyBoardCardBuilder cardBuilder;
  final BoardPhantomController phantomController;
  final Widget? leading;
  final Widget? trailing;
  final Widget? background;
  final ReorderFlexConfig reorderFlexConfig;
  final AppFlowyBoardHeaderBuilder? headerBuilder;
  final AppFlowyBoardFooterBuilder? footerBuilder;

  const _AppFlowyBoardContent({
    required this.config,
    required this.onReorder,
    required this.delegate,
    required this.dataController,
    required this.scrollManager,
    required this.boardState,
    required this.groupConstraints,
    required this.cardBuilder,
    required this.phantomController,
    this.leading,
    this.trailing,
    this.scrollController,
    this.background,
    this.footerBuilder,
    this.headerBuilder,
  }) : reorderFlexConfig = const ReorderFlexConfig(
          direction: Axis.horizontal,
          dragDirection: Axis.horizontal,
        );

  @override
  State<_AppFlowyBoardContent> createState() => _AppFlowyBoardContentState();
}

class _AppFlowyBoardContentState extends State<_AppFlowyBoardContent> {
  final GlobalKey _boardContentKey =
      GlobalKey(debugLabel: '$_AppFlowyBoardContent overlay key');
  late BoardOverlayEntry _overlayEntry;

  @override
  void initState() {
    super.initState();
    _overlayEntry = BoardOverlayEntry(
      builder: (BuildContext context) {
        return Stack(
          alignment: AlignmentDirectional.topStart,
          children: [
            if (widget.background != null)
              Container(
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(widget.config.boardCornerRadius),
                ),
                child: widget.background,
              ),
            ReorderFlex(
              config: widget.reorderFlexConfig,
              scrollController: widget.scrollController,
              onReorder: widget.onReorder,
              dataSource: widget.dataController,
              interceptor: OverlappingDragTargetInterceptor(
                reorderFlexId: widget.dataController.identifier,
                acceptedReorderFlexId: widget.dataController.groupIds,
                delegate: widget.delegate,
                columnsState: widget.boardState,
              ),
              leading: widget.leading,
              trailing: widget.trailing,
              groupWidth: widget.groupConstraints.maxWidth,
              children: _buildColumns(),
            ),
          ],
        );
      },
      opaque: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BoardOverlay(
      key: _boardContentKey,
      initialEntries: [_overlayEntry],
    );
  }

  List<Widget> _buildColumns() {
    final List<Widget> children = [];

    widget.dataController.groupDatas.asMap().entries.map(
      (item) {
        final columnData = item.value;
        final columnIndex = item.key;

        final dataSource = _BoardGroupDataSourceImpl(
          groupId: columnData.id,
          dataController: widget.dataController,
        );

        final reorderFlexAction = ReorderFlexActionImpl();
        widget.boardState.reorderFlexActionMap[columnData.id] =
            reorderFlexAction;

        children.add(
          ChangeNotifierProvider.value(
            key: ValueKey(columnData.id),
            value: widget.dataController.getGroupController(columnData.id),
            child: Consumer<AppFlowyGroupController>(
              builder: (context, value, child) {
                return ConstrainedBox(
                  constraints: widget.groupConstraints,
                  child: LayoutBuilder(
                    // use LayoutBuilder to get the width of the group
                    // and pass it to be used in [ReorderDragTarget]
                    builder: (context, constraints) => AppFlowyBoardGroup(
                      margin: _marginFromIndex(columnIndex),
                      bodyPadding: widget.config.groupBodyPadding,
                      headerBuilder: _buildHeader,
                      footerBuilder: widget.footerBuilder,
                      cardBuilder: widget.cardBuilder,
                      dataSource: dataSource,
                      scrollController: ScrollController(),
                      phantomController: widget.phantomController,
                      onReorder: widget.dataController.moveGroupItem,
                      cornerRadius: widget.config.groupCornerRadius,
                      backgroundColor: widget.config.groupBackgroundColor,
                      dragStateStorage: widget.boardState,
                      dragTargetKeys: widget.boardState,
                      reorderFlexAction: reorderFlexAction,
                      stretchGroupHeight: widget.config.stretchGroupHeight,
                      groupWidth: constraints.maxWidth,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    ).toList();

    return children;
  }

  Widget? _buildHeader(
    BuildContext context,
    AppFlowyGroupData groupData,
  ) {
    if (widget.headerBuilder == null) {
      return null;
    }
    return Selector<AppFlowyGroupController, AppFlowyGroupHeaderData>(
      selector: (context, controller) => controller.groupData.headerData,
      builder: (context, headerData, _) {
        return widget.headerBuilder!(context, groupData)!;
      },
    );
  }

  EdgeInsets _marginFromIndex(int index) {
    if (widget.dataController.groupDatas.isEmpty) {
      return widget.config.groupMargin;
    }

    if (index == 0) {
      // remove the left padding of the first group
      return widget.config.groupMargin.copyWith(left: 0);
    }

    if (index == widget.dataController.groupDatas.length - 1) {
      // remove the right padding of the last group
      return widget.config.groupMargin.copyWith(right: 0);
    }

    return widget.config.groupMargin;
  }
}

class _BoardGroupDataSourceImpl extends AppFlowyGroupDataDataSource {
  String groupId;
  final AppFlowyBoardController dataController;

  _BoardGroupDataSourceImpl({
    required this.groupId,
    required this.dataController,
  });

  @override
  AppFlowyGroupData get groupData =>
      dataController.getGroupController(groupId)!.groupData;

  @override
  List<String> get acceptedGroupIds => dataController.groupIds;
}

/// A context contains the group states including the draggingState.
///
/// [draggingState] represents the dragging state of the group.
class AppFlowyGroupContext {
  DraggingState? draggingState;
}

class AppFlowyBoardState extends DraggingStateStorage
    with ReorderDragTargeKeys {
  final Map<String, DraggingState> groupDragStates = {};
  final Map<String, Map<String, GlobalObjectKey>> groupDragTargetKeys = {};

  /// Quick access to the [AppFlowyBoardGroup], the [GlobalKey] is bind to the
  /// AppFlowyBoardGroup's [ReorderFlex] widget.
  final Map<String, ReorderFlexActionImpl> reorderFlexActionMap = {};

  @override
  DraggingState? readState(String reorderFlexId) {
    return groupDragStates[reorderFlexId];
  }

  @override
  void insertState(String reorderFlexId, DraggingState state) {
    Log.trace('$reorderFlexId Write dragging state: $state');
    groupDragStates[reorderFlexId] = state;
  }

  @override
  void removeState(String reorderFlexId) {
    groupDragStates.remove(reorderFlexId);
  }

  @override
  void insertDragTarget(
    String reorderFlexId,
    String key,
    GlobalObjectKey<State<StatefulWidget>> value,
  ) {
    Map<String, GlobalObjectKey>? group = groupDragTargetKeys[reorderFlexId];
    if (group == null) {
      group = {};
      groupDragTargetKeys[reorderFlexId] = group;
    }
    group[key] = value;
  }

  @override
  GlobalObjectKey<State<StatefulWidget>>? getDragTarget(
    String reorderFlexId,
    String key,
  ) {
    Map<String, GlobalObjectKey>? group = groupDragTargetKeys[reorderFlexId];
    if (group != null) {
      return group[key];
    } else {
      return null;
    }
  }

  @override
  void removeDragTarget(String reorderFlexId) {
    groupDragTargetKeys.remove(reorderFlexId);
  }
}

class ReorderFlexActionImpl extends ReorderFlexAction {}
