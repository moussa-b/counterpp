import 'folder.dart';

class Counter {
  String? color;
  int? counterCount;
  int? creationTimeStamp;
  Folder? folder;
  int? id;
  int? lastModificationTimeStamp;
  int? counterLimit;
  String? name;
  int? counterOrder;
  int? orderInFolder;
  int? step;
  String? note;

  Counter(
      {this.color,
        this.counterCount,
        this.creationTimeStamp,
        this.folder,
        this.id,
        this.lastModificationTimeStamp,
        this.counterLimit,
        this.name,
        this.counterOrder,
        this.orderInFolder,
        this.step,
        this.note});

  Counter.fromJson(Map<String, dynamic> json) {
    color = json['color'];
    counterCount = json['counterCount'];
    creationTimeStamp = json['creationTimeStamp'];
    if (json['folder.id'] != null) {
      folder = Folder(
        id: json['folder.id'],
        name: json['folder.name'],
        folderOrder: json['folder.folderOrder'],
        creationTimeStamp: json['folder.creationTimeStamp'],
        lastModificationTimeStamp: json['folder.lastModificationTimeStamp'],
        counterNumber: json['folder.counterNumber'],
      );
    }
    id = json['id'];
    lastModificationTimeStamp = json['lastModificationTimeStamp'];
    counterLimit = json['counterLimit'];
    name = json['name'];
    counterOrder = json['counterOrder'];
    orderInFolder = json['orderInFolder'];
    step = json['step'];
    note = json['note'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['color'] = color;
    data['counterCount'] = counterCount;
    data['creationTimeStamp'] = creationTimeStamp;
    if (folder != null) {
      data['folder'] = folder!.toJson();
    }
    data['id'] = id;
    data['lastModificationTimeStamp'] = lastModificationTimeStamp;
    data['counterLimit'] = counterLimit;
    data['name'] = name;
    data['counterOrder'] = counterOrder;
    data['orderInFolder'] = orderInFolder;
    data['step'] = step;
    data['note'] = note;
    return data;
  }
}
