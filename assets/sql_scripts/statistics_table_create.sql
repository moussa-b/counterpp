CREATE TABLE [statistics] (
    [id] INTEGER PRIMARY KEY AUTOINCREMENT,
    [counterId] INTEGER,
    [folderId] INTEGER,
    [type] TEXT,
    [value] INTEGER,
    [dateTimeStamp] INTEGER,
    FOREIGN KEY(folderId) REFERENCES folders(id) ON DELETE CASCADE,
    FOREIGN KEY(counterId) REFERENCES counters(id) ON DELETE CASCADE
);
