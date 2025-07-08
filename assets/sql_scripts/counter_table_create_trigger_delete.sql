CREATE TRIGGER after_counter_delete
    AFTER DELETE ON counters
    FOR EACH ROW
    WHEN (SELECT LENGTH(synchronizationAccessToken) FROM settings WHERE id = 1) > 0
BEGIN
INSERT INTO counters_history (
    name,
    counterCount,
    creationTimeStamp,
    lastModificationTimeStamp,
    counterLimit,
    folderId,
    color,
    counterOrder,
    orderInFolder,
    step,
    note,
    originalId,
    insertTimeStamp,
    operationType,
    synchronizationTimeStamp
)
VALUES (
           OLD.name,
           OLD.counterCount,
           OLD.creationTimeStamp,
           OLD.lastModificationTimeStamp,
           OLD.counterLimit,
           OLD.folderId,
           OLD.color,
           OLD.counterOrder,
           OLD.orderInFolder,
           OLD.step,
           OLD.note,
           OLD.id,
           strftime('%s','now'),
           'DELETE',
           NULL
       );
END;
