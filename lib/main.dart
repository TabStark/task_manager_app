import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'splashscreen.dart';
import 'completedtask.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child ?? Container()),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primaryColorLight: Color.fromARGB(255, 119, 7, 255)),
      home: splashScreen(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;
  final _bottomnavigationbarItem = [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
    BottomNavigationBarItem(icon: Icon(Icons.check), label: "Completed Task")
  ];
  PageController pageController = PageController(initialPage: 0);
//  CONVERT STRING TO TIME
  TimeOfDay parseTime(
    String timeString,
  ) {
    List<String> parts = timeString.split(':');
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);
    return TimeOfDay(hour: hour, minute: minute);
  }

  @override
  Widget build(BuildContext context) {
    final CollectionReference _tasks =
        FirebaseFirestore.instance.collection("task");

    final TextEditingController _taskController = TextEditingController();
    final TextEditingController _discriptionController =
        TextEditingController();

    TextEditingController _datetimeController = TextEditingController();
    TextEditingController _timeController = TextEditingController();

    // CREATE TASK
    Future<void> _createTask([DocumentSnapshot? documentSnapshot]) async {
      await showModalBottomSheet(
          isScrollControlled: true,
          context: context,
          builder: (BuildContext ctx) {
            return Padding(
                padding: EdgeInsets.only(
                    top: 20,
                    left: 20,
                    right: 20,
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TASK
                    TextField(
                      controller: _taskController,
                      decoration: InputDecoration(labelText: "Enter Task Name"),
                    ),

                    // DISCRIPTION
                    TextField(
                      controller: _discriptionController,
                      decoration:
                          InputDecoration(labelText: "Enter Discription"),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // DATE
                        Container(
                          width: 200,
                          child: TextField(
                            controller: _datetimeController,
                            decoration: InputDecoration(
                              hintText: "Select Due Date",
                              suffixIcon: Icon(Icons.calendar_month_outlined),
                            ),
                            onTap: () async {
                              DateTime? pickdate = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2025));
                              if (pickdate != null) {
                                setState(() {
                                  _datetimeController.text =
                                      DateFormat("yyyy-MM-dd").format(pickdate);
                                });
                              }
                            },
                          ),
                        ),

                        // TIME
                        Container(
                          width: 150,
                          child: TextField(
                            controller: _timeController,
                            decoration: InputDecoration(
                                hintText: "Select Time",
                                suffixIcon: Icon(Icons.timer_sharp)),
                            onTap: () async {
                              TimeOfDay? picktime = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now());
                              if (picktime != null) {
                                setState(() {
                                  _timeController.text =
                                      picktime.format(context);
                                });
                              }
                            },
                          ),
                        )
                      ],
                    ),

                    // SAVE BUTTON
                    ElevatedButton(
                      onPressed: () async {
                        if (_taskController.text != "" &&
                            _discriptionController.text != "" &&
                            _datetimeController.text != "" &&
                            _timeController.text != "") {
                          DateTime selectedDate = new DateFormat("yyyy-MM-dd")
                              .parse(_datetimeController.text);
                          TimeOfDay selectedTime =
                              parseTime(_timeController.text);

                          if (selectedDate != null && selectedTime != null) {
                            DateTime combinedDateTime = DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                                selectedTime.hour,
                                selectedTime.minute,
                                selectedDate.second);

                            final String taskname = _taskController.text;
                            final String taskDiscription =
                                _discriptionController.text;
                            final Timestamp timestamp =
                                Timestamp.fromDate(combinedDateTime);

                            if (combinedDateTime != null) {
                              await _tasks.add({
                                "task_name": taskname,
                                "Discription": taskDiscription,
                                "status": false,
                                "due_date": timestamp
                              });
                              Navigator.of(context).pop();
                              _taskController.text = "";
                              _discriptionController.text = "";
                              _datetimeController.text = "";
                              _timeController.text = "";
                            }
                          }
                        } else {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text("Alert!"),
                                  content: Text("Fill all the blanks",
                                      style: TextStyle(fontSize: 20)),
                                  actions: <Widget>[
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text(
                                        "Ok",
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 19),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context)
                                              .primaryColorLight),
                                    )
                                  ],
                                );
                              });
                        }
                      },
                      child: Text(
                        "Save",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColorLight),
                    )
                  ],
                ));
          });
    }

    // UPDATE
    Future<void> _update([DocumentSnapshot? documentSnapshot]) async {
      if (documentSnapshot != null) {
        _taskController.text = documentSnapshot["task_name"];
        _discriptionController.text = documentSnapshot["Discription"];
        Timestamp time = documentSnapshot["due_date"];
        DateTime dateTime = DateTime.parse(time.toDate().toString());
        _datetimeController.text = DateFormat("yyyy-MM-dd").format(dateTime);
        _timeController.text = DateFormat('jm').format(dateTime);
      }

      await showModalBottomSheet(
          isScrollControlled: true,
          context: context,
          builder: (BuildContext ctx) {
            return Padding(
              padding: EdgeInsets.only(
                  top: 20,
                  left: 20,
                  right: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TASK
                    TextField(
                      controller: _taskController,
                      decoration: InputDecoration(labelText: "Enter Task Name"),
                    ),

                    // DISCRIPTION
                    TextField(
                      controller: _discriptionController,
                      decoration:
                          InputDecoration(labelText: "Enter Discription"),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // DATE
                        Container(
                          width: 200,
                          child: TextField(
                            controller: _datetimeController,
                            decoration: InputDecoration(
                              hintText: "Select Due Date",
                              suffixIcon: Icon(Icons.calendar_month_outlined),
                            ),
                            onTap: () async {
                              DateTime? pickdate = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2025));
                              if (pickdate != null) {
                                setState(() {
                                  _datetimeController.text =
                                      DateFormat("yyyy-MM-dd").format(pickdate);
                                });
                              }
                            },
                          ),
                        ),

                        // TIME
                        Container(
                          width: 150,
                          child: TextField(
                            controller: _timeController,
                            decoration: InputDecoration(
                                hintText: "Select Time",
                                suffixIcon: Icon(Icons.timer_sharp)),
                            onTap: () async {
                              TimeOfDay? picktime = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now());
                              if (picktime != null) {
                                setState(() {
                                  _timeController.text =
                                      picktime.format(context);
                                });
                              }
                            },
                          ),
                        )
                      ],
                    ),

                    SizedBox(
                      height: 20,
                    ),
                    SizedBox(
                      width: 110,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_taskController.text != "" &&
                              _discriptionController.text != "" &&
                              _datetimeController.text != "" &&
                              _timeController.text != "") {
                            DateTime selectedDate = new DateFormat("yyyy-MM-dd")
                                .parse(_datetimeController.text);
                            TimeOfDay selectedTime =
                                parseTime(_timeController.text);

                            // COMBINE DATE AND TIME
                            if (selectedDate != null && selectedTime != null) {
                              DateTime combinedDateTime = DateTime(
                                  selectedDate.year,
                                  selectedDate.month,
                                  selectedDate.day,
                                  selectedTime.hour,
                                  selectedTime.minute,
                                  selectedDate.second);

                              final String taskname = _taskController.text;
                              final String taskDiscription =
                                  _discriptionController.text;
                              final Timestamp timestamp =
                                  Timestamp.fromDate(combinedDateTime);

                              if (combinedDateTime != null) {
                                await _tasks.doc(documentSnapshot!.id).update({
                                  "task_name": taskname,
                                  "Discription": taskDiscription,
                                  "status": false,
                                  "due_date": timestamp
                                });
                                Navigator.of(context).pop();
                                _taskController.text = "";
                                _discriptionController.text = "";
                                _datetimeController.text = "";
                                _timeController.text = "";
                              }
                            }
                          } else {
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text("Alert!"),
                                    content: Text("Fill all the blanks",
                                        style: TextStyle(fontSize: 20)),
                                    actions: <Widget>[
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text(
                                          "Ok",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 19),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Theme.of(context)
                                                .primaryColorLight),
                                      )
                                    ],
                                  );
                                });
                          }
                        },
                        child: Text(
                          "Update",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).primaryColorLight),
                      ),
                    )
                  ]),
            );
          });
    }

    // COMPLETE STATUS
    Future<void> checkstatus([DocumentSnapshot? documentSnapshot]) async {
      setState(() {});
      bool currentstatus = documentSnapshot?["status"];
      if (currentstatus == false) {
        await _tasks.doc(documentSnapshot?.id).update({"status": true});
      } else {
        await _tasks.doc(documentSnapshot?.id).update({"status": false});
      }
    }

    // DELETE TASK
    Future<void> _delete(String productid) async {
      await _tasks.doc(productid).delete();

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("You have Successfully deleted the Task")));
    }

    return Scaffold(
      // APPBAR
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Task Manager",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Theme.of(context).primaryColorLight,
      ),

      // FLOATING BUTTON
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createTask(),
        child: Text(
          "+",
          style: TextStyle(fontSize: 22, color: Colors.white),
        ),
        backgroundColor: Theme.of(context).primaryColorLight,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      // BODY
      body: PageView(
          controller: pageController,
          onPageChanged: (newIndex) {
            setState(() {
              _currentIndex = newIndex;
            });
          },
          children: [
            StreamBuilder(
                stream: _tasks.snapshots(),
                builder:
                    (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
                  if (streamSnapshot.hasData) {
                    return Padding(
                      padding: EdgeInsets.all(10),
                      child: ListView.builder(
                          itemCount: streamSnapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            final DocumentSnapshot documentSnapshot =
                                streamSnapshot.data!.docs[index];
                            if (documentSnapshot['status'] == false) {
                              Timestamp time = documentSnapshot["due_date"];
                              DateTime dateTime =
                                  DateTime.parse(time.toDate().toString());

                              return Slidable(
                                startActionPane: ActionPane(
                                    motion: const StretchMotion(),
                                    children: [
                                      SlidableAction(
                                        onPressed: (context) =>
                                            _update(documentSnapshot),
                                        backgroundColor:
                                            Theme.of(context).primaryColorLight,
                                        icon: Icons.edit,
                                        label: "Edit",
                                      )
                                    ]),
                                endActionPane: ActionPane(
                                    motion: const StretchMotion(),
                                    children: [
                                      SlidableAction(
                                        onPressed: (context) =>
                                            _delete(documentSnapshot.id),
                                        backgroundColor:
                                            Theme.of(context).primaryColorLight,
                                        icon: Icons.delete,
                                        label: "Delete",
                                      )
                                    ]),
                                child: Card(
                                  margin:
                                      const EdgeInsets.only(top: 5, bottom: 5),
                                  child: ListTile(
                                      title: Text(
                                        documentSnapshot["task_name"],
                                      ),
                                      subtitle:
                                          Text(documentSnapshot["Discription"]),
                                      trailing: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          InkWell(
                                              onTap: () =>
                                                  checkstatus(documentSnapshot),
                                              child: documentSnapshot['status']
                                                  ? Icon(Icons.check_box,
                                                      color: Colors.green)
                                                  : Icon(Icons
                                                      .check_box_outline_blank)),
                                          SizedBox(
                                              width: 100,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                      "${DateFormat('MMMd').format(dateTime)}"),
                                                  Text(
                                                      "${DateFormat('jm').format(dateTime)}")
                                                ],
                                              ))
                                        ],
                                      )),
                                ),
                              );
                            } else {
                              return Container();
                            }
                          }),
                    );
                  }
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }),
            CompletedTask()
          ]),

      // PAGE NAVIGATION
      bottomNavigationBar: BottomNavigationBar(
        items: _bottomnavigationbarItem,
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          pageController.animateToPage(index,
              duration: Duration(milliseconds: 500), curve: Curves.ease);
        },
      ),
    );
  }
}
