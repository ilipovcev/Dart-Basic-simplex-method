import 'package:simplex/simplex_compute.dart';

void main(List<String> arguments) {
  bool quit = false;

// ---Solution is unbounded---
  // List<List<double>> standardized =  [
  // // x1   x2    x3  x4  B
  //   [1,   -2,    1,  0,   2],
  //   [2,   -1,    0,  1,   3],
  //   [-1,  -1,    0,  0,   0]  
  // ];


  // List<List<double>> standardized =  [
  // // 2x1 + x2 <= 1
  // // x1 + 3x2 <= 6

  // // F(x) = 3x1 - 2x2
  // // x1   x2    x3  x4   B
  //   [2,   1,    1,  0,   1],
  //   [1,   3,    0,  1,   6],
  //   [-3,  2,    0,  0,   0],
  // ];

  List<List<double>> standardized =  [
  // 3x1 + 2x2 <= 3
  // 2x1 + 3x2 <= 2

  // F(x) = x1 + 2x2
  // x1   x2    x3  x4   B
    [3,   2,    1,  0,   3],
    [2,   3,    0,  1,   2],
    [-1,  -2,    0,  0,   0],
  ];

  Simplex simplex = Simplex(standardized.length-1, standardized.first.length-1);
  simplex.fillTable(standardized);
  simplex.printTable();

  while (!quit) {
    RESULT result = simplex.compute();

    // simplex.printTable();

    if(result == RESULT.isOptimal){
      simplex.printTable();
      quit = true;
    } else if (result == RESULT.unbounded) {
      print("---Solution is unbounded---");
      quit = true;
    }
  }
}
