import 'dart:collection';
import 'dart:math';

import 'package:appflowy_board/src/widgets/reorder_flex/drag_state.dart';
import 'package:flutter/material.dart';

import '../../utils/log.dart';
import '../reorder_flex/drag_target_interceptor.dart';
import '../reorder_flex/reorder_flex.dart';
import '../reorder_phantom/phantom_controller.dart';
import 'group_data.dart';

typedef OnGroupDragStarted = void Function(int index);

typedef OnGroupDragEnded = void Function(String groupId);

typedef OnGroupReorder = void Function(
  String groupId,
  int fromIndex,
  int toIndex,
);

typedef AppFlowyBoardCardBuilder = Widget Function(
  BuildContext context,
  AppFlowyGroupData groupData,
  AppFlowyGroupItem item,
);

typedef AppFlowyBoardHeaderBuilder = Widget? Function(
  BuildContext context,
  AppFlowyGroupData groupData,
);

typedef AppFlowyBoardFooterBuilder = Widget Function(
  BuildContext context,
  AppFlowyGroupData groupData,
);

typedef OnLoadMoreCards = Future<void> Function(AppFlowyGroupData groupData);

typedef HasMoreCards = bool Function(AppFlowyGroupData groupData);

typedef LoadingWidgetBuilder = Widget Function(BuildContext context);

abstract class AppFlowyGroupDataDataSource implements ReoderFlexDataSource {
  AppFlowyGroupData get groupData;

  List<String> get acceptedGroupIds;

  @override
  String get identifier => groupData.id;

  @override
  UnmodifiableListView<AppFlowyGroupItem> get items => groupData.items;

  void debugPrint() {
    String msg = '[$AppFlowyGroupDataDataSource] $groupData data: ';
    for (final element in items) {
      msg = '$msg$element,';
    }

    Log.debug(msg);
  }
}

/// A [AppFlowyBoardGroup] represents the group UI of the Board.
///
class AppFlowyBoardGroup extends StatefulWidget {
  const AppFlowyBoardGroup({
    super.key,
    required this.cardBuilder,
    required this.onReorder,
    required this.dataSource,
    required this.phantomController,
    this.headerBuilder,
    this.footerBuilder,
    this.reorderFlexAction,
    this.dragStateStorage,
    this.dragTargetKeys,
    this.scrollController,
    this.onDragStarted,
    this.onDragEnded,
    this.margin = EdgeInsets.zero,
    this.bodyPadding = EdgeInsets.zero,
    this.cornerRadius = 0.0,
    this.backgroundColor = Colors.transparent,
    this.stretchGroupHeight = true,
    this.shrinkWrap = false,
    this.cardPageSize = 0,
    this.loadMoreTriggerOffset = 80.0,
    this.onLoadMore,
    this.hasMore,
    this.loadingWidgetBuilder,
  }) : config = const ReorderFlexConfig();

  final AppFlowyBoardCardBuilder cardBuilder;
  final OnGroupReorder onReorder;
  final AppFlowyGroupDataDataSource dataSource;
  final BoardPhantomController phantomController;
  final AppFlowyBoardHeaderBuilder? headerBuilder;
  final AppFlowyBoardFooterBuilder? footerBuilder;
  final ReorderFlexAction? reorderFlexAction;
  final DraggingStateStorage? dragStateStorage;
  final ReorderDragTargetKeys? dragTargetKeys;

  final ScrollController? scrollController;
  final OnGroupDragStarted? onDragStarted;

  final OnGroupDragEnded? onDragEnded;
  final EdgeInsets margin;
  final EdgeInsets bodyPadding;
  final double cornerRadius;
  final Color backgroundColor;
  final bool stretchGroupHeight;
  final bool shrinkWrap;
  final ReorderFlexConfig config;
  final int cardPageSize;
  final double loadMoreTriggerOffset;
  final OnLoadMoreCards? onLoadMore;
  final HasMoreCards? hasMore;

  /// Custom builder for the loading indicator widget.
  /// If not provided, a default CircularProgressIndicator will be used.
  final LoadingWidgetBuilder? loadingWidgetBuilder;

