import 'package:flutter/material.dart';

class NewContactPage extends StatefulWidget {
  const NewContactPage({super.key});

  @override
  State<NewContactPage> createState() => _NewContactPageState();
}

class _NewContactPageState extends State<NewContactPage> {
  @override
  Widget build(BuildContext context) {
    ColorScheme c=Theme.of(context).colorScheme;
    return Container(
      width: 400,
      color: Colors.white,
      child: Wrap(
        spacing: 10,
        children: [
          Container(width: 30,height: 30,color: c.primary,),
          Container(width: 30,height: 30,color: c.onPrimary,),
          Container(width: 30,height: 30,color: c.primaryContainer,),
          Container(width: 30,height: 30,color: c.onPrimaryContainer,),
          Container(width: 30,height: 30,color: c.secondary,),
          Container(width: 30,height: 30,color: c.onSecondary,),
          Container(width: 30,height: 30,color: c.secondaryContainer,),
          Container(width: 30,height: 30,color: c.onSecondaryContainer,),
          Container(width: 30,height: 30,color: c.tertiary,),
          Container(width: 30,height: 30,color: c.onTertiary,),
          Container(width: 30,height: 30,color: c.tertiaryContainer,),
          Container(width: 30,height: 30,color: c.onTertiaryContainer,),
        ],
      ),
    );
  }
}
