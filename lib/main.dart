import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:launcher_assist/launcher_assist.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var installedApps;
  var wallpaper;
  bool accessStorage;

  @override
  void initState() {
    accessStorage = false;
    super.initState();
    LauncherAssist.getAllApps().then((var apps) {
      setState(() {
        installedApps = apps;
      });
    });
    handleStoragePermissions().then((permissionGranted) {
      if (permissionGranted) {
        LauncherAssist.getWallpaper().then((imageData) {
          setState(() {
            wallpaper = imageData;
            accessStorage = !accessStorage;
          });
        });
      } else {
        print("Aint work");
      }
    });
  }

  void _handleInvalidPermissions(storagePermissionStatus) {
    if (storagePermissionStatus == PermissionStatus.denied) {
      throw new PlatformException(
          code: "Permission Denied",
          message: "Access to storage data denied",
          details: null);
    } else if (storagePermissionStatus == PermissionStatus.denied) {
      throw new PlatformException(
          code: "Permission Denied",
          message: "Access to storage data denied",
          details: null);
    }
  }

  Future<bool> handleStoragePermissions() async {
    PermissionStatus storagePermissionStatus = await _getPermissionStatus();
    if (storagePermissionStatus == PermissionStatus.granted) {
      return true;
    } else {
      _handleInvalidPermissions(storagePermissionStatus);
      return false;
    }
  }

  Future<PermissionStatus> _getPermissionStatus() async {
    PermissionStatus permission = await PermissionHandler()
        .checkPermissionStatus(PermissionGroup.storage);
    if (permission != PermissionStatus.granted &&
        permission != PermissionStatus.disabled) {
      Map<PermissionGroup, PermissionStatus> permissionStatus =
          await PermissionHandler()
              .requestPermissions([PermissionGroup.storage]);
      return permissionStatus[PermissionGroup.storage] ??
          PermissionStatus.unknown;
    } else {
      return permission;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (accessStorage) {
      setState(() {});
    }
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Lit Launcher',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Scaffold(
          body: WillPopScope(
            onWillPop: () => Future(() => false),
            child: Stack(
              children: <Widget>[
                WallpaperContainer(
                  wallpaper: wallpaper,
                ),
                installedApps != null
                    ? ForegroundWidget(installedApps: installedApps)
                    : Container(),
                accessStorage
                    ? Container()
                    : Positioned(
                        top: 0,
                        left: 20,
                        child: SafeArea(
                          child: Tooltip(
                            message: "Click here to grant storage permission",
                            child: GestureDetector(
                              onTap: () {
                                handleStoragePermissions()
                                    .then((permissionGranted) {
                                  if (permissionGranted) {
                                    LauncherAssist.getWallpaper()
                                        .then((imageData) {
                                      setState(() {
                                        wallpaper = imageData;
                                        accessStorage = !accessStorage;
                                      });
                                    });
                                  } else {
                                    print("Aint work");
                                  }
                                });
                                setState(() {});
                              },
                              child: Icon(
                                Icons.storage,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                      )
              ],
            ),
          ),
        ));
  }
}

class ForegroundWidget extends StatefulWidget {
  final installedApps;
  ForegroundWidget({@required this.installedApps});

  @override
  _ForegroundWidgetState createState() => _ForegroundWidgetState();
}

class _ForegroundWidgetState extends State<ForegroundWidget>
    with SingleTickerProviderStateMixin {
  AnimationController opacityController;
  Animation<double> opacity;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    opacityController =
        AnimationController(vsync: this, duration: Duration(seconds: 1));
    opacity = Tween(begin: 0.0, end: 1.0).animate(opacityController);
  }

  @override
  Widget build(BuildContext context) {
    opacityController.forward();
    return FadeTransition(
      opacity: opacity,
      child: Container(
        padding: EdgeInsets.fromLTRB(30, 50, 30, 0),
        child: GridView.count(
          crossAxisCount: 4,
          mainAxisSpacing: 40,
          physics: BouncingScrollPhysics(),
          children: List.generate(
              widget.installedApps != null ? widget.installedApps.length : 0,
              (index) {
            return GestureDetector(
              onTap: () {
                LauncherAssist.launchApp(
                    widget.installedApps[index]['package']);
              },
              child: Container(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    iconContainer(index),
                    SizedBox(
                      height: 10,
                    ),
                    Text(
                      widget.installedApps[index]['label'],
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  iconContainer(int index) {
    try {
      return Image.memory(
        widget.installedApps[index]['icon'] != null
            ? widget.installedApps[index]['icon']
            : Uint8List(0),
        height: 50,
        width: 50,
      );
    } catch (e) {
      return Container();
    }
  }
}

class WallpaperContainer extends StatelessWidget {
  final wallpaper;

  WallpaperContainer({@required this.wallpaper});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: Image.memory(
        wallpaper != null ? wallpaper : Uint8List(0),
        fit: BoxFit.cover,
      ),
    );
  }
}
