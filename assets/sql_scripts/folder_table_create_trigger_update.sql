CREATE TRIGGER after_folder_update
    AFTER UPDATE ON folders
    FOR EACH ROW
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
               'UPDATE',
               NULL
           );
END;
