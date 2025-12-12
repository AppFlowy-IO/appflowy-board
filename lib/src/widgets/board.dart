import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/log.dart';
import 'board_data.dart';
import 'board_group/group.dart';
import 'board_group/group_data.dart';
import 'reorder_flex/drag_state.dart';
import 'reorder_flex/drag_target_interceptor.dart';
import 'reorder_flex/reorder_flex.dart';
import 'reorder_phantom/phantom_controller.dart';

class AppFlowyBoardScrollController {
  AppFlowyBoardState? _boardState;

  void scrollToBottom(
    String groupId, {
    void Function(BuildContext)? completed,
  }) {
    _boardState?.reorderFlexActionMap[groupId]?.scrollToBottom(completed);
  }
}

class AppFlowyBoardConfig {
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
    this.dragAutoScrollVelocity = 30.0,
  });

  // board
  final double boardCornerRadius;

  // group
  final double groupCornerRadius;
  final Color groupBackgroundColor;
  final EdgeInsets groupMargin;
  final EdgeInsets groupHeaderPadding;
  final EdgeInsets groupBodyPadding;
  final EdgeInsets groupFooterPadding;
  final bool stretchGroupHeight;

  // card
  final EdgeInsets cardMargin;

  /// The velocity scalar for auto-scrolling when dragging cards near edges.
  /// Lower values result in slower scrolling. Default is 30.0.
  /// Increase this value for faster scrolling, decrease for slower.
  final double dragAutoScrollVelocity;
}

class AppFlowyBoard extends StatelessWidget {
  const AppFlowyBoard({
    super.key,
    required this.controller,
    required this.cardBuilder,
    this.headerBuilder,
    this.footerBuilder,
    this.background,
    this.groupConstraints = const BoxConstraints(maxWidth: 200),
    this.scrollController,
    this.config = const AppFlowyBoardConfig(),
    this.boardScrollController,
    this.leading,
    this.trailing,
    this.shrinkWrap = false,
  });

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

  /// A constraints applied to [AppFlowyBoardGroup] widget.
  final BoxConstraints groupConstraints;

  /// A controller is used by the [ReorderFlex].
  ///
  /// The [ReorderFlex] will used the primary scrollController of the current
  /// [BuildContext] by using PrimaryScrollController.of(context).
  /// If the primary scrollController is null, we will assign a new [ScrollController].
  final ScrollController? scrollController;

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

  /// if [shrinkWrap] is true, the height of board will be dynamic
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: Consumer<AppFlowyBoardController>(
        builder: (context, notifier, child) {
          return _AppFlowyBoardContent(
            config: config,
            boardController: controller,
            scrollController: scrollController,
            scrollManager: boardScrollController,
            background: background,
            groupConstraints: groupConstraints,
            cardBuilder: cardBuilder,
            footerBuilder: footerBuilder,
            headerBuilder: headerBuilder,
            onReorder: controller.moveGroup,
            leading: leading,
            trailing: trailing,
            shrinkWrap: shrinkWrap,
          );
        },
      ),
    );
  }
}

class _AppFlowyBoardContent extends StatefulWidget {
  _AppFlowyBoardContent({
    required this.config,
    required this.onReorder,
    required this.boardController,
    required this.scrollManager,
    required this.groupConstraints,
    required this.cardBuilder,
    this.leading,
    this.trailing,
    this.shrinkWrap = false,
    this.scrollController,
    this.background,
    this.headerBuilder,
    this.footerBuilder,
  }) : reorderFlexConfig = ReorderFlexConfig(
          direction: Axis.horizontal,
          dragDirection: Axis.horizontal,
          autoScrollVelocityScalar: config.dragAutoScrollVelocity,
        );

  final AppFlowyBoardConfig config;
  final OnReorder onReorder;
  final AppFlowyBoardController boardController;
  final AppFlowyBoardScrollController? scrollManager;
  final BoxConstraints groupConstraints;
  final AppFlowyBoardCardBuilder cardBuilder;
  final Widget? leading;
  final Widget? trailing;
  final ScrollController? scrollController;
  final Widget? background;
  final bool shrinkWrap;
  final AppFlowyBoardHeaderBuilder? headerBuilder;
  final AppFlowyBoardFooterBuilder? footerBuilder;
  final ReorderFlexConfig reorderFlexConfig;

  @override
  State<_AppFlowyBoardContent> createState() => _AppFlowyBoardContentState();
}

class _AppFlowyBoardContentState extends State<_AppFlowyBoardContent> {
  late final _scrollController =
      widget.scrollController ?? ScrollController();
  late final AppFlowyBoardState _boardState;
  late final BoardPhantomController _phantomController;
  final Map<String, ScrollController> _groupScrollControllers = {};

  @override
  void initState() {
    super.initState();
    _boardState = AppFlowyBoardState();
    _phantomController = BoardPhantomController(
      delegate: widget.boardController,
      groupsState: _boardState,
    );

    if (widget.scrollManager != null) {
      widget.scrollManager!._boardState = _boardState;
    }
  }

