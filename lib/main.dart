import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/gestures.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:simple_permissions/simple_permissions.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Generated App',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.pink,
        primaryColor: const Color(0xFFe91e63),
        accentColor: const Color(0xFFe91e63),
        canvasColor: const Color(0xFFfafafa),
      ),
      home: MyImagePage(),
    );
  }
}

class MyImagePage extends StatefulWidget {

  @override
  _MyImagePageState createState() => _MyImagePageState();
}

class _MyImagePageState extends State<MyImagePage> {
  File image;
  GlobalKey _homeStateKey = GlobalKey();
  List<List<Offset>> strokes = new List<List<Offset>>();
  MyPainter _painter;
  ui.Image targetImage;
  Size mediaSize;
  double _r = 255.0;
  double _g = 0.0;
  double _b = 0.0;

  _MyImagePageState() {
    requestPermission();
  }

  // パーミッションの設定
  void requestPermission() async {
    await SimplePermissions.requestPermission(Permission.Camera);
    await SimplePermissions.requestPermission(Permission.WriteExternalStorage);
  }

  @override
  Widget build(BuildContext context) {
    mediaSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text('Canture Image Drawing!'),
      ),
      body: Listener(
        onPointerDown: _pointerDown,
        onPointerMove: _pointerMove,
        child: Container(
          child: CustomPaint(
            key: _homeStateKey,
            painter: _painter,
            child: ConstrainedBox(
              constraints: BoxConstraints.expand(),
            ),
          ),
        ),
      ),
      floatingActionButton: image == null
        ? FloatingActionButton(
            onPressed: getImage,
            tooltip: 'Take a picture!',
            child: Icon(Icons.add_a_photo),
        )
        : FloatingActionButton(
          onPressed: saveImage,
          tooltip: 'Save image',
          child: Icon(Icons.save),
        ),
        drawer: Drawer(
          child: Center(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Text(
                    'Set Color...',
                    style: TextStyle(fontSize: 20.0,),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Slider(
                    min: 0.0,
                    max: 255.0,
                    value: _r,
                    onChanged: sliderR,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Slider(
                    min: 0.0,
                    max: 255.0,
                    value: _g,
                    onChanged: sliderG,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Slider(
                    min: 0.0,
                    max: 255.0,
                    value: _b,
                    onChanged: sliderB,
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }

  // スライダーの値設定
  void sliderR(double value) {
    setState(() {
      _r = value;
    });
  }
  void sliderG(double value) {
    setState(() {
      _g = value;
    });
  }
  void sliderB(double value) {
    setState(() {
      _b = value;
    });
  }

  // MyPainterの作成
  void createMyPainter() {
    var strokeColor = Color.fromARGB(200, _r.toInt(), _g.toInt(), _b.toInt());
    _painter = MyPainter(targetImage, image, strokes, mediaSize, strokeColor);
  }

  // カメラを起動しイメージを読み込む
  void getImage() async {
    File file = await ImagePicker.pickImage(source: ImageSource.camera);
    image = file;
    loadImage(image.path);
  }

  // イメージの保存
  void saveImage() async {
    _painter.saveImage();
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text("Saved!"),
        content: Text("Save image to file."),
      )
    );
  }

  // パスからイメージを読み込み ui.image を作成する
  void loadImage(path) async {
    List<int> byts = await image.readAsBytes();
    Uint8List u8lst = Uint8List.fromList(byts);
    ui.instantiateImageCodec(u8lst).then((codec) {
      codec.getNextFrame().then((frameInfo) {
        targetImage = frameInfo.image;
        setState(() {
          createMyPainter();
        });
      });
    });
  }

  // タップしたときの処理
  void _pointerDown(PointerDownEvent event) {
    RenderBox referenceBox = _homeStateKey.currentContext.findRenderObject();
    strokes.add([referenceBox.globalToLocal(event.position)]);
    setState(() {
      createMyPainter();
    });
  }

  // ドラック中の処理
  void _pointerMove(PointerMoveEvent event) {
    RenderBox referenceBox = _homeStateKey.currentContext.findRenderObject();
    strokes.last.add(referenceBox.globalToLocal(event.position));
    setState(() {
      createMyPainter();
    });
  }
}


// ペインタークラス
class MyPainter extends CustomPainter {
  File image;
  ui.Image targetImage;
  Size mediaSize;
  Color strokeColor;
  var strokes = new List<List<Offset>>();
  MyPainter(this.targetImage, this.image, this.strokes, this.mediaSize, this.strokeColor);

  @override
  void paint(Canvas canvas, Size size) async {
    mediaSize = size;
//    ui.Image uiImage;
//    drawToCanvas().then((img) {
//      uiImage = img;
//    });
    ui.Image img = await drawToCanvas();
    canvas.drawImage(img, Offset(0.0, 0.0), Paint());
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;

  // 描画イメージをファイルに保存する
  void saveImage() async {
//    ui.Image uiImage;
//    drawToCanvas().then((img) {
//      uiImage = img;
//    });
    ui.Image img = await drawToCanvas();
    final ByteData byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    int epoch = new DateTime.now().millisecondsSinceEpoch;
    final file = new File(image.parent.path + '/' + epoch.toString() + '.png');
    file.writeAsBytes(byteData.buffer.asUint8List());
  }

  // イメージを描画した ui.Image を返す
  Future<ui.Image> drawToCanvas() async {
    ui.PictureRecorder recorder = ui.PictureRecorder();
    ui.Canvas canvas = Canvas(recorder);

    Paint paint1 = Paint();
    paint1.color = Colors.white;
    canvas.drawColor(Colors.white, BlendMode.color);

    if(targetImage != null) {
      Rect rect1 = Rect.fromPoints(
        Offset(0.0, 0.0),
        Offset(targetImage.width.toDouble(), targetImage.height.toDouble())
      );
      Rect rect2 = Rect.fromPoints(
        Offset(0.0, 0.0),
        Offset(mediaSize.width, mediaSize.height)
      );
      canvas.drawImageRect(targetImage, rect1, rect2, paint1);
    }

    Paint paint2 = Paint();
    paint2.color = strokeColor;
    paint2.style = PaintingStyle.stroke;
    paint2.strokeWidth = 5.0;

    for(var stroke in strokes) {
      Path strokePath = new Path();
      strokePath.addPolygon(stroke, false);
      canvas.drawPath(strokePath, paint2);
    }
    ui.Picture picture = recorder.endRecording();
    return picture.toImage(mediaSize.width.toInt(), mediaSize.height.toInt());
  }
}