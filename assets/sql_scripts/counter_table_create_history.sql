CREATE TABLE [counters_history] (
    [id] INTEGER PRIMARY KEY AUTOINCREMENT,
    [originalId] INTEGER,
    [name] TEXT,
    [counterCount] INTEGER,
    [creationTimeStamp] INTEGER,
    [lastModificationTimeStamp] INTEGER,
    [counterLimit] INTEGER,
    [folderId] INTEGER,
    [color] TEXT,
    [counterOrder] INTEGER,
    [orderInFolder] INTEGER,
    [step] INTEGER,
    [note] TEXT NULL,
    [insertTimeStamp] INTEGER,
    [operationType] TEXT,
    [synchronizationTimeStamp] INTEGER
);
