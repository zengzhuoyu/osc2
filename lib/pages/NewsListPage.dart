import 'package:flutter/material.dart';
import 'package:osc2/widgets/SlideView.dart';
import 'dart:async';
import 'dart:convert';
import 'package:osc2/api/Api.dart';
import 'package:osc2/util/NetUtils.dart';
import 'package:osc2/constants/Constants.dart';

// 资讯列表页面
class NewsListPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => NewsListPageState();
}

class NewsListPageState extends State<NewsListPage> {

  // 轮播图的数据
  var slideData = null;
  // 列表的数据（轮播图数据和列表数据分开，但是实际上轮播图和列表中的item同属于ListView的item）
  var listData = null;
  // 列表中资讯标题的样式
  TextStyle titleTextStyle = new TextStyle(fontSize: 15.0);
  // 时间文本的样式
  TextStyle subtitleStyle = new TextStyle(color: const Color(0xFFB5BDC0), fontSize: 12.0);
  // 当前数据页索引值
  var curPage = 1;
  // 数据总条数
  var listTotalSize = 0;
  // ListView控制器
  ScrollController _controller = new ScrollController();

  NewsListPageState() {
//    // 这里做数据初始化，加入一些测试数据
//    for (int i = 0; i < 3; i++) {
//      Map map = new Map();
//      // 轮播图的资讯标题
//      map['title'] = 'Python 之父透露退位隐情，与核心开发团队产生隔阂';
//      // 轮播图的详情URL
//      map['detailUrl'] = 'https://www.oschina.net/news/98455/guido-van-rossum-resigns';
//      // 轮播图的图片URL
//      map['imgUrl'] = 'https://static.oschina.net/uploads/img/201807/30113144_1SRR.png';
//      slideData.add(map);
//    }
//    for (int i = 0; i < 30; i++) {
//      Map map = new Map();
//      // 列表item的标题
//      map['title'] = 'J2Cache 2.3.23 发布，支持 memcached 二级缓存';
//      // 列表item的作者头像URL
//      map['authorImg'] = 'https://static.oschina.net/uploads/user/0/12_50.jpg?t=1421200584000';
//      // 列表item的时间文本
//      map['timeStr'] = '2018/7/30';
//      // 列表item的资讯图片
//      map['thumb'] = 'https://static.oschina.net/uploads/logo/j2cache_N3NcX.png';
//      // 列表item的评论数
//      map['commCount'] = 5;
//      listData.add(map);
//    }

    _controller.addListener(() {
      // 表示列表的最大滚动距离
      var maxScroll = _controller.position.maxScrollExtent;
      // 表示当前列表已向下滚动的距离
      var pixels = _controller.position.pixels;
      // 如果两个值相等，表示滚动到底，并且如果列表没有加载完所有数据
      if (maxScroll == pixels && listData.length < listTotalSize) {
        // scroll to bottom, get next page data
        print("load more ... ");
        curPage++; // 当前页索引加1
        getNewsList(true); // 获取下一页数据
      }
    });

  }

  Future<Null> _pullToRefresh() async {
    curPage = 1;
    getNewsList(false);
    return null;
  }

