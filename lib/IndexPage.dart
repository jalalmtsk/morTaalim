
import 'package:flutter/material.dart';
import 'package:mortaalim/courses/primaire1Page/index_1PrimairePage.dart';
import 'package:mortaalim/courses/primaire2Page/2_primaire.dart';
import 'package:mortaalim/courses/primaire3Page/3_primaire.dart';
import 'package:mortaalim/courses/primaire4Page/4_primaire.dart';
import 'package:mortaalim/courses/primaire5Page/5_primaire.dart';
import 'package:mortaalim/courses/primaire6Page/6_primaire.dart';
import 'courses/primaire1Page/1_primairePage.dart';



class Index extends StatefulWidget{
  @override
  State<Index> createState() => _IndexState();
}

class _IndexState extends State<Index> {
  final List<Map<String, dynamic>> HighCourse = [
    {'title': '1ère Primaire', 'widget': index1Primaire()},
    {'title': '2ème Primaire', 'widget': primaire2()},
    {'title': '3ème Primaire', 'widget': primaire3()},
    {'title': '4ème Primaire', 'widget': primaire4()},
    {'title': '5ème Primaire', 'widget': primaire5()},
    {'title': '6ème Primaire', 'widget': primaire6()},
  ];



  @override
  Widget build(BuildContext context){

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(title: Text("Bienvenue"),),

      body: Column(
        children: [
          Text("Choisis Ton Niveau", style: Theme.of(context).textTheme.titleMedium,),

          Expanded(child: Image.asset('assets/images/Mathematics_toy.png')),
          Expanded(
            child: ListView.builder(
                itemCount: HighCourse.length,
                itemBuilder: (context, index){
                  final  title = HighCourse[index]['title']!;
                  return Padding(
                    padding: EdgeInsets.all(10),
                    child: Card(
                      color: Theme.of(context).cardColor,
                      child: ListTile(
                        title: Text(title),
                        onTap: (){
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => HighCourse[index]['widget']
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }),
          ),
        ],
      ),
    );
  }
}
