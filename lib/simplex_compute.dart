enum RESULT {
  notOptimal,
  isOptimal,
  unbounded
}

class Answer {
  final int rowPosition;
  final double value;
  final String variableName;
  Answer({
    required this.rowPosition,
    required this.value,
    required this.variableName,
  });


  int get fractional => ((value - value.floor()) * 10000).floor();
  bool get isInteger => value is int || value == value.roundToDouble();
}

class Simplex {
  late final int _rows;
  late final int _cols;
  late final List<List<double>> _table;
  bool _solutionIsUnbounded = false;
  List<int> basisVars = [];
  var listAnswers = List<Answer>.empty(growable: true); 
  

  Simplex(int numOfConstraints, int numOfUnknowns) {
    _rows = numOfConstraints + 1;
    _cols = numOfUnknowns + 1;

    _table = List.generate(_rows, (i) => List.filled(_cols, -999), growable: false);
  }
  
  printTable(){
    String stringPrint = '';
    String titlePrint = '';
    for (var i = 0; i < _rows; i++) {
      for (var j = 0; j < _cols; j++) {
        stringPrint += '${_table[i][j].toStringAsFixed(3)}\t';
      }
      stringPrint += '\n';
    }
    for (var i = 0; i <= _rows; i++) {
      titlePrint += 'X${i+1}\t';
      if (i == _rows) titlePrint += 'B';
    }
    print(titlePrint);
    print(stringPrint);
  }

  fillTable(List<List<double>> data){
    for (var i = 0; i < _table.length; i++) {
      for (var j = 0; j < _table[i].length; j++) {
        _table[i][j] = data[i][j];
      }
    }
    for (var i = 1; i < _cols; i++) {
      if (i > (_cols - data.length)) {
        basisVars.add(i);
      }
    }
  }

  RESULT compute() {
    if(checkOptimality()){
      return RESULT.isOptimal;  
    }

    int pivotColumn = _findEnteringColumn();
    print('Pivot Column: $pivotColumn\n');


    List<double> ratios = _calculateRatios(pivotColumn);
    if(_solutionIsUnbounded == true){
      return RESULT.unbounded;
    }

    int pivotRow = _findSmallestValue(ratios);
    print('Pivot row: $pivotRow');
    print('Element on col $pivotColumn and row $pivotRow is pivot');
    print('variable x${pivotColumn+1} to basis column in $pivotRow row\n');
    _newBasisVar(pivotRow, pivotColumn);

    _formNextTableau(pivotRow, pivotColumn);

    return RESULT.notOptimal;
  }

  bool nonIntegerAnswer() {
    bool hasIntegers = true;
    for (var element in listAnswers) {
      if (!element.isInteger) {
        hasIntegers = false;
        break;
      }
    }
    return !hasIntegers;
  }

  findLargestAnswerFractional() {
    Answer maxFractional = listAnswers.first;
    for (var item in listAnswers) {
      if (item.fractional > maxFractional.fractional) {
        maxFractional = item;
      }
    }
    print('Answer with max fractional: ${maxFractional.variableName}');
    return maxFractional;
  }

  getAnswers() {
    for (var i = 1; i < _rows; i++) {
      if (basisVars.contains(i)) {
        var index = basisVars.indexOf(i);
        listAnswers.add(Answer(
          rowPosition: i, 
          value: _table[index][_cols-1].toDouble(), 
          variableName: 'x$i'
        ));
      } else {
        listAnswers.add(Answer(
          rowPosition: i, 
          value: 0.0, 
          variableName: 'x$i'
        ));
      }
    }
    print('Answer: $listAnswers');
  }

  _newBasisVar(int toRow, int x) {
    basisVars[toRow] = x + 1;
    String basisVarString = '';
    for (var e in basisVars) {
      basisVarString += 'x$e\t';
    }
    print('Basis variables: $basisVarString\t');
  }

