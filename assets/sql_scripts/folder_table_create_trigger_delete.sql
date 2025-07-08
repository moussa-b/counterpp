CREATE TRIGGER after_folder_delete
    AFTER DELETE ON folders
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
           OLD.name,
           OLD.creationTimeStamp,
           OLD.lastModificationTimeStamp,
           OLD.folderOrder,
           OLD.id,
           strftime('%s', 'now'),
           'DELETE',
           NULL
       );
END;
