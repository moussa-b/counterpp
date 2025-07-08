CREATE TABLE [folders_history] (
    [id] INTEGER PRIMARY KEY AUTOINCREMENT,
    [originalId] INTEGER,
    [name] TEXT,
    [creationTimeStamp] INTEGER,
    [lastModificationTimeStamp] INTEGER,
    [folderOrder] INTEGER,
    [insertTimeStamp] INTEGER,
    [operationType] TEXT,
    [synchronizationTimeStamp] INTEGER
);
