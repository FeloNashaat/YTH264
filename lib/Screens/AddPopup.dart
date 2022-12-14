import 'package:YT_H264/Services/GlobalMethods.dart';
import 'package:flutter/material.dart';
import 'package:YT_H264/Screens/DownloadOptions.dart';
import 'package:YT_H264/Services/QueueObject.dart';
import 'package:YT_H264/Services/Youtube.dart';

class AddModalPopup extends StatefulWidget {
  AddModalPopup({super.key, this.uri});
  String? uri;
  YoutubeService ytServ = YoutubeService();

  @override
  State<AddModalPopup> createState() => _AddModalPopupState();
}

class _AddModalPopupState extends State<AddModalPopup> {
  final TextEditingController _uriController = TextEditingController();
  Widget downloadButton = Icon(Icons.search);
  YoutubeQueueObject? vidInfo;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.uri != null) {
      _uriController.text = widget.uri!;
      widget.uri = null;
      print('Share Detected');
      WidgetsBinding.instance.addPostFrameCallback(
        (timeStamp) async {
          print('Real Button Pressed');
          if (_uriController.text != '') {
            try {
              setState(() {
                downloadButton = Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: CircularProgressIndicator(),
                );
              });
              vidInfo = await widget.ytServ
                  .getVidInfo(_uriController.text)
                  .then((value) {
                setState(() {
                  downloadButton = Icon(Icons.search);
                });
                return value;
              });
              print(vidInfo!.title);
              setState(() {});
            } catch (e) {
              downloadButton = Icon(Icons.search);
              GlobalMethods.snackBarError(e.toString(), context,
                  isException: true);
            }
          } else {
            GlobalMethods.snackBarError('Enter Link', context);
          }
        },
      );
    }
    return Container(
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeIn,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 10),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.onPrimary,
                              borderRadius: BorderRadius.circular(20)),
                          width: MediaQuery.of(context).size.width * 0.75,
                          height: 55,
                          child: TextFormField(
                            controller: _uriController,
                            decoration: const InputDecoration(
                                hintStyle: TextStyle(
                                    color: Colors.black,
                                    fontFamily: 'Helvetica',
                                    fontSize: 16),
                                hintText: 'Enter Youtube URL',
                                border: OutlineInputBorder()),
                          )),
                      Padding(
                        padding: const EdgeInsets.all(0.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            height: 50,
                            width: 50,
                            child: TextButton(
                              style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all(Colors.black),
                                  overlayColor:
                                      MaterialStateProperty.all(Colors.grey)),
                              onPressed: () async {
                                print('Real Button Pressed');
                                if (_uriController.text != '') {
                                  try {
                                    setState(() {
                                      downloadButton = Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: CircularProgressIndicator(),
                                      );
                                    });
                                    vidInfo = await widget.ytServ
                                        .getVidInfo(_uriController.text)
                                        .then((value) {
                                      setState(() {
                                        downloadButton = Icon(Icons.search);
                                      });
                                      return value;
                                    });
                                    print(vidInfo!.title);
                                    setState(() {});
                                  } catch (e) {
                                    downloadButton = Icon(Icons.search);
                                    GlobalMethods.snackBarError(
                                        e.toString(), context,
                                        isException: true);
                                  }
                                } else {
                                  GlobalMethods.snackBarError(
                                      'Enter Link', context);
                                }
                              },
                              child: downloadButton,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  DownloadOptions(
                    ytObj: vidInfo,
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