  // 从网络获取数据，isLoadMore表示是否是加载更多数据
  getNewsList(bool isLoadMore) {
    String url = Api.NEWS_LIST;
    url += "?pageIndex=$curPage&pageSize=10";
    NetUtils.get(url).then((data) {
      if (data != null) {
        // 将接口返回的json字符串解析为map类型
        Map<String, dynamic> map = json.decode(data);
        if (map['code'] == 0) {
          // code=0表示请求成功
          var msg = map['msg'];
          // total表示资讯总条数
          listTotalSize = msg['news']['total'];
          // data为数据内容，其中包含slide和news两部分，分别表示头部轮播图数据，和下面的列表数据
          var _listData = msg['news']['data'];
          var _slideData = msg['slide'];
          setState(() {
            if (!isLoadMore) {
              // 不是加载更多，则直接为变量赋值
              listData = _listData;
            } else {
              // 是加载更多，则需要将取到的news数据追加到原来的数据后面
              List list1 = new List();
              // 添加原来的数据
              list1.addAll(listData);
              // 添加新取到的数据
              list1.addAll(_listData);
              // 判断是否获取了所有的数据，如果是，则需要显示底部的"我也是有底线的"布局
              if (list1.length >= listTotalSize) {
                list1.add(Constants.END_LINE_TAG);
              }
              // 给列表数据赋值
              listData = list1;
            }

            // 轮播图数据
            slideData = _slideData;

          });
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    getNewsList(false);
  }

  @override
  Widget build(BuildContext context) {
    // 无数据时，显示Loading
    if (listData == null) {
      print("show loading...");
      return new Center(
        // CircularProgressIndicator是一个圆形的Loading进度条
        child: new CircularProgressIndicator(),
      );
    } else {
      // 有数据，显示ListView
      Widget listView = new ListView.builder(
        itemCount: listData.length * 2,
        itemBuilder: (context, i) => renderRow(i),
        controller: _controller,
      );
      // RefreshIndicator为ListView增加了下拉刷新能力，onRefresh参数传入一个方法，在下拉刷新时调用
      return new RefreshIndicator(child: listView, onRefresh: _pullToRefresh);

    }
//    return new ListView.builder(
//      // 这里itemCount是将轮播图组件、分割线和列表items都作为ListView的item算了
//      itemCount: listData.length * 2 + 1,
//      itemBuilder: (context, i) => renderRow(i)
//    );
  }

  // 渲染列表item
  Widget renderRow(i) {
    // i为0时渲染轮播图
    if (i == 0) {
      return new Container(
        height: 180.0,
        child: new SlideView(slideData),
      );
    }
    // i > 0时
    i -= 1;
    // i为奇数，渲染分割线
    if (i.isOdd) {
      return new Divider(height: 1.0);
    }
    // 将i取整
    i = i ~/ 2;
    // 得到列表item的数据
    var itemData = listData[i];
    // 代表列表item中的标题这一行
    var titleRow = new Row(
      children: <Widget>[
        // 标题充满一整行，所以用Expanded组件包裹
        new Expanded(
          child: new Text(itemData['title'], style: titleTextStyle),
        )
      ],
    );
    // 时间这一行包含了作者头像、时间、评论数这几个
    var timeRow = new Row(
      children: <Widget>[
        // 这是作者头像，使用了圆形头像
        new Container(
          width: 20.0,
          height: 20.0,
          decoration: new BoxDecoration(
            // 通过指定shape属性设置图片为圆形
            shape: BoxShape.circle,
            color: const Color(0xFFECECEC),
            image: new DecorationImage(
                image: new NetworkImage(itemData['authorImg']), fit: BoxFit.cover),
            border: new Border.all(
              color: const Color(0xFFECECEC),
              width: 2.0,
            ),
          ),
        ),
        // 这是时间文本
        new Padding(
          padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
          child: new Text(
            itemData['timeStr'],
            style: subtitleStyle,
          ),
        ),
        // 这是评论数，评论数由一个评论图标和具体的评论数构成，所以是一个Row组件
        new Expanded(
          flex: 1,
          child: new Row(
            // 为了让评论数显示在最右侧，所以需要外面的Expanded和这里的MainAxisAlignment.end
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              new Text("${itemData['commCount']}", style: subtitleStyle),
              new Image.asset('./images/ic_comment.png', width: 16.0, height: 16.0),
            ],
          ),
        )
      ],
    );
    var thumbImgUrl = itemData['thumb'];
    // 这是item右侧的资讯图片，先设置一个默认的图片
    var thumbImg = new Container(
      margin: const EdgeInsets.all(10.0),
      width: 60.0,
      height: 60.0,
      decoration: new BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFECECEC),
        image: new DecorationImage(
            image: new ExactAssetImage('./images/ic_img_default.jpg'),
            fit: BoxFit.cover),
        border: new Border.all(
          color: const Color(0xFFECECEC),
          width: 2.0,
        ),
      ),
    );
    // 如果上面的thumbImgUrl不为空，就把之前thumbImg默认的图片替换成网络图片
    if (thumbImgUrl != null && thumbImgUrl.length > 0) {
      thumbImg = new Container(
        margin: const EdgeInsets.all(10.0),
        width: 60.0,
        height: 60.0,
        decoration: new BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFECECEC),
          image: new DecorationImage(
              image: new NetworkImage(thumbImgUrl), fit: BoxFit.cover),
          border: new Border.all(
            color: const Color(0xFFECECEC),
            width: 2.0,
          ),
        ),
      );
    }
    // 这里的row代表了一个ListItem的一行
    var row = new Row(
      children: <Widget>[
        // 左边是标题，时间，评论数等信息
        new Expanded(
          flex: 1,
          child: new Padding(
            padding: const EdgeInsets.all(10.0),
            child: new Column(
              children: <Widget>[
                titleRow,
                new Padding(
                  padding: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 0.0),
                  child: timeRow,
                )
              ],
            ),
          ),
        ),
        // 右边是资讯图片
        new Padding(
          padding: const EdgeInsets.all(6.0),
          child: new Container(
            width: 100.0,
            height: 80.0,
            color: const Color(0xFFECECEC),
            child: new Center(
              child: thumbImg,
            ),
          ),
        )
      ],
    );
    // 用InkWell包裹row，让row可以点击
    return new InkWell(
      child: row,
      onTap: () {
      },
    );
  }
}