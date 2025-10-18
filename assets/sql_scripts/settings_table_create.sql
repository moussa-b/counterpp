CREATE TABLE settings
(
    id                         INTEGER PRIMARY KEY AUTOINCREMENT,
    counterCompactView         INTEGER,
    counterSorting             INTEGER,
    folderSorting              INTEGER,
    activateSounds             INTEGER,
    activateVibrator           INTEGER,
    keepScreenOn               INTEGER,
    showTutorial               INTEGER,
    synchronizationAccessToken TEXT,
    synchronizationApiUrl      TEXT,
    mailApiKey                 TEXT,
    mailApiDomain              TEXT,
    mailSupport                TEXT,
    lastModificationTimeStamp  INTEGER,
    lastOpenedTabIndex         INTEGER
);