  _formNextTableau(int pivotRow, int pivotColumn){
    final double pivotValue = _table[pivotRow][pivotColumn];
    final List<double> pivotRowVals = List.filled(_cols, 0);
    final List<double> pivotColumnVals = List.filled(_cols, 0);
    final List<double> rowNew = List.filled(_cols, 0);

    for (var i = 0; i < _cols; i++) {
      pivotRowVals[i] = _table[pivotRow][i];
    }

    for (var i = 0; i < _rows; i++) {
      pivotColumnVals[i] = _table[i][pivotColumn];
    }

    for(var i = 0; i < _cols; i++) {
      rowNew[i] =  pivotRowVals[i] / pivotValue;
    }

    for (var i = 0; i < _rows; i++) {
      if(i != pivotRow){
        for (var j = 0; j < _cols; j++) {
          double c = pivotColumnVals[i];
          _table[i][j] = _table[i][j] - (c * rowNew[j]);
        }
      } else {
        _table[i] = rowNew;
      }
    }

    for (var i = 0; i < rowNew.length; i++) {
      rowNew[i] = _table[pivotRow][i];
    }

    print('New table:');
    printTable();
  }

  List<double> _calculateRatios(int column){
    List<double> positiveEntries = List.filled(_rows, 0);
    List<double> res = List.filled(_rows, 0);
    int allNegativeCount = 0;

    for (var i = 0; i < _rows; i++) {
      if(_table[i][column] > 0){
        positiveEntries[i] = _table[i][column];
      } else{
        positiveEntries[i] = 0;
        allNegativeCount++;
      }
    }
    print('positive entries for column $column: $positiveEntries\n');
    print('negative count for column $column: $allNegativeCount\n');

    if(allNegativeCount == _rows) {
      _solutionIsUnbounded = true;
    } else {
      for (var i = 0; i < _rows; i++) {
        var val = positiveEntries[i];
        if(val > 0){
          res[i] = _table[i][_cols-1] / val;
          print('Di = ${res[i]}');
        }
      }
    }
    print('ratio: $res\n');
    return res;
  }

  int _findEnteringColumn() {
    List<double> values  = List.filled(_cols, 0);
    int location = 0;

    int pos, count = 0;
    for(pos = 0; pos < _cols-1; pos++){
      if(_table[_rows-1][pos] < 0){
        count++;
        print('nagative value on _table[${_rows-1}][$pos] = ${_table[_rows-1][pos]}');
        print('count = $count\n');
      }
    }

    if(count > 1){ // >=
      for (var i = 0; i < _cols-1; i++) {
        values[i] = (_table[_rows-1][i]).abs();
        print('Absolute value ${_table[_rows-1][i]} = ${values[i]}\n');
      }
      print('Find largest value from $values\n');
      location = _findLargestValue(values);
    } else {
      // location = 0;
      location = count - 1;
    }
    return location;
  }

  int _findSmallestValue(List<double> data) {
    double minimum;
    int c, location = 0;
    minimum = data[0];

    for (c = 1; c < data.length; c++) {
      if(data[c] > 0){
        if(data[c] < minimum){
          minimum = data[c];
          location = c;
        }
      }
    }
    return location;
  }

  int _findLargestValue(List<double> data) {
    double maximum = 0;
    int c, location = 0;
    maximum = data[0];

    for (c = 1; c < data.length; c++) {
      if(data[c] > 0){  
        if(data[c] > maximum){
          maximum = data[c];
          location = c;
        }
      }
    }
    return location;
  }

  bool checkOptimality() {
    bool isOptimal = false;
    int vCount = 0;

    for(int i = 0; i < _cols-1; i++){
      double val = _table[_rows-1][i];
      if(val >= 0){
        vCount++;
      }
    }

    if(vCount == _cols - 1){
      isOptimal = true;

    }

    return isOptimal;
  }

  List<List<double>> get getTable => _table;
}