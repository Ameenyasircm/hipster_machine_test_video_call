

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

callNext(var className, var context) {
  Navigator.push(context, MaterialPageRoute(builder: (context) => className),
  );
}

callNextReplacement(var className, var context){
  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => className),
  );
}
