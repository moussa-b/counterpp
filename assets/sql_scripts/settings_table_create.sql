CREATE TABLE settings
(
    id                        INTEGER PRIMARY KEY AUTOINCREMENT,
    counterCompactView        INTEGER,
    counterSorting            INTEGER,
    folderSorting             INTEGER,
    activateSounds            INTEGER,
    activateVibrator          INTEGER,
    keepScreenOn              INTEGER,
    showTutorial              INTEGER,
    onlineSynchronizationId   TEXT,
    lastModificationTimeStamp INTEGER
);
