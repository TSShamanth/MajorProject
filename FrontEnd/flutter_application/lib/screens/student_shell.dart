import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StudentShell extends StatelessWidget {
  final Widget child;
  final GoRouterState state;

  const StudentShell({super.key, required this.child, required this.state});

  @override
  Widget build(BuildContext context) {
    // The individual screens (Profile, Fees, etc.) now use StudentLayout 
    // which internally uses AppLayout. AppLayout provides the Sidebar and Header.
    // We should not wrap them in another Scaffold here.
    return child;
  }
}
