class Folder {
  int? creationTimeStamp;
  int? id;
  int? lastModificationTimeStamp;
  String? name;
  int? folderOrder;
  int? counterNumber;

  Folder(
      {this.creationTimeStamp,
      this.id,
      this.lastModificationTimeStamp,
      this.name,
      this.folderOrder,
      this.counterNumber});

  Folder.fromJson(Map<String, dynamic> json) {
    creationTimeStamp = json['creationTimeStamp'];
    id = json['id'];
    lastModificationTimeStamp = json['lastModificationTimeStamp'];
    name = json['name'];
    folderOrder = json['folderOrder'];
    counterNumber = json['counterNumber'] ?? 0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['creationTimeStamp'] = creationTimeStamp;
    data['id'] = id;
    data['lastModificationTimeStamp'] = lastModificationTimeStamp;
    data['name'] = name;
    data['folderOrder'] = folderOrder;
    data['counterNumber'] = counterNumber;
    return data;
  }
}
