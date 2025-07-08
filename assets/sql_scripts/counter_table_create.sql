CREATE TABLE [counters] (
  [id] INTEGER PRIMARY KEY AUTOINCREMENT,
  [name] TEXT,
  [counterCount] INTEGER,
  [creationTimeStamp] INTEGER,
  [lastModificationTimeStamp] INTEGER,
  [synchronizationTimeStamp] INTEGER,
  [counterLimit] INTEGER,
  [folderId] INTEGER,
  [color] TEXT,
  [counterOrder] INTEGER,
  [orderInFolder] INTEGER,
  [step] INTEGER,
  [note] TEXT NULL,
  FOREIGN KEY(folderId) REFERENCES folders(id) ON DELETE CASCADE
);