  String get groupId => dataSource.groupData.id;

  @override
  State<AppFlowyBoardGroup> createState() => _AppFlowyBoardGroupState();
}

class _AppFlowyBoardGroupState extends State<AppFlowyBoardGroup> {
  ScrollController? _scrollController;
  int _visibleCount = 0;
  bool _isLoadingMore = false;
  int _lastTotalItems = 0;

  @override
  void initState() {
    super.initState();
    _initVisibleCount();
    _attachScrollController(widget.scrollController);
  }

  @override
  void didUpdateWidget(covariant AppFlowyBoardGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      _attachScrollController(widget.scrollController);
    }

    if (oldWidget.cardPageSize != widget.cardPageSize) {
      _initVisibleCount();
    }
  }

  @override
  void dispose() {
    _detachScrollController();
    super.dispose();
  }

  void _attachScrollController(ScrollController? controller) {
    _detachScrollController();
    _scrollController = controller;
    _scrollController?.addListener(_onScroll);
  }

  void _detachScrollController() {
    _scrollController?.removeListener(_onScroll);
    _scrollController = null;
  }

  void _initVisibleCount() {
    final totalItems = widget.dataSource.groupData.items.length;
    if (widget.cardPageSize <= 0) {
      _visibleCount = totalItems;
      _lastTotalItems = totalItems;
      return;
    }
    _visibleCount = min(widget.cardPageSize, totalItems);
    _lastTotalItems = totalItems;
  }

  void _syncVisibleCount(int totalItems) {
    if (widget.cardPageSize <= 0) {
      _visibleCount = totalItems;
      _lastTotalItems = totalItems;
      return;
    }

    if (_lastTotalItems == 0 && totalItems > 0) {
      _visibleCount = min(widget.cardPageSize, totalItems);
      _lastTotalItems = totalItems;
      return;
    }

    if (totalItems < _lastTotalItems) {
      if (_visibleCount > totalItems) {
        _visibleCount = totalItems;
      }
    } else if (totalItems > _lastTotalItems) {
      final added = totalItems - _lastTotalItems;
      if (_visibleCount >= _lastTotalItems) {
        _visibleCount = min(_visibleCount + added, totalItems);
      }
    }

    _lastTotalItems = totalItems;
  }

  void _onScroll() {
    final controller = _scrollController;
    if (controller == null || !controller.hasClients) return;

    final position = controller.position;
    final threshold = widget.loadMoreTriggerOffset;
    if (position.pixels >= position.maxScrollExtent - threshold) {
      _maybeLoadMore();
    }
  }

  Future<void> _maybeLoadMore() async {
    if (_isLoadingMore || widget.cardPageSize <= 0) {
      return;
    }

    final totalItems = widget.dataSource.groupData.items.length;
    final hasHiddenItems = _visibleCount < totalItems;
    final hasMoreOverride = widget.hasMore?.call(widget.dataSource.groupData);
    if (hasMoreOverride == false) {
      return;
    }
    final hasMore =
        hasMoreOverride ?? hasHiddenItems || widget.onLoadMore != null;

    if (!hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      await widget.onLoadMore?.call(widget.dataSource.groupData);
    } finally {
      if (mounted) {
        final updatedTotal = widget.dataSource.groupData.items.length;
        setState(() {
          _isLoadingMore = false;
          _visibleCount =
              min(_visibleCount + widget.cardPageSize, updatedTotal);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.dataSource.groupData.items;
    final totalItems = items.length;
    _syncVisibleCount(totalItems);
    final visibleCount =
        widget.cardPageSize <= 0 ? totalItems : min(_visibleCount, totalItems);
    final visibleItems = items.take(visibleCount).toList();
    final children =
        visibleItems.map((item) => _buildWidget(context, item)).toList();

    // Check if there are more items to load
    final hasMoreItems = visibleCount < totalItems ||
        (widget.hasMore?.call(widget.dataSource.groupData) ?? false);

    // Build loading indicator widget (placed outside ReorderFlex)
    Widget? loadingIndicator;
    if (_isLoadingMore && hasMoreItems) {
      loadingIndicator = widget.loadingWidgetBuilder?.call(context) ??
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 1.0),
              ),
            ),
          );
    }

    final header =
        widget.headerBuilder?.call(context, widget.dataSource.groupData);

    final footer =
        widget.footerBuilder?.call(context, widget.dataSource.groupData);

    final dataSource = _LimitedGroupDataSource(
      base: widget.dataSource,
      items: visibleItems,
    );

    final interceptor = CrossReorderFlexDragTargetInterceptor(
      reorderFlexId: widget.groupId,
      delegate: widget.phantomController,
      acceptedReorderFlexIds: widget.dataSource.acceptedGroupIds,
      draggableTargetBuilder: PhantomDraggableBuilder(),
    );

    final reorderFlex = ReorderFlex(
      key: ValueKey(widget.groupId),
      dragStateStorage: widget.dragStateStorage,
      dragTargetKeys: widget.dragTargetKeys,
      scrollController: widget.scrollController,
      config: widget.config,
      onDragStarted: (index) {
        widget.phantomController.groupStartDragging(widget.groupId);
        widget.onDragStarted?.call(index);
      },
      onReorder: (fromIndex, toIndex) {
        if (widget.phantomController.shouldReorder(widget.groupId)) {
          widget.onReorder(widget.groupId, fromIndex, toIndex);
          widget.phantomController.updateIndex(fromIndex, toIndex);
        }
      },
      onDragEnded: () {
        widget.phantomController.groupEndDragging(widget.groupId);
        widget.onDragEnded?.call(widget.groupId);
        widget.dataSource.debugPrint();
      },
      dataSource: dataSource,
      interceptor: interceptor,
      reorderFlexAction: widget.reorderFlexAction,
      children: children,
    );

    // Only wrap in Column if we have a loading indicator to show
    final scrollContent = loadingIndicator != null
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [reorderFlex, loadingIndicator],
          )
        : reorderFlex;

    final paddingWidget = Padding(
      padding: widget.bodyPadding,
      child: SingleChildScrollView(
        scrollDirection: widget.config.direction,
        controller: widget.scrollController,
        child: scrollContent,
      ),
    );

    final reorderWidget = widget.shrinkWrap
        ? paddingWidget
        : Flexible(
            fit: widget.stretchGroupHeight ? FlexFit.tight : FlexFit.loose,
            child: paddingWidget,
          );

    final childrenWidgets = [
      if (header != null) header,
      reorderWidget,
      if (footer != null) footer,
    ];

    Widget content = widget.shrinkWrap
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: childrenWidgets,
          )
        : Flex(
            direction: Axis.vertical,
            mainAxisSize: MainAxisSize.min,
            children: childrenWidgets,
          );

    content = widget.cornerRadius > 0
        ? ClipRRect(
            borderRadius: BorderRadius.circular(widget.cornerRadius),
            child: content,
          )
        : ClipRect(child: content);

    return Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(widget.cornerRadius),
      ),
      child: content,
    );
  }

  Widget _buildWidget(BuildContext context, AppFlowyGroupItem item) {
    if (item is PhantomGroupItem) {
      return PassthroughPhantomWidget(
        key: UniqueKey(),
        opacity: widget.config.draggingWidgetOpacity,
        passthroughPhantomContext: item.phantomContext,
      );
    }

    final card = widget.cardBuilder(context, widget.dataSource.groupData, item);
    return RepaintBoundary(
      key: ValueKey(item.id),
      child: card,
    );
  }
}

class _LimitedGroupDataSource extends AppFlowyGroupDataDataSource {
  _LimitedGroupDataSource({
    required this.base,
    required List<AppFlowyGroupItem> items,
  }) : _items = UnmodifiableListView(items);

  final AppFlowyGroupDataDataSource base;
  final UnmodifiableListView<AppFlowyGroupItem> _items;

  @override
  AppFlowyGroupData get groupData => base.groupData;

  @override
  List<String> get acceptedGroupIds => base.acceptedGroupIds;

  @override
  UnmodifiableListView<AppFlowyGroupItem> get items => _items;
}