  @override
  void dispose() {
    // Dispose internally created scroll controller
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    // Dispose all group scroll controllers
    for (final controller in _groupScrollControllers.values) {
      controller.dispose();
    }
    _groupScrollControllers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        if (widget.background != null)
          // Use ClipRRect for better performance than Container with clipBehavior
          ClipRRect(
            borderRadius:
                BorderRadius.circular(widget.config.boardCornerRadius),
            child: widget.background,
          ),
        Scrollbar(
          controller: _scrollController,
          child: SingleChildScrollView(
            scrollDirection: widget.reorderFlexConfig.direction,
            controller: _scrollController,
            child: ReorderFlex(
              config: widget.reorderFlexConfig,
              scrollController: _scrollController,
              onReorder: widget.onReorder,
              dataSource: widget.boardController,
              autoScroll: true,
              interceptor: OverlappingDragTargetInterceptor(
                reorderFlexId: widget.boardController.identifier,
                acceptedReorderFlexId: widget.boardController.groupIds,
                delegate: _phantomController,
                columnsState: _boardState,
              ),
              leading: widget.leading,
              trailing: widget.trailing,
              children: _buildColumns(),
            ),
          ),
        ),
      ],
    );
  }

  ScrollController _getOrCreateGroupScrollController(String groupId) {
    if (!_groupScrollControllers.containsKey(groupId)) {
      _groupScrollControllers[groupId] = ScrollController();
    }
    return _groupScrollControllers[groupId]!;
  }

  List<Widget> _buildColumns() {
    final List<Widget> children = [];

    // Clean up scroll controllers for removed groups
    final currentGroupIds =
        widget.boardController.groupDatas.map((g) => g.id).toSet();
    final removedGroupIds = _groupScrollControllers.keys
        .where((id) => !currentGroupIds.contains(id))
        .toList();
    for (final groupId in removedGroupIds) {
      _groupScrollControllers[groupId]?.dispose();
      _groupScrollControllers.remove(groupId);
    }

    widget.boardController.groupDatas.asMap().entries.map((item) {
      final columnData = item.value;
      final columnIndex = item.key;

      final dataSource = _BoardGroupDataSourceImpl(
        groupId: columnData.id,
        boardController: widget.boardController,
      );

      final reorderFlexAction = ReorderFlexActionImpl();
      _boardState.reorderFlexActionMap[columnData.id] = reorderFlexAction;

      children.add(
        ChangeNotifierProvider.value(
          key: ValueKey(columnData.id),
          value: widget.boardController.getGroupController(columnData.id),
          child: Consumer<AppFlowyGroupController>(
            builder: (context, value, child) => ConstrainedBox(
              constraints: widget.groupConstraints,
              child: AppFlowyBoardGroup(
                margin: _marginFromIndex(columnIndex),
                bodyPadding: widget.config.groupBodyPadding,
                headerBuilder: _buildHeader,
                footerBuilder: widget.footerBuilder,
                cardBuilder: widget.cardBuilder,
                dataSource: dataSource,
                scrollController:
                    _getOrCreateGroupScrollController(columnData.id),
                shrinkWrap: widget.shrinkWrap,
                phantomController: _phantomController,
                onReorder: widget.boardController.moveGroupItem,
                cornerRadius: widget.config.groupCornerRadius,
                backgroundColor: widget.config.groupBackgroundColor,
                dragStateStorage: _boardState,
                dragTargetKeys: _boardState,
                reorderFlexAction: reorderFlexAction,
                stretchGroupHeight: widget.config.stretchGroupHeight,
                onDragStarted: (index) {
                  widget.boardController.onStartDraggingCard
                      ?.call(columnData.id, index);
                },
              ),
            ),
          ),
        ),
      );
    }).toList();

    return children;
  }

  Widget? _buildHeader(BuildContext context, AppFlowyGroupData groupData) {
    if (widget.headerBuilder == null) {
      return null;
    }
    return Selector<AppFlowyGroupController, AppFlowyGroupHeaderData>(
      selector: (context, controller) => controller.groupData.headerData,
      builder: (context, _, __) => widget.headerBuilder!(context, groupData)!,
    );
  }

  EdgeInsets _marginFromIndex(int index) {
    if (widget.boardController.groupDatas.isEmpty) {
      return widget.config.groupMargin;
    }

    if (index == 0) {
      // remove the left padding of the first group
      return widget.config.groupMargin.copyWith(left: 0);
    }

    if (index == widget.boardController.groupDatas.length - 1) {
      // remove the right padding of the last group
      return widget.config.groupMargin.copyWith(right: 0);
    }

    return widget.config.groupMargin;
  }
}

class _BoardGroupDataSourceImpl extends AppFlowyGroupDataDataSource {
  _BoardGroupDataSourceImpl({
    required this.groupId,
    required this.boardController,
  });

  final String groupId;
  final AppFlowyBoardController boardController;

  @override
  AppFlowyGroupData get groupData =>
      boardController.getGroupController(groupId)!.groupData;

  @override
  List<String> get acceptedGroupIds => boardController.groupIds;
}

class AppFlowyBoardState extends DraggingStateStorage
    implements ReorderDragTargetKeys {
  final Map<String, DraggingState> groupDragStates = {};
  final Map<String, Map<String, GlobalObjectKey>> groupDragTargetKeys = {};

  /// Quick access to the [AppFlowyBoardGroup], the [GlobalKey] is bind to the
  /// AppFlowyBoardGroup's [ReorderFlex] widget.
  final Map<String, ReorderFlexActionImpl> reorderFlexActionMap = {};

  @override
  DraggingState? readState(String reorderFlexId) =>
      groupDragStates[reorderFlexId];

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
    final Map<String, GlobalObjectKey>? group =
        groupDragTargetKeys[reorderFlexId];
    if (group != null) {
      return group[key];
    }

    return null;
  }

  @override
  void removeDragTarget(String reorderFlexId) {
    groupDragTargetKeys.remove(reorderFlexId);
  }
}

class ReorderFlexActionImpl extends ReorderFlexAction {}
