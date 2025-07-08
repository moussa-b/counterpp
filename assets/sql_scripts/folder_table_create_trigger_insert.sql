CREATE TRIGGER after_folder_insert
    AFTER INSERT ON folders
    FOR EACH ROW
    WHEN (SELECT LENGTH(synchronizationAccessToken) FROM settings WHERE id = 1) > 0
BEGIN
INSERT INTO folders_history (
    name,
    creationTimeStamp,
    lastModificationTimeStamp,
    folderOrder,
    originalId,
    insertTimeStamp,
    operationType,
    synchronizationTimeStamp
)
VALUES (
           NEW.name,
           NEW.creationTimeStamp,
           NEW.lastModificationTimeStamp,
           NEW.folderOrder,
           NEW.id,
           strftime('%s', 'now'),
           'INSERT',
           NULL
       );
END;
